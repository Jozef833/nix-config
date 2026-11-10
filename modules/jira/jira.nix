{
  flake.modules = {
    nixos.workstation =
      { config, ... }:
      {
        sops = {
          secrets.atlassian-api-key.owner = config.my.nixos.primaryUser;

          # restish refuses group/world-readable configs, so it can't live in the Nix store.
          templates."restish.json" = {
            owner = config.my.nixos.primaryUser;
            content = builtins.toJSON {
              apis.jira = {
                base_url = "https://cmhmilliman.atlassian.net";
                spec_url = "https://developer.atlassian.com/cloud/jira/platform/swagger-v3.v3.json";
                profiles.default.credentials.basicAuth.auth = {
                  type = "http-basic";
                  params = {
                    username = "jozef.porubcin@milliman.com";
                    password = config.sops.placeholder.atlassian-api-key;
                  };
                };
              };
            };
          };
        };
      };

    homeManager.workstation =
      {
        config,
        osConfig,
        pkgs,
        ...
      }:
      {
        home.packages = [ pkgs.restish ];

        my.agentContext = "- Jira: `restish jira <operation>` is installed and authenticated. Load the `jira` skill before using it.";

        programs = {
          claude-code.skills.jira = ./SKILL.md;
          github-copilot-cli.skills.jira = ./SKILL.md;
          opencode.skills.jira = ./SKILL.md;
        };

        xdg.configFile."restish/restish.json".source =
          config.lib.file.mkOutOfStoreSymlink
            osConfig.sops.templates."restish.json".path;
      };
  };
}
