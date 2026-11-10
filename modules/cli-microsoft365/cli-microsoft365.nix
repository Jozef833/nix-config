{
  perSystem =
    { pkgs, ... }:
    {
      packages.cli-microsoft365 = pkgs.callPackage (
        {
          buildNpmPackage,
          fetchurl,
          lib,
        }:
        buildNpmPackage (finalAttrs: {
          pname = "cli-microsoft365";
          version = "11.9.0";

          src = fetchurl {
            url = "https://registry.npmjs.org/@pnp/cli-microsoft365/-/cli-microsoft365-${finalAttrs.version}.tgz";
            hash = "sha512-40yShIH5gBNZrkDRV6Vtkc0ru/4Cl5MWM2u4FN5MpKxKO/OGas7b1MwVMn8J1rywEdVrsQczLLzFmcXzVe3wgg==";
          };

          postPatch = ''
            rm -f npm-shrinkwrap.json
            cp ${./package-lock.json} package-lock.json
          '';

          npmDepsHash = "sha256-vtdNULPQo6vafuoVFCKJqABcuOEqk6srdFf90aQnKvw=";

          dontNpmBuild = true;

          meta = {
            description = "CLI for Microsoft 365 (m365) - manage Microsoft 365 and SharePoint Framework projects from any shell";
            homepage = "https://pnp.github.io/cli-microsoft365/";
            license = lib.licenses.mit;
            mainProgram = "m365";
          };
        })
      ) { };
    };

  flake.modules.homeManager.cli-microsoft365 =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      cliMicrosoft365 = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.cli-microsoft365;
      teamsIndex = pkgs.writeShellApplication {
        name = "teams-index";
        excludeShellChecks = [ "SC2016" ];
        runtimeInputs = [
          cliMicrosoft365
          pkgs.findutils
          pkgs.jq
        ];
        text = builtins.readFile ./teams-index.sh;
      };
    in
    {
      options.my.home.cli-microsoft365 = {
        entraAppId = lib.mkOption {
          type = lib.types.str;
          description = "Entra ID application (client) ID used for `m365 login` (public client, device code flow)";
        };
        entraTenantId = lib.mkOption {
          type = lib.types.str;
          description = "Entra ID tenant (directory) ID used for `m365 login`";
        };
      };

      config = {
        home = {
          packages = [
            cliMicrosoft365
            teamsIndex
          ];

          sessionVariables = {
            CLIMICROSOFT365_ENTRAAPPID = config.my.home.cli-microsoft365.entraAppId;
            CLIMICROSOFT365_TENANT = config.my.home.cli-microsoft365.entraTenantId;
          };
        };

        my.agentContext = "- Microsoft 365 (Teams, Outlook, files): `m365` is logged in as the user. Load the `m365` skill before using it.";

        programs = {
          claude-code.skills.m365 = ./SKILL.md;
          github-copilot-cli.skills.m365 = ./SKILL.md;
          opencode.skills.m365 = ./SKILL.md;
        };

        xdg.configFile."configstore/cli-m365-config.json" = {
          force = true;
          text = builtins.toJSON {
            disableTelemetry = true;
            helpMode = "full";
            output = "json";
            prompt = false;
            showHelpOnFailure = false;
          };
        };
      };
    };
}
