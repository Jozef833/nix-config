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
      cfg = config.my.nixos.atlasRefreshJobs;

      user = config.my.nixos.primaryUser;
      repoPath = "/home/${user}/Documents/personal/repositories/Project-Atlas";

      cliMicrosoft365 = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.cli-microsoft365;

      environments = [
        "dev"
        "prd"
      ];

      mkRefreshScript =
        name: subdir: commands:
        pkgs.writeShellScript name ''
          set -euo pipefail
          cd ${subdir}
          ${lib.concatStringsSep "\n" commands}
        '';

      publishDuckDb = source: blobName: env: ''
        uv run --native-tls --with azure-identity --with azure-storage-blob \
          python ../_shared/publish_duckdb_blob.py \
          --source ${source} \
          --environment ${env} \
          --container datasets \
          --name ${blobName}'';

      publishToAllEnvironments = source: blobName: map (publishDuckDb source blobName) environments;

      clientListRefreshScript =
        env:
        mkRefreshScript "atlas-client-list-refresh-${env}" "atlas" [
          "dotnet run --project src/Atlas.ClientList.Refresh --configuration Release"
        ];

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

      mapRefreshScript = mkRefreshScript "atlas-map-refresh" "project-scout/map" (
        [
          "pwsh -NoProfile -NonInteractive -File scripts/Invoke-MapRefresh.ps1 -UvTempPath /tmp/atlas-map-refresh"
        ]
        ++ publishToAllEnvironments "outputs/map.duckdb" "map.duckdb"
      );

      mkService =
        {
          description,
          script,
          path ? [ ],
          environment ? { },
        }:
        {
          inherit description path environment;
          serviceConfig = {
            Type = "oneshot";
            User = user;
            WorkingDirectory = repoPath;
            ExecStart = "${pkgs.util-linux}/bin/flock ${repoPath} ${pkgs.devenv}/bin/devenv -q shell -- ${script}";
            TimeoutStartSec = "2h";
          };
        };

      refreshOrder = [
        "atlas-map-refresh"
        "atlas-conflict-checks-refresh-dev"
        "atlas-conflict-checks-refresh-prd"
        "atlas-client-list-refresh-dev"
        "atlas-client-list-refresh-prd"
        "atlas-elm-refresh"
      ];

      chainAfter = lib.listToAttrs (
        lib.imap0 (
          i: name:
          lib.nameValuePair name (
            if i == 0 then [ ] else [ "${builtins.elemAt refreshOrder (i - 1)}.service" ]
          )
        ) refreshOrder
      );

      applyChain = lib.mapAttrs (
        name: svc: svc // { after = (svc.after or [ ]) ++ (chainAfter.${name} or [ ]); }
      );
    in
    {
      options.my.nixos.atlasRefreshJobs.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        systemd = lib.recursiveUpdate {
          services = applyChain {
            atlas-client-list-refresh-dev = mkService {
              description = "Project Atlas: refresh client list replica and publish (dev)";
              script = clientListRefreshScript "dev";
              environment = {
                ATLAS_ENVIRONMENT = "dev";
              };
            };

            atlas-client-list-refresh-prd = mkService {
              description = "Project Atlas: refresh client list replica and publish (prd)";
              script = clientListRefreshScript "prd";
              environment = {
                ATLAS_ENVIRONMENT = "prd";
              };
            };

            atlas-conflict-checks-refresh-dev = mkService {
              description = "Project Atlas: refresh conflict checks and publish (dev)";
              script = conflictChecksRefreshScript "dev";
              environment.CCK_ENVIRONMENT = "dev";
            };

            atlas-conflict-checks-refresh-prd = mkService {
              description = "Project Atlas: refresh conflict checks and publish (prd)";
              script = conflictChecksRefreshScript "prd";
              environment.CCK_ENVIRONMENT = "prd";
            };

            atlas-elm-refresh = mkService {
              description = "Project Atlas: refresh ELM DuckDB and publish to dev and prd";
              script = elmRefreshScript;
              environment = {
                ELM_AGILOFT_PASSWORD_FILE = config.sops.secrets.atlas-elm-password.path;
              };
            };

            atlas-map-refresh = mkService {
              description = "Project Atlas: refresh MAP DuckDB and publish to dev and prd";
              script = mapRefreshScript;
              path = [ cliMicrosoft365 ];
            };
          };

          targets.atlas-refresh = {
            description = "Project Atlas: all refresh jobs";
            wants = map (n: "${n}.service") refreshOrder;

            # Per systemd.target(5), a target with DefaultDependencies=yes implicitly
            # gains After= on everything it Wants=. That makes this target's *start job*
            # block until the entire refresh chain finishes (up to 6 x TimeoutStartSec).
            #
            # switch-to-configuration puts every active/activating target into
            # /run/nixos/start-list, submits a StartUnit job for each, and then blocks on
            # the JobRemoved D-Bus signal for all of them. So if this target happens to be
            # activating during a rebuild (e.g. the Persistent=true timer below firing for
            # a missed window), `nixos-rebuild switch` hangs for as long as the refresh
            # chain runs -- which is forever if a job is stuck on interactive auth.
            #
            # DefaultDependencies=no drops that implicit ordering: the target activates
            # immediately, the services still get pulled in via Wants= and run in the
            # background, and the rebuild is never held hostage by a data refresh.
            unitConfig.DefaultDependencies = false;
          };

          timers.atlas-refresh = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "*-*-* 00:00:00 America/Chicago";
              Persistent = true;
              Unit = "atlas-refresh.target";
            };
          };
        } cfg.overrides;
      };
    };
}
