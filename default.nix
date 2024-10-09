{
  lib,
  config,
  dream2nix,
  ...
}: let
  python = config.deps.python;
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
        config.deps.pdm
        python
      ]
      ++ lib.optionals pkgs.stdenv.isDarwin [
        pkgs.darwin.DarwinTools
      ];
    preBuild = ''
      export HOME=$(mktemp -d)
      export PATH=$PATH:/usr/sbin # cmd `system_profiler` for salt-call

      pdm venv create -w venv
      pdm install --prod
      pdm run dump_state_name_completions
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
