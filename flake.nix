{
	description = "Life Log Server";

	inputs.nixpkgs.url = "nixpkgs/nixos-26.05";

	outputs =
		{ self, nixpkgs }:
		let
			pkgs = import nixpkgs {
				system = "x86_64-linux";
				config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ ];
			};
		in
		{
			# TODO: fix my git hook. It's really dumb that I have to do this.
			packages.x86_64-linux.default = pkgs.hello;

			devShells.${pkgs.stdenv.hostPlatform.system}.default = pkgs.mkShell {
				buildInputs = with pkgs; [
					pkgs.coreutils
					pkgs.which
					pkgs.bash
					pkgs.git
					pkgs.nix
					pkgs.nixfmt
				];
				shellHook = "";
			};
		};
}
