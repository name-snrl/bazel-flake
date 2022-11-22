{
  description = "Bazel flake";

  inputs = {
    nixpkgs.url = "nixpkgs/release-22.11";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    java.url = "github:timothyklim/jdk-flake";
    src = {
      url = "github:bazelbuild/bazel/7.0.0-pre.20221102.3";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, java, src }:
    let
      system = "x86_64-linux";
      sources = with builtins; (fromJSON (readFile ./flake.lock)).nodes;
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      jdk = java.packages.${system}.openjdk_19;
      bazel_5 = pkgs-unstable.bazel_5;
      bazel = import ./build.nix {
        inherit pkgs nixpkgs bazel_5 jdk src;
        version = sources.src.original.ref;
      };
      bazel-app = flake-utils.lib.mkApp { drv = bazel; };
      derivation = { inherit bazel; };
    in
    with pkgs; rec {
      packages.${system} = derivation // { default = bazel; };
      apps.${system}.bazel = bazel-app;
      defaultApp.${system} = bazel-app;
      legacyPackages.${system} = extend overlay;
      devShells.${system}.default = callPackage ./shell.nix {
        # inherit bazel src;
        inherit src;
        bazel = bazel_5;
      };
      nixosModules.default = {
        nixpkgs.overlays = [ overlays.default ];
      };
      overlays.default = final: prev: derivation;
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
