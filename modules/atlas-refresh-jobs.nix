_: {
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

      publishRoot = "/mnt/t/AI";

      cliMicrosoft365 = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.cli-microsoft365;

      mkRefreshScript =
        name: subdir: commands:
        pkgs.writeShellScript name ''
          set -euo pipefail
          cd ${subdir}
          ${lib.concatStringsSep "\n" commands}
        '';

      mapRefreshScript = mkRefreshScript "atlas-map-refresh" "project-scout/map" [
        "pwsh -NoProfile -NonInteractive -File scripts/Invoke-MapRefresh.ps1 -UvTempPath /tmp/atlas-map-refresh"
        ''
          uv run --native-tls --with azure-identity --with azure-storage-blob \
            python ../_shared/publish_duckdb_blob.py \
            --source outputs/map.duckdb \
            --resource-group Project-Atlas_DEV \
            --account atlasdevdata \
            --container datasets \
            --name map.duckdb''
      ];

      elmRefreshScript = mkRefreshScript "atlas-elm-refresh" "project-scout/elm" [
        "pwsh -NoProfile -NonInteractive -File scripts/Invoke-ElmRefresh.ps1 -Publish -PublishRoot ${publishRoot}"
      ];

      conflictChecksRefreshScript =
        mkRefreshScript "atlas-conflict-checks-refresh" "project-scout/conflict-checks"
          [
            "uv run cck-refresh"
          ];

      clientListRefreshScript = mkRefreshScript "atlas-client-list-refresh" "atlas" [
        "dotnet run --project src/Atlas.ClientList.Refresh --configuration Release"
      ];

      mkService =
        {
          description,
          script,
          path ? [ ],
          requiresMount ? false,
        }:
        {
          inherit description path;
          unitConfig = lib.optionalAttrs requiresMount {
            RequiresMountsFor = [ "/mnt/t" ];
          };
          serviceConfig = {
            Type = "oneshot";
            User = user;
            WorkingDirectory = repoPath;
            ExecStart = "${pkgs.devenv}/bin/devenv -q shell -- ${script}";
            TimeoutStartSec = "2h";
          };
        };

      mkTimer = time: {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* ${time} America/Chicago";
          Persistent = true;
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
            atlas-map-refresh = mkService {
              description = "Project Atlas: refresh MAP DuckDB and publish to blob";
              script = mapRefreshScript;
              path = [ cliMicrosoft365 ];
            };

            atlas-elm-refresh = mkService {
              description = "Project Atlas: refresh ELM DuckDB and publish";
              script = elmRefreshScript;
              requiresMount = true;
            };

            atlas-conflict-checks-refresh = mkService {
              description = "Project Atlas: refresh conflict checks and publish";
              script = conflictChecksRefreshScript;
            };

            atlas-client-list-refresh = mkService {
              description = "Project Atlas: refresh client list replica and publish";
              script = clientListRefreshScript;
            };
          };

          timers = {
            atlas-map-refresh = mkTimer "00:00:00";
            atlas-elm-refresh = mkTimer "00:05:00";
            atlas-conflict-checks-refresh = mkTimer "00:10:00";
            atlas-client-list-refresh = mkTimer "00:15:00";
          };
        } cfg.overrides;
      };
    };
}
