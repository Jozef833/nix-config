{
  flake.modules.homeManager.grok-build =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.home.grok-build;

      package =
        if cfg.envFiles == { } then
          pkgs.grok-build
        else
          pkgs.symlinkJoin {
            name = "grok-build-wrapped";
            nativeBuildInputs = with pkgs; [
              makeWrapper
            ];
            paths = with pkgs; [
              grok-build
            ];
            postBuild = ''
              wrapProgram $out/bin/grok \
                ${lib.concatStringsSep " \\\n                " (
                  lib.mapAttrsToList (
                    name: file: "--run ${lib.escapeShellArg "export ${name}=\"$(cat ${file})\""}"
                  ) cfg.envFiles
                )}
              ln -sf grok $out/bin/agent
            '';
          };

      tomlFormat = pkgs.formats.toml { };

      toGrokMcpServer =
        name: server:
        lib.hm.mcp.transformMcpServer {
          inherit server;
          exclude = [ "type" ];
          extraTransforms = [
            (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
          ];
        };

      transformedMcpServers =
        if cfg.enableMcpIntegration && config.programs.mcp.enable && config.programs.mcp.servers != { } then
          lib.mapAttrs toGrokMcpServer config.programs.mcp.servers
        else
          { };
    in
    {
      options.my.home.grok-build = {
        enableMcpIntegration = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to integrate the MCP servers config from
            `programs.mcp.servers` into `[mcp_servers.*]` in
            `~/.grok/config.toml`.
          '';
        };
        envFiles = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
        };
        hooks = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf tomlFormat.type);
          default = { };
          description = ''
            Grok hook groups merged into `[[hooks.<Event>]]` in
            `~/.grok/config.toml`, keyed by event name. Mergeable across
            multiple modules (e.g. agent-policy).
          '';
        };
        overrides = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
      };

      config = {
        home = {
          file = {
            ".grok/config.toml" = {
              force = true;
              source = tomlFormat.generate "grok-build-config.toml" (
                lib.recursiveUpdate {
                  cli = {
                    auto_update = false;
                    show_tips = false;
                  };
                  compat = {
                    claude = {
                      hooks = false;
                    };
                  };
                  features = {
                    telemetry = false;
                  };
                  inherit (cfg) hooks;
                  marketplace = {
                    default_skills_installs_purged = true;
                  };
                  mcp_servers = transformedMcpServers;
                  telemetry = {
                    otel_enabled = false;
                    trace_upload = false;
                  };
                } cfg.overrides
              );
            };
          };
          packages = [
            package
          ];
        };
      };
    };
}
