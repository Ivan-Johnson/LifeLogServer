let
	pkgs = import <nixpkgs> { };
	lls = import ./derivation.nix { inherit pkgs; };
in
pkgs.mkShell { packages = [ lls ]; }
