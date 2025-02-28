{ rust, edition }:

{
  projectRootFile = "flake.nix";

  programs = {
    just.enable = true;
    mdformat.enable = true;
    nixfmt.enable = true;
    rustfmt = {
      inherit edition;
      enable = true;
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
