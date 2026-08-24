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

      mkTimer = time: {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* ${time} America/Chicago";
          Persistent = true;
          RandomizedDelaySec = "5m";
        };
      };
    in
    {
      options.my.nixos.atlasRefreshJobs.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        systemd = lib.recursiveUpdate {
          services = {
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

          timers = {
            atlas-map-refresh = mkTimer "00:00:00";
            atlas-conflict-checks-refresh-dev = mkTimer "01:00:00";
            atlas-conflict-checks-refresh-prd = mkTimer "01:30:00";
            atlas-client-list-refresh-dev = mkTimer "02:00:00";
            atlas-client-list-refresh-prd = mkTimer "03:00:00";
            atlas-elm-refresh = mkTimer "04:00:00";
          };
        } cfg.overrides;
      };
    };
}
