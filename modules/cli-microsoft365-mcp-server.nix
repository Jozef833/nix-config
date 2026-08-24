{
  perSystem =
    { config, pkgs, ... }:
    let
      cliMicrosoft365 = config.packages.cli-microsoft365;

      unwrapped = pkgs.callPackage (
        {
          buildNpmPackage,
          fetchFromGitHub,
          lib,
        }:
        buildNpmPackage {
          pname = "cli-microsoft365-mcp-server";
          version = "0.1.22";

          src = fetchFromGitHub {
            owner = "pnp";
            repo = "cli-microsoft365-mcp-server";
            rev = "0df64533d6d9a288d57bea67305c70f759bb99ba";
            hash = "sha256-Ew7WMizMRN89kaV5WqsKuRyk7FINBbuIpdDesNrdpwI=";
          };

          npmDepsHash = "sha256-Lrmlq+iNzukE7K5UYJeQyp9jJ9YYCeLZ2utZaDzqgG4=";

          meta = {
            description = "MCP server exposing CLI for Microsoft 365 (m365) commands to AI assistants";
            homepage = "https://github.com/pnp/cli-microsoft365-mcp-server";
            license = lib.licenses.mit;
            mainProgram = "cli-microsoft365-mcp-server";
          };
        }
      ) { };

      npmGlobalPrefix = pkgs.runCommand "cli-microsoft365-mcp-server-npm-global-prefix" { } ''
        mkdir -p $out/lib/node_modules/@pnp
        ln -s ${cliMicrosoft365}/lib/node_modules/@pnp/cli-microsoft365 $out/lib/node_modules/@pnp/cli-microsoft365
      '';

      cliMicrosoft365McpConfig = pkgs.writeTextDir "configstore/cli-m365-config.json" (
        builtins.toJSON {
          prompt = false;
          output = "json";
          helpMode = "full";
        }
      );
    in
    {
      packages.cli-microsoft365-mcp-server = pkgs.symlinkJoin {
        name = "cli-microsoft365-mcp-server";
        paths = [ unwrapped ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/cli-microsoft365-mcp-server \
            --set NPM_CONFIG_PREFIX ${npmGlobalPrefix} \
            --set XDG_CONFIG_HOME ${cliMicrosoft365McpConfig} \
            --set CLIMICROSOFT365_NOUPDATE 1 \
            --prefix PATH : ${
              pkgs.lib.makeBinPath [
                pkgs.nodejs
                cliMicrosoft365
              ]
            }
        '';
      };
    };
}
