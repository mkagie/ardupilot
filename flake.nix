{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # TODO(mkagie) Need to package pydronecan
        pydronecan = with pkgs.python3Packages; buildPythonPackage rec {
          pname = "dronecan";
          version = "1.0.22";
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-+mMlGY7bFf8HZKke9ERjhf9ec2DNSzKavVYY1SCOGHc=";
          };
          propagatedBuildInputs = [ pymavlink setuptools ];
        };

        python = pkgs.python3.withPackages (p: with p; [
          ipython
          numpy
          future
          lxml
          pymavlink
          # mavproxy
          pexpect
          flake8
          requests
          monotonic
          # geocoder
          empy
          ptyprocess
          configparser
          click
          decorator
          pydronecan

          # Additionaly
          pygame
          intelhex
          matplotlib
          pyserial
          scipy
          pyyaml
        ]);
        sitl_pkgs = with pkgs; [
          libtool
          libxml2
          libxslt
          xterm
          csfml
          libjpeg
        ];
        arduplane = pkgs.stdenv.mkDerivation {
          name = "arduplane";
          src = ./ArduPlane;

          nativeBuildInputs = with pkgs; [ wafHook ];
          buildInputs = sitl_pkgs;
          propagatedBuildInputs = [ python ];

          # configurePhase = with pkgs; ''
          #   echo "Hello"
          #   ls
          #   ${waf}/bin/waf configure --board sitl
          # '';

          # buildPhase = with pkgs; ''
          #   ${waf}/bin/waf plane
          # '';

          # installPhase = with pkgs; ''
          #   mkdir $out
          #   DESTDIR=$out ${waf}/bin/waf install
          # '';
        };
      in
      {
        defaultPackage = arduplane;
        devShells = with pkgs; {
          default = mkShell {
            inputsFrom = [ arduplane ];
            # packages = [ waf ];
          };
        };
      }
    );
}
