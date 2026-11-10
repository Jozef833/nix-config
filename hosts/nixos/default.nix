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
            "/mnt/cmh-mem-repo/cm" = {
              device = "\\\\cmh-mem-repo.milliman.com\\cm";
              fsType = "drvfs";
              options = [
                "uid=1000"
                "gid=100"
                "nofail" # don't block boot if share is unreachable
                "x-systemd.automount" # mount on first access, not at boot
                "x-systemd.idle-timeout=60"
              ];
            };

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
                "agiloft-elm-client-id" = {
                  owner = config.my.nixos.primaryUser;
                };
                "agiloft-elm-client-secret" = {
                  owner = config.my.nixos.primaryUser;
                };
                "anthropic-api-key" = {
                  owner = config.my.nixos.primaryUser;
                };
                "atlas-elm-password" = {
                  owner = config.my.nixos.primaryUser;
                };
                "atlas-elm-rest-password" = {
                  owner = config.my.nixos.primaryUser;
                };
                "atlas-elm-rest-username" = {
                  owner = config.my.nixos.primaryUser;
                };
                "atlas-elm-username" = {
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
                  adaptiveThinkingModels = [
                    "claude-opus-5-5"
                    "claude-sonnet-5-5"
                  ];
                  claudeThinkingOptions = {
                    thinking = {
                      display = "summarized";
                      type = "adaptive";
                    };
                  };
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
                                  "exa"
                                  "playwright"
                                ] config.programs.mcp.servers
                              );
                        };
                      };

                      cli-microsoft365 = {
                        entraAppId = "cb24f20f-b696-4030-9f95-82b06b399c70";
                        entraTenantId = "e240d61e-61e3-4c9e-ab90-8644b2f4d2a9";
                      };

                      extras = with pkgs; [
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
                            disabled_providers = [
                              "opencode"
                            ];
                            experimental = {
                              policies = [
                                {
                                  action = "provider.use";
                                  effect = "deny";
                                  resource = "opencode";
                                }
                              ];
                            };
                            provider = {
                              "github-copilot" = {
                                models = lib.genAttrs adaptiveThinkingModels (_: {
                                  options = claudeThinkingOptions;
                                });
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
      atlas-refresh-jobs
      base
      podman
      workstation
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
