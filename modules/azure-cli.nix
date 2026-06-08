_: {
  flake.modules.homeManager.azure-cli =
    { pkgs, ... }:
    let
      azure-cli-wrapped = pkgs.symlinkJoin {
        name = "azure-cli-wrapped";
        nativeBuildInputs = with pkgs; [ makeWrapper ];
        paths = with pkgs; [
          (azure-cli.withExtensions (
            with azure-cli.extensions;
            [
              application-insights
              azure-devops
              #containerapp
              log-analytics
              resource-graph
            ]
          ))
        ];
        postBuild = ''
          wrapProgram $out/bin/az \
            --set AZURE_CORE_COLLECT_TELEMETRY 0 \
            --set-default REQUESTS_CA_BUNDLE /etc/ssl/certs/ca-certificates.crt
        '';
      };
    in
    {
      home = {
        packages = [
          azure-cli-wrapped
        ];
      };
    };
}
