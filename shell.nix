{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
	buildInputs = with pkgs; [
		cmark
		gomplate
		htmlq
		jq
		minify
		(pkgs.writeShellScriptBin "parallel-moreutils" ''${pkgs.moreutils}/bin/parallel "$@"'')
		(pkgs.writeShellScriptBin "serve" ''${pkgs.python3}/bin/python3 -m http.server'')
	];

	MIME_TYPES_PATH = "${pkgs.mime-types}/etc/mime.types";
	PROJECT_ROOT = "${builtins.toString ./.}";

	shellHook = ''
		PATH=${builtins.toString ./.}/tools:$PATH
	'';
}
