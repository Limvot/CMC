{ pkgs ? (import (builtins.fetchGit {
  # Descriptive name to make the store path easier to identify
  name = "nixos-unstable-2018-09-12";
  url = "https://github.com/nixos/nixpkgs-channels/";
  # Commit hash for nixos-unstable as of 2018-09-12
  # `git ls-remote https://github.com/nixos/nixpkgs-channels nixos-unstable`
  ref = "refs/heads/nixos-unstable";
  rev = "5717d9d2f7ca0662291910c52f1d7b95b568fec2";
}) {}) }:
let
  clj2nix = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "hlolli";
    repo = "clj2nix";
    rev = "de55ca72391bdadcdcbdf40337425d94e55162cb";
    sha256 = "0bsq0b0plh6957zy9gl2g6hq8nhjkln4sn9lgf3yqbwz8i1z5a4a";
  }) {};
  cljdeps = pkgs.callPackage ./deps.nix { };
  classp = cljdeps.makeClasspaths { };
  execName = "hello";
  #mainClass = "qif-edn.core";

  #manifest = pkgs.writeText "${execName}-MANIFEST.MF" ''
    #Manifest-Version: 1.0
    #Main-Class: ${mainClass}
  #'';
in pkgs.stdenv.mkDerivation {
  name = execName;

  nativeBuildInputs = [ clj2nix pkgs.jdk pkgs.makeWrapper pkgs.clojure pkgs.nix-bundle ];

  buildInputs = map (x: x.path) cljdeps.packages;

  src = ./src;

  #phases = [ "unpackPhase" "buildPhase" "installPhase" ];
  phases = [ "unpackPhase" "installPhase" ];

  #buildPhase = ''
    ##mkdir classes
    ##java -cp .:${classp} ${pkgs.clojure}.main -e "(compile '${mainClass})"
    ##clojure -cp .:${classp} -e "(compile '${mainClass})"
    ##jar cmf ${manifest} out.jar -C classes qif_edn
  #'';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/clojure
    cp hello.clj $out/share/clojure/hello.clj
    makeWrapper ${pkgs.jdk}/bin/java $out/bin/${execName} \
      --add-flags "-cp ${classp}:${pkgs.clojure}/libexec/* clojure.main $out/share/clojure/hello.clj"
  '';
}
