{ rust }:

{
  projectRootFile = "flake.nix";

  programs = {
    just.enable = true;
    mdformat.enable = true;
    nixfmt.enable = true;
    rustfmt = {
      enable = true;
      edition = "2024";
    };
    shfmt.enable = true;
    toml-sort = {
      enable = true;
    };
    yamlfmt.enable = true;
  };

  settings.global.excludes = [
    "LICENSE"
    ".editorconfig"
  ];

  settings.formatter = {
    rustfmt.package = rust;
    toml-sort.options = [ "--no-sort-tables" ];
  };
}
