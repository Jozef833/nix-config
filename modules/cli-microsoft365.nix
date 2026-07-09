_: {
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
            cp ${./cli-microsoft365-package-lock.json} package-lock.json
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
          packages = [ cliMicrosoft365 ];

          sessionVariables = {
            CLIMICROSOFT365_ENTRAAPPID = config.my.home.cli-microsoft365.entraAppId;
            CLIMICROSOFT365_TENANT = config.my.home.cli-microsoft365.entraTenantId;
          };
        };

        xdg.configFile."configstore/cli-m365-config.json" = {
          force = true;
          text = builtins.toJSON {
            prompt = true;
            output = "json";
            helpMode = "full";
          };
        };
      };
    };
}
