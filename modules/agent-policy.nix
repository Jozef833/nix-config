_: {
  flake.modules.homeManager.agent-policy =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.agent-policy;

      settings = lib.recursiveUpdate {
        policyFile = ../packages/agent-policy/policy.json;
      } config.my.home.agent-policy.overrides;

      opencodePlugin = pkgs.writeText "agent-policy.js" ''
        const BIN = "${lib.getExe package}";
        const POLICY = "${settings.policyFile}";

        export const AgentPolicy = async () => ({
          "tool.execute.before": async (input, output) => {
            let verdict;
            try {
              if (input.tool !== "bash") return;
              const cmd = output?.args?.command;
              if (typeof cmd !== "string" || cmd.length === 0) return;
              const proc = Bun.spawnSync([BIN, "check", "--policy", POLICY], {
                stdin: new TextEncoder().encode(cmd),
              });
              if (proc.exitCode !== 0) return;
              const out = new TextDecoder().decode(proc.stdout).trim();
              if (out.length === 0) return; // silence means allow
              verdict = JSON.parse(out);
            } catch {
              return; // fail open when the engine is unavailable
            }
            if (verdict.action === "deny") {
              throw new Error(verdict.message);
            }
          },
        });
      '';
    in
    {
      options.my.home.agent-policy.overrides = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };

      config = {
        home = {
          packages = [ package ];
        };

        programs = {
          claude-code = {
            settings = {
              hooks = {
                PreToolUse = [
                  {
                    matcher = "Bash";
                    hooks = [
                      {
                        type = "command";
                        command = "${lib.getExe package} claude-hook --policy ${settings.policyFile}";
                      }
                    ];
                  }
                ];
              };
            };
          };

          opencode = {
            settings = {
              plugin = [ "${opencodePlugin}" ];
            };
          };
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.agent-policy = pkgs.callPackage (
        { buildGoModule, lib }:
        buildGoModule {
          meta = {
            description = "Bash policy engine for coding agents: teaching denials for Claude Code and OpenCode";
            license = lib.licenses.mit;
            mainProgram = "agent-policy";
          };
          pname = "agent-policy";
          src = ../packages/agent-policy;
          vendorHash = "sha256-tCFu9E2pFBWBQFiRVvI16FNI3dE1bUKJlsEbvDAo7lo=";
          version = "0.1.0";
        }
      ) { };
    };
}
