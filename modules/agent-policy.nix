_: {
  flake.modules.homeManager.agent-policy =
    {
      config,
      inputs,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.agent-policy;

      settings = lib.recursiveUpdate {
        classes = {
          home = [ config.home.homeDirectory ];
          # Slow drvfs/cifs mounts come straight from the host's fileSystems,
          # so adding a mount teaches the policy about it automatically.
          network = lib.attrNames (
            lib.filterAttrs (
              _mountPoint: fs:
              builtins.elem fs.fsType [
                "cifs"
                "drvfs"
              ]
            ) osConfig.fileSystems
          );
          nix-store = [ "/nix" ];
          repos = [ "${config.home.homeDirectory}/Documents/personal/repositories" ];
          root = [ "/" ];
          windows = [ "/mnt/c" ];
        };
        policyFile = ../packages/agent-policy/policy.json;
      } config.my.home.agent-policy.overrides;

      classesFile = pkgs.writeText "agent-policy-classes.json" (builtins.toJSON settings.classes);

      engineFlags = "--policy ${settings.policyFile} --classes ${classesFile}";

      opencodePlugin = pkgs.writeText "agent-policy.js" ''
        const BIN = "${lib.getExe package}";
        const FLAGS = ["--policy", "${settings.policyFile}", "--classes", "${classesFile}"];

        export const AgentPolicy = async ({ directory }) => ({
          "tool.execute.before": async (input, output) => {
            let verdict;
            try {
              if (input.tool !== "bash") return;
              const cmd = output?.args?.command;
              if (typeof cmd !== "string" || cmd.length === 0) return;
              const proc = Bun.spawnSync([BIN, "check", ...FLAGS, "--cwd", directory], {
                stdin: new TextEncoder().encode(cmd),
              });
              if (proc.exitCode !== 0) return;
              verdict = JSON.parse(new TextDecoder().decode(proc.stdout));
            } catch {
              return; // fail open when the engine is unavailable
            }
            if (verdict.action === "deny") {
              throw new Error(verdict.message);
            }
            if (verdict.action === "rewrite" && typeof verdict.command === "string") {
              output.args.command = verdict.command;
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
                        command = "${lib.getExe package} claude-hook ${engineFlags}";
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
            description = "Bash policy engine for coding agents: teaching denials and budget rewrites for Claude Code and OpenCode";
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
