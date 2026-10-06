{
  flake.modules.nixos.atlas-refresh-jobs =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      applyChain = lib.mapAttrs (
        name: svc: svc // { after = (svc.after or [ ]) ++ (chainAfter.${name} or [ ]); }
      );

      cfg = config.my.nixos.atlasRefreshJobs;

      chainAfter = lib.listToAttrs (
        lib.imap0 (
          i: name:
          lib.nameValuePair name (
            if i == 0 then [ ] else [ "${builtins.elemAt refreshOrder (i - 1)}.service" ]
          )
        ) refreshOrder
      );

      clientListRefreshScript =
        env:
        mkRefreshScript "atlas-client-list-refresh-${env}" "atlas" [
          "dotnet run --project src/Atlas.ClientList.Refresh --configuration Release"
        ];

      cliMicrosoft365 = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.cli-microsoft365;

      conflictChecksRefreshScript =
        env:
        mkRefreshScript "atlas-conflict-checks-refresh-${env}" "project-scout/conflict-checks" [
          "uv run cck-refresh --work-dir outputs/${env}"
        ];

      elmRefreshScript = mkRefreshScript "atlas-elm-refresh" "project-scout/elm" (
        [
          "pwsh -NoProfile -NonInteractive -File scripts/Invoke-ElmRefresh.ps1"
        ]
        ++ publishToAllEnvironments "outputs/elm.duckdb" "elm.duckdb"
      );

      environments = [
        "dev"
        "prd"
      ];

      failureNotify = pkgs.writeShellScript "atlas-refresh-failed" ''
        unit="''${1%.service}"
        case "''${MONITOR_SERVICE_RESULT:-}" in
          timeout) why="Timed out (likely stuck waiting on sign-in)" ;;
          exit-code) why="Exited with status ''${MONITOR_EXIT_STATUS:-?}" ;;
          *) why="Result: ''${MONITOR_SERVICE_RESULT:-unknown}" ;;
        esac
        lastError=""
        nl=$'\n'
        if [[ -n ''${MONITOR_INVOCATION_ID:-} ]]; then
          lastError="$(${pkgs.systemd}/bin/journalctl --no-pager -o cat _SYSTEMD_INVOCATION_ID="$MONITOR_INVOCATION_ID" \
            | ${pkgs.gnused}/bin/sed 's/\x1b\[[0-9;]*m//g' \
            | ${pkgs.gnugrep}/bin/grep -iE 'error|exception|failed' | ${pkgs.gnugrep}/bin/grep -vE '^WARNING|<' \
            | ${pkgs.coreutils}/bin/tail -n1 | ${pkgs.coreutils}/bin/cut -c1-160)"
        fi
        # Toasts show at most three text lines, so the error goes first.
        exec ${notify} "$unit" "Atlas refresh failed: $unit" \
          "''${lastError:+$lastError$nl}$why. Logs: journalctl -eu $unit"
      '';

      mapRefreshScript = mkRefreshScript "atlas-map-refresh" "project-scout/map" (
        [
          "pwsh -NoProfile -NonInteractive -File scripts/Invoke-MapRefresh.ps1 -UvTempPath /tmp/atlas-map-refresh"
        ]
        ++ publishToAllEnvironments "outputs/map.duckdb" "map.duckdb"
      );

      mkRefreshScript =
        name: subdir: commands:
        pkgs.writeShellScript name ''
          set -euo pipefail
          cd ${subdir}
          ${lib.concatStringsSep "\n" commands}
        '';

      mkService =
        {
          description,
          environment ? { },
          path ? [ ],
          script,
        }:
        {
          inherit description environment path;
          onFailure = [ "atlas-refresh-failed@%n.service" ];
          serviceConfig = {
            ExecStart = "${runWithAuthWatch} %n ${pkgs.util-linux}/bin/flock ${repoPath} ${pkgs.devenv}/bin/devenv -q shell -- ${script}";
            TimeoutStartSec = "2h";
            Type = "oneshot";
            User = user;
            WorkingDirectory = repoPath;
          };
        };

      notify = pkgs.writeShellScript "atlas-notify" ''
        export ATLAS_TOAST_TAG="$1" ATLAS_TOAST_TITLE="$2" ATLAS_TOAST_BODY="$3" ATLAS_TOAST_URL="''${4:-}"
        export WSLENV=ATLAS_TOAST_TAG:ATLAS_TOAST_TITLE:ATLAS_TOAST_BODY:ATLAS_TOAST_URL
        exec /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -NonInteractive \
          -EncodedCommand "$(${pkgs.glibc.bin}/bin/iconv -f UTF-8 -t UTF-16LE ${toastScript} | ${pkgs.coreutils}/bin/base64 -w0)"
      '';

      publishDuckDb = source: blobName: env: ''
        uv run --native-tls --with azure-identity --with azure-storage-blob \
          python ../_shared/publish_duckdb_blob.py \
          --source ${source} \
          --environment ${env} \
          --container datasets \
          --name ${blobName}'';

      publishToAllEnvironments = source: blobName: map (publishDuckDb source blobName) environments;

      refreshOrder = [
        "atlas-map-refresh"
        "atlas-conflict-checks-refresh-dev"
        "atlas-conflict-checks-refresh-prd"
        "atlas-client-list-refresh-dev"
        "atlas-client-list-refresh-prd"
        "atlas-elm-refresh"
      ];

      repoPath = "/home/${user}/Documents/personal/repositories/Project-Atlas";

      runWithAuthWatch = pkgs.writeShellScript "atlas-run" ''
        set -uo pipefail
        unit="''${1%.service}"
        shift
        signInRe='[Ss]ign in with your ([^[:space:]]+) account( \(([^)]*)\))?'
        account=""
        nl=$'\n'
        "$@" 2>&1 | while IFS= read -r line || [[ -n $line ]]; do
          printf '%s\n' "$line"
          if [[ $line =~ $signInRe ]]; then
            account="''${BASH_REMATCH[1]}''${BASH_REMATCH[3]:+ (''${BASH_REMATCH[3]})}"
          elif [[ $line =~ (https://[^[:space:]]+).*enter\ (the\ )?code\ ([A-Z0-9]+) ]]; then
            url="''${BASH_REMATCH[1]}"
            code="''${BASH_REMATCH[3]}"
            ${notify} "$unit" "Atlas sign-in needed: $unit" \
              "''${account:+Sign in as $account$nl}Enter code $code at $url (expires ~15 min; a new code follows if missed)" "$url" \
              </dev/null >/dev/null 2>&1 &
            account=""
          fi
        done
        exit "''${PIPESTATUS[0]}"
      '';

      toastScript = pkgs.writeText "atlas-toast.ps1" ''
        $ErrorActionPreference = 'Stop'
        $ProgressPreference = 'SilentlyContinue'
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]
        function Esc([string]$s) { [Security.SecurityElement]::Escape($s) }
        $texts = @($env:ATLAS_TOAST_TITLE) + @($env:ATLAS_TOAST_BODY -split "`n" | Where-Object { $_ })
        $textXml = ($texts | Select-Object -First 3 | ForEach-Object { "<text>$(Esc $_)</text>" }) -join ""
        $openXml = if ($env:ATLAS_TOAST_URL) { "<action content='Open sign-in page' activationType='protocol' arguments='$(Esc $env:ATLAS_TOAST_URL)'/>" } else { "" }
        $xml = [Windows.Data.Xml.Dom.XmlDocument]::new()
        $xml.LoadXml("<toast scenario='reminder'><visual><binding template='ToastGeneric'>$textXml</binding></visual><actions>$openXml<action content='Dismiss' activationType='system' arguments='dismiss'/></actions></toast>")
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        $toast.Tag = $env:ATLAS_TOAST_TAG
        $toast.Group = 'atlas-refresh'
        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
      '';

      user = config.my.nixos.primaryUser;
    in
    {
      options.my.nixos.atlasRefreshJobs.overrides = lib.mkOption {
        default = { };
        type = lib.types.attrs;
      };

      config = {
        systemd = lib.recursiveUpdate {
          services =
            applyChain {
              atlas-client-list-refresh-dev = mkService {
                description = "Project Atlas: refresh client list replica and publish (dev)";
                environment = {
                  ATLAS_ENVIRONMENT = "dev";
                };
                script = clientListRefreshScript "dev";
              };

              atlas-client-list-refresh-prd = mkService {
                description = "Project Atlas: refresh client list replica and publish (prd)";
                environment = {
                  ATLAS_ENVIRONMENT = "prd";
                };
                script = clientListRefreshScript "prd";
              };

              atlas-conflict-checks-refresh-dev = mkService {
                description = "Project Atlas: refresh conflict checks and publish (dev)";
                environment.CCK_ENVIRONMENT = "dev";
                script = conflictChecksRefreshScript "dev";
              };

              atlas-conflict-checks-refresh-prd = mkService {
                description = "Project Atlas: refresh conflict checks and publish (prd)";
                environment.CCK_ENVIRONMENT = "prd";
                script = conflictChecksRefreshScript "prd";
              };

              atlas-elm-refresh = mkService {
                description = "Project Atlas: refresh ELM DuckDB and publish to dev and prd";
                environment = {
                  ELM_AGILOFT_PASSWORD_FILE = config.sops.secrets.atlas-elm-password.path;
                  ELM_AGILOFT_USERNAME_FILE = config.sops.secrets.atlas-elm-username.path;
                };
                script = elmRefreshScript;
              };

              atlas-map-refresh = mkService {
                description = "Project Atlas: refresh MAP DuckDB and publish to dev and prd";
                path = [ cliMicrosoft365 ];
                script = mapRefreshScript;
              };
            }
            // {
              "atlas-refresh-failed@" = {
                description = "Project Atlas: notify that %i failed";
                serviceConfig = {
                  ExecStart = "${failureNotify} %i";
                  Type = "oneshot";
                  User = user;
                };
              };
            };

          targets.atlas-refresh = {
            description = "Project Atlas: all refresh jobs";
            unitConfig.DefaultDependencies = false;
            unitConfig.StopWhenUnneeded = true;
            wants = map (n: "${n}.service") refreshOrder;
          };

          timers.atlas-refresh = {
            timerConfig = {
              OnCalendar = "*-*-* 00:00:00 America/Chicago";
              Persistent = true;
              Unit = "atlas-refresh.target";
            };
            wantedBy = [ "timers.target" ];
          };
        } cfg.overrides;
      };
    };
}
