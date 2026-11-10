{
  # The Copilot desktop app runs on Windows and reads personal skills from the Windows profile,
  # which can't follow WSL symlinks into /nix/store, so the managed skills are copied there.
  flake.modules.homeManager.workstation =
    { config, lib, ... }:
    let
      source = "${config.home.homeDirectory}/.copilot/skills";
      target = "/mnt/c/Users/Jozef.Porubcin/.copilot/skills";
    in
    {
      home.activation.copilotWindowsSkills = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [[ -d ${lib.escapeShellArg (dirOf (dirOf target))} ]]; then
          target=${lib.escapeShellArg target}
          manifest="$target/.nix-managed"
          run mkdir -p "$target"

          if [[ -f $manifest ]]; then
            while IFS= read -r name; do
              [[ -n $name ]] && run rm -rf "$target/$name"
            done < "$manifest"
          fi

          names=()
          for dir in ${lib.escapeShellArg source}/*/; do
            [[ -d $dir ]] || continue
            name=$(basename "$dir")
            if [[ -e $target/$name ]]; then
              warnEcho "Not overwriting unmanaged Windows Copilot skill: $target/$name"
              continue
            fi
            run cp -rL --no-preserve=mode,ownership "$dir" "$target/$name"
            names+=("$name")
          done

          if [[ ! -v DRY_RUN ]]; then
            printf '%s\n' "''${names[@]}" > "$manifest"
          fi
        fi
      '';
    };
}
