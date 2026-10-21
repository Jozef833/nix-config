{
  flake = {
    modules = {
      homeManager = {
        codex =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            # Copilot's /models response uses a different schema from Codex's catalog.
            modelCatalog = pkgs.runCommand "codex-model-catalog.json" { } ''
              HOME="$TMPDIR" CODEX_HOME="$TMPDIR" ${lib.getExe pkgs.codex} debug models --bundled > "$out"
            '';
          in
          {
            options = {
              my = {
                home = {
                  codex = {
                    overrides = lib.mkOption {
                      type = lib.types.attrs;
                      default = { };
                    };
                  };
                };
              };
            };

            config = {
              programs = {
                codex = lib.recursiveUpdate {
                  enable = true;
                  enableMcpIntegration = true;
                  mutableSettings = true;
                  settings = {
                    analytics = {
                      enabled = false;
                    };
                    approval_policy = "never";
                    check_for_update_on_startup = false;
                    features = {
                      apps = false;
                      memories = false;
                    };
                    feedback = {
                      enabled = false;
                    };
                    hide_agent_reasoning = false;
                    memories = {
                      generate_memories = false;
                      use_memories = false;
                    };
                    model = "gpt-6.1-sol";
                    model_catalog_json = "${modelCatalog}";
                    model_context_window = 1000000;
                    model_provider = "github-copilot";
                    model_reasoning_effort = "high";
                    model_reasoning_summary = "detailed";
                    model_providers = {
                      github-copilot = {
                        name = "GitHub Copilot";
                        base_url = "https://api.githubcopilot.com";
                        auth = {
                          command = lib.getExe pkgs.gh;
                          args = [
                            "auth"
                            "token"
                            "--hostname"
                            "github.com"
                          ];
                        };
                        http_headers = {
                          Copilot-Integration-Id = "vscode-chat";
                          Editor-Version = "Codex";
                        };
                      };
                    };
                    personality = "pragmatic";
                    sandbox_mode = "danger-full-access";
                    show_raw_agent_reasoning = true;
                    skills = {
                      config = [
                        {
                          path = "${config.home.homeDirectory}/.codex/skills/.system/imagegen";
                          enabled = false;
                        }
                        {
                          path = "${config.home.homeDirectory}/.codex/skills/.system/openai-docs";
                          enabled = false;
                        }
                        {
                          path = "${config.home.homeDirectory}/.codex/skills/.system/skill-creator";
                          enabled = false;
                        }
                        {
                          path = "${config.home.homeDirectory}/.codex/skills/.system/skill-installer";
                          enabled = false;
                        }
                      ];
                    };
                    web_search = "live";
                  };
                } config.my.home.codex.overrides;
              };
            };
          };
      };
    };
  };
}
