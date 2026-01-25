{
  pname,
  pkgs,
  flake,
}: let
  formatter = pkgs.writeShellApplication {
    name = pname;

    runtimeInputs = [
      pkgs.alejandra
      pkgs.deadnix
    ];

    text = ''
      set -euo pipefail

      # If no arguments are passed, default to formatting the whole project
      if [[ $# = 0 ]]; then
        prj_root=$(git rev-parse --show-toplevel 2>/dev/null || echo .)
        set -- "$prj_root"
      fi

      set -x

      alejandra "$@"
      deadnix --no-lambda-pattern-names --fail "$@"
    '';

    meta = {
      description = "lint and format the repo";
    };
  };
in
  formatter
