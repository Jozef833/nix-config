{ config, inputs, ... }:
let
  homeAspects = with config.flake.modules.homeManager; [
    agent-policy
    azure-cli
    bash
    claude-code
    cli-microsoft365
    direnv
    gh
    git
    github-copilot-cli
    home
    lazygit
    mcp
    milliman-timesheet-cli
    nvf
    opencode
    secretspec
    ssh
    ungoogled-chromium
  ];
in
{
  hosts.nixos.nixos = {
    modules = [
      inputs.home-manager.nixosModules.home-manager
      inputs.nixos-wsl.nixosModules.default
      inputs.sops-nix.nixosModules.sops

      (
        { config, lib, ... }:
        {
          networking = {
            hostName = "nixos";
          };

          fileSystems = {
            "/mnt/h" = {
              device = "H:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/i" = {
              device = "I:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/l" = {
              device = "L:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/n" = {
              device = "N:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/network/o" = {
              device = "//milw-isilon-prod-smb.milliman.com/milwh-users$/jozef.porubcin";
              fsType = "cifs";
              options = [
                "credentials=/run/secrets/samba-credentials"
                "domain=milliman.com"
                "uid=1000"
                "gid=100"
                "file_mode=0600"
                "dir_mode=0700"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/network/t/MISC" = {
              device = "//milw-isilon-prod-smb.milliman.com/milwh-docs$/MISC";
              fsType = "cifs";
              options = [
                "credentials=/run/secrets/samba-credentials"
                "domain=milliman.com"
                "uid=1000"
                "gid=100"
                "file_mode=0600"
                "dir_mode=0700"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/o" = {
              device = "O:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/p" = {
              device = "P:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/q" = {
              device = "Q:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/s" = {
              device = "S:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/t" = {
              device = "T:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/u" = {
              device = "U:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/v" = {
              device = "V:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/w" = {
              device = "W:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

            "/mnt/x" = {
              device = "X:";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };
          };

          security = {
            pki = {
              certificateFiles = [
                (inputs.self + "/hosts/nixos/ZscalerRootCertificate-2048-SHA256-Feb2025.crt")
              ];
            };
          };

          my = {
            nixos = {
              primaryUser = "nixos";
              stateVersion = "25.05";
            };

            nixpkgs = {
              overrides = {
                config = {
                  allowUnfreePredicate =
                    pkg:
                    builtins.elem (lib.getName pkg) [
                      "acli-unwrapped"
                      "claude-code"
                      "github-copilot-cli"
                    ];
                };
              };
            };

            sops = {
              ageKeyFile = "/home/${config.my.nixos.primaryUser}/.config/sops/age/keys.txt";
              defaultSopsFile = inputs.self + "/hosts/nixos/secrets.yaml";
              secrets = {
                "anthropic-api-key" = {
                  owner = config.my.nixos.primaryUser;
                };
                "atlas-elm-password" = {
                  owner = config.my.nixos.primaryUser;
                };
                "azure-foundry-api-key" = {
                  owner = config.my.nixos.primaryUser;
                };
                "samba-credentials" = {
                  owner = "root";
                };
                "ssh-azure-devops" = {
                  owner = config.my.nixos.primaryUser;
                };
                "ssh-github" = {
                  owner = config.my.nixos.primaryUser;
                };
              };
            };
          };
        }
      )

      (
        { config, ... }:
        {
          home-manager = {
            extraSpecialArgs = {
              inherit inputs;
            };
            useGlobalPkgs = true;
            useUserPackages = true;
            users = {
              ${config.my.nixos.primaryUser} =
                {
                  config,
                  inputs,
                  lib,
                  pkgs,
                  ...
                }:
                let
                  azureFoundryClaudeDeployments = [
                    "claude-fable-5"
                    "claude-haiku-4-5"
                    "claude-opus-5"
                    "claude-sonnet-5"
                  ];
                  signingKey = "/run/secrets/ssh-github";
                in
                {
                  imports = homeAspects ++ [
                    inputs.nvf.homeManagerModules.default
                  ];

                  home = {
                    file = {
                      ".ssh/allowed_signers".text =
                        "172046463+Jozef833@users.noreply.github.com "
                        + builtins.readFile (inputs.self + "/keys/ssh-github.pub");
                    };
                  };

                  my = {
                    home = {
                      claude-code = {
                        overrides = {
                          mcpServers =
                            lib.mapAttrs
                              (
                                _name: server:
                                lib.hm.mcp.transformMcpServer {
                                  inherit server;
                                  exclude = [ "enabled" ];
                                  extraTransforms = [ lib.hm.mcp.addType ];
                                }
                              )
                              (
                                lib.getAttrs [
                                  "atlassian"
                                  "exa"
                                  "m365"
                                  "playwright"
                                ] config.programs.mcp.servers
                              );
                          settings = {
                            apiKeyHelper = "cat /run/secrets/anthropic-api-key";
                            env = {
                              DISABLE_LOGIN_COMMAND = 1;
                              DISABLE_LOGOUT_COMMAND = 1;
                            };
                          };
                        };
                      };

                      cli-microsoft365 = {
                        entraAppId = "cb24f20f-b696-4030-9f95-82b06b399c70";
                        entraTenantId = "e240d61e-61e3-4c9e-ab90-8644b2f4d2a9";
                      };

                      extras = with pkgs; [
                        acli.unwrapped
                        (writeShellScriptBin "claude-foundry" ''
                          set -euo pipefail
                          export ANTHROPIC_DEFAULT_FABLE_MODEL="''${ANTHROPIC_DEFAULT_FABLE_MODEL:-claude-fable-5}"
                          export ANTHROPIC_DEFAULT_HAIKU_MODEL="''${ANTHROPIC_DEFAULT_HAIKU_MODEL:-claude-haiku-4-5}"
                          export ANTHROPIC_DEFAULT_OPUS_MODEL="''${ANTHROPIC_DEFAULT_OPUS_MODEL:-claude-opus-5}"
                          export ANTHROPIC_DEFAULT_SONNET_MODEL="''${ANTHROPIC_DEFAULT_SONNET_MODEL:-claude-sonnet-5}"
                          ANTHROPIC_FOUNDRY_API_KEY="$(cat /run/secrets/azure-foundry-api-key)"
                          export ANTHROPIC_FOUNDRY_API_KEY
                          export ANTHROPIC_FOUNDRY_BASE_URL="https://eastus2.api.cognitive.microsoft.com/anthropic"
                          export CLAUDE_CODE_USE_FOUNDRY=1
                          exec claude "$@"
                        '')
                        wl-clipboard
                      ];

                      git = {
                        inherit signingKey;
                        userEmail = "172046463+Jozef833@users.noreply.github.com";
                        userName = "Jozef833";
                      };

                      mcp = {
                        overrides = {
                          servers = {
                            atlassian = {
                              disabled = true;
                              url = "https://mcp.atlassian.com/v1/mcp";
                            };
                            context7 = {
                              disabled = true;
                              url = "https://mcp.context7.com/mcp";
                            };
                            m365 = {
                              disabled = true;
                              command = "${
                                inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.cli-microsoft365-mcp-server
                              }/bin/cli-microsoft365-mcp-server";
                              env = {
                                CLIMICROSOFT365_ENTRAAPPID = config.my.home.cli-microsoft365.entraAppId;
                                CLIMICROSOFT365_TENANT = config.my.home.cli-microsoft365.entraTenantId;
                              };
                            };
                            microsoft-learn = {
                              disabled = true;
                              url = "https://learn.microsoft.com/api/mcp";
                            };
                          };
                        };
                      };

                      opencode = {
                        overrides = {
                          settings = {
                            provider = {
                              anthropic = {
                                options = {
                                  apiKey = "{file:/run/secrets/anthropic-api-key}";
                                };
                              };
                              "azure-foundry" = {
                                models = lib.genAttrs azureFoundryClaudeDeployments (deployment: {
                                  attachment = true;
                                  name = deployment;
                                  reasoning = true;
                                  temperature = true;
                                  tool_call = true;
                                });
                                name = "Azure Foundry (Anthropic)";
                                npm = "@ai-sdk/anthropic";
                                options = {
                                  apiKey = "{file:/run/secrets/azure-foundry-api-key}";
                                  baseURL = "https://eastus2.api.cognitive.microsoft.com/anthropic/v1";
                                };
                              };
                              "azure-foundry-openai" = {
                                models = {
                                  "DeepSeek-V4-Pro" = {
                                    attachment = false;
                                    reasoning = true;
                                    temperature = true;
                                    tool_call = true;
                                  };
                                  "gpt-5.6-luna" = {
                                    attachment = true;
                                    reasoning = true;
                                    temperature = true;
                                    tool_call = true;
                                  };
                                  "gpt-5.6-sol" = {
                                    attachment = true;
                                    reasoning = true;
                                    temperature = true;
                                    tool_call = true;
                                  };
                                  "gpt-5.6-terra" = {
                                    attachment = true;
                                    reasoning = true;
                                    temperature = true;
                                    tool_call = true;
                                  };
                                  "model-router" = {
                                    attachment = true;
                                    reasoning = true;
                                    temperature = true;
                                    tool_call = true;
                                  };
                                };
                                name = "Azure Foundry (OpenAI-compatible)";
                                npm = "@ai-sdk/openai-compatible";
                                options = {
                                  apiKey = "{file:/run/secrets/azure-foundry-api-key}";
                                  baseURL = "https://eastus2.api.cognitive.microsoft.com/openai/v1";
                                };
                              };
                            };
                          };
                        };
                      };

                      secretspec = {
                        provider = "dotenv";
                      };

                      ssh = {
                        overrides = {
                          settings = {
                            "github.com" = {
                              AddKeysToAgent = "yes";
                              IdentitiesOnly = true;
                              IdentityFile = signingKey;
                            };
                            "ssh.dev.azure.com" = {
                              AddKeysToAgent = "yes";
                              IdentitiesOnly = true;
                              IdentityFile = "/run/secrets/ssh-azure-devops";
                            };
                          };
                        };
                      };

                      stateVersion = "25.05";
                    };
                  };
                };
            };
          };
        }
      )
    ]
    ++ (with config.flake.modules.nixos; [
      #atlas-refresh-jobs
      base
      podman
      wsl
      xdg-portal
    ])
    ++ (with config.flake.modules.generic; [
      nix
      nixpkgs
      sops
      system
    ]);

    system = "x86_64-linux";
  };
}
