{ config, inputs, ... }:
let
  homeAspects = with config.flake.modules.homeManager; [
    azure-cli
    bash
    claude-code
    direnv
    eilmeldung
    gh
    git
    home
    lazygit
    librewolf
    mcp
    nvf
    opencode
    ssh
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
                      extras = with pkgs; [
                        wl-clipboard
                      ];

                      claude-code = {
                        overrides = {
                          mcpServers = lib.mapAttrs (
                            _name: server:
                            lib.hm.mcp.transformMcpServer {
                              inherit server;
                              exclude = [ "enabled" ];
                              extraTransforms = [ lib.hm.mcp.addType ];
                            }
                          ) (lib.getAttrs [ "atlassian" "playwright" ] config.programs.mcp.servers);
                          settings = {
                            apiKeyHelper = "cat /run/secrets/anthropic-api-key";
                            env = {
                              DISABLE_LOGIN_COMMAND = 1;
                              DISABLE_LOGOUT_COMMAND = 1;
                            };
                          };
                        };
                      };

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
                            };
                          };
                        };
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
