{
  flake.modules.homeManager.workstation =
    { config, lib, ... }:
    {
      options.my.agentContext = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Always-loaded environment facts for coding agents. Features append lines under the services heading.";
      };

      config = {
        my.agentContext = lib.mkBefore ''
          # Working environment

          This machine is NixOS running in WSL2 on a Windows host.

          - Globally installed tools are exactly those declared in ~/nix-config, but any nixpkgs package runs via
            `nix shell nixpkgs#<pkg> --command <cmd>`, inside or outside a dev shell. Treat that as installed: if a
            tool is the best fit, use it this way rather than settling for an alternative. Only change ~/nix-config
            when a tool is needed permanently, and ask the user first.
          - For Python with libraries, build one environment:
            `nix shell --impure --expr 'let pkgs = (builtins.getFlake "nixpkgs").legacyPackages.''${builtins.currentSystem}; in pkgs.python3.withPackages (ps: [ ps.requests ])' --command python ...`
          - Repositories with `flake.nix`, `devenv.nix`, or `.envrc` have their own dev shell.
          - The Windows filesystem is fully accessible: C: is at `/mnt/c` (user profile
            `/mnt/c/Users/Jozef.Porubcin`), and other drives and network shares are under `/mnt`. It's slower than the
            Linux filesystem.
          - Windows programs on PATH run directly (`powershell.exe`, `cmd.exe`). `docker` and `npm` resolve to
            Windows programs; `podman` is the Linux container runtime. `xdg-open` opens URLs in the Windows browser.
          - Don't print secrets from `/run/secrets` or CLI credential files.

          ## Configured services
        '';

        programs = {
          claude-code.context = config.my.agentContext;
          github-copilot-cli.context = config.my.agentContext;
          opencode.context = config.my.agentContext;
        };
      };
    };
}
