{
  description = "A cheap & continously rebased fork of nixpkgs.lib";

  outputs =
    { self }:
    let
      lib = import ./lib;

      mkStrOptionAsAttr =
        { lib, name }:
        {
          options.${name} = lib.mkOption { type = lib.types.str; };
        };

      optionABC = (
        { lib, ... }:
        {
          _file = "./optionABC.nix";
          options.abc = lib.mkOption {
            default = { };
            type = lib.types.submodule (
              { lib, ... }:
              {
                options.def = lib.mkOption {
                  default = { };
                  type = lib.types.submodule (
                    { lib, ... }:
                    mkStrOptionAsAttr {
                      inherit lib;
                      name = "ghi";
                    }
                  );
                };
              }
            );
          };
        }
      );

      # find something better
      slice =
        list: start: end:
        map (i: builtins.elemAt list i) (lib.range start (end - 1));

      fileSection =
        { file, line }:
        let
          f = builtins.readFile file;
          splitFile = lib.splitString "\n" f;
          start = if line - 6 < 0 then 0 else line - 6;
          end = if line + 6 > builtins.length splitFile then builtins.length else line + 6;
          splitFileSection = map (i: builtins.elemAt splitFile i) (lib.range start end);
        in
        lib.concatStringsSep "\n" splitFileSection;

      moduleErrorAttr =
        (lib.evalModules {
          modules = [
            optionABC
            {
              _file = "abcConfig1.nix";
              abc.def.ghi = 2; # should be string
            }
          ];
        }).config.abc.def.ghi;

      parseMergeDefinitionError =
        {
          __error ? "",
          opt,
          defs ? [ ],
        }:
        ({
          inherit __error;

          optionLocExcerpts = map (p: fileSection { inherit (p) file line; }) opt.declarationPositions;
        });
    in
    {
      inherit lib;
      cfg = moduleErrorAttr;
      test = parseMergeDefinitionError moduleErrorAttr;
    };
}
