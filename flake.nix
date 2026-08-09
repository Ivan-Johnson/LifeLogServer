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

			lls = import ./derivation.nix { inherit pkgs; };
		in
		{
			packages.x86_64-linux.default = lls;

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

			nixos = {
				config = {
					# NOTE: LLS does have a `/etc/lifelogserver/server.cfg`
					# configuration file. At present (20240617), it is only used to
					# configure the secret key [1]. I don't have a secret manager
					# setup with NixOS, so I won't bother setting that file up with
					# NixOS.
					#
					# [1]: https://flask.palletsprojects.com/en/3.0.x/config/#SECRET_KEY

					environment.systemPackages = [ lls ];

					users.groups.lls = { };

					users.users.lls = {
						isSystemUser = true;
						description = "User for the lls server";
						group = "lls";
					};

					systemd.services."lifelog_server" = {
						description = "Lifelog server";
						wantedBy = [ "default.target" ];
						serviceConfig = {
							Type = "exec";
							ExecStart = "${lls}/bin/lifelogserver start";
							User = "lls";
							Group = "lls";
						};
					};
				};
			};
		};
}
