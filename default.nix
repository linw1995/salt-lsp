{
  lib,
  config,
  dream2nix,
  ...
}: let
  pkgs = config.deps.pkgs;
in {
  imports = [
    dream2nix.modules.dream2nix.WIP-python-pdm
  ];

  deps = {nixpkgs, ...}: {
    pkgs = nixpkgs;
    python = nixpkgs.python311;
  };

  mkDerivation = {
    src = lib.cleanSourceWith {
      src = lib.cleanSource ./.;
      filter = name: type:
        !(builtins.any (x: x) [
          (lib.hasSuffix ".nix" name)
          (lib.hasPrefix "." (builtins.baseNameOf name))
          (lib.hasSuffix "flake.lock" name)
        ]);
    };
    nativeBuildInputs =
      [
        pkgs.salt
      ]
      ++ lib.optionals pkgs.stdenv.isDarwin [
        pkgs.darwin.DarwinTools
      ];

    preBuild = ''
      export HOME=$(mktemp -d)
      export PATH=$PATH:/usr/sbin # cmd `system_profiler` for salt-call

      python -c 'from salt_lsp.cmds import dump_state_name_completions; dump_state_name_completions()'
    '';
  };

  pdm.lockfile = ./pdm.lock;
  pdm.pyproject = ./pyproject.toml;

  buildPythonPackage = {
    pythonImportsCheck = [
      "salt_lsp"
    ];
  };
}
