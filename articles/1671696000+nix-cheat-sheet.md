# Nix Cheat Sheet

This document describes a few useful Nix functionalities that you’ll want to use
often.

Note that only use this document to get the gist of things; it is not meant to
be a detailed explanation. As usual, heed for the `man` pages for more
information. It is also written with the intention that you're using Nix within
a non-NixOS distribution.

The Nix tool provides several useful functionalities. Below are some of the common ones that you’ll want to know.


## Nix Search

Nix provides a command, `nix search`, to search the entire Nixpkgs package repository. For example:


```
## Find a package that contains "Firefox" in its name or description.
$ nix search firefox
```


This will give you various results with names such as `nixos.firefox` or `nixpkgs.firefox`, which will be useful for later Nix invocations.


## Nix-env

Nix also provides a command, `nix-env`, that behaves like Ubuntu’s `apt`, where packages can be globally installed. By default,** <code>nix-env</code> installs things into the user scope</strong>.

A few examples of the command are:


```
## Install Firefox.
$ nix-env -iA nixpkgs.firefox # or
$ nix-env -iA nixos.firefox
## Uninstall Firefox.
$ nix-env --uninstall nixpkgs.firefox # or nixos.firefox
```


**Note:** Certain things are best installed using the system’s package manager (`apt` for Ubuntu/Pop!_OS). This is because Nix uses clever tricks to allow the system to contain multiple instances of the same thing while being completely isolated, but not all applications can work with that. Things that should be installed using the system’s PM include fonts, themes and GUI applications.

**Note:** Nix-env is actually not the advised way to use Nix, Ideally, you’d want to use something more declarative like [Home Manager](https://github.com/nix-community/home-manager), as it will heavily aid you in maintaining your home environment while not letting you accumulate packages and forget about them.


## Nix-store

Some commands that are potentially helpful in certain niche use-cases:

- To optimize the Nix store, run `nix-store --optimise`.
- To find out why a derivation path is being kept around, use `nix-store --query --roots <path>`.

## Nix Shell

The Nix shell is used to initialize a shell containing all the dependencies needed for development. Note that **it is incapable of running services**; see [nixos-shell (VM version)](https://github.com/Mic92/nixos-shell) or [nixos-shell (container version)](https://github.com/chrisfarms/nixos-shell) for that. You can also use Docker with [Arion](https://docs.hercules-ci.com/arion/), which acts like Docker Compose but with Nix.

A basic Nix shell goes like this:


```
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
	name = "acmcsuf-shell";

	buildInputs = with pkgs; [
		nodejs
		# more things	
	];

	shellHook = ''
		PATH="$PWD/node_modules/.bin:$PATH"
		echo "You've entered the Nix shell!"
	'';
}
```


It is worth nothing that name, buildInputs and shellHook are all optional.

As a side note, doing `buildInputs = with pkgs; [ nodejs ]; `is the same as doing `buildInputs = [ pkgs.nodejs ];`. The former syntax is just cleaner.

You have to enter a Nix shell manually. To do so, run `nix-shell`. Nix shell will automatically find the shell.nix file in the working directory.

**Note:** It is advised to add shell.nix to your .git/info/exclude. Not everyone uses Nix, and we don’t want to clutter the repository with something only we use, unless you don’t care (like I don’t).


## Using with VSCode

VSCode has an extension called the [Nix Environment Selector](https://marketplace.visualstudio.com/items?itemName=arrterian.nix-env-selector) that allows it to use the Nix shell environment automatically. Otherwise, Nix tools will only be available within the terminal.

The README provides a plethora of examples, but to summarize, simply open the folder with the shell.nix file and it will ask if you want to use that file. Simply choose Yes.


## Making a Temporary Shell

You can make a temporary Nix shell with all the packages you need without having to create a file. To do so, run:


```
$ nix-shell -p '<nixpkgs>' package1 package2 …
```


For example, to make a shell with Deno, NodeJS and TypeScript, do:


```
$ nix-shell -p '<nixpkgs>' deno nodejs nodePackages.typescript
```


It is a good idea to make a shell alias for this:


```
$ cat ~/.bashrc
## …
alias nixsh="nix-shell -p '<nixpkgs>'"
```



## Overriding Nixpkgs

Nix (the package manager) uses Nixpkgs (the package repository) to contain all of its packages’ build instructions. These instructions are stored on the [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs) GitHub repository. System and package updates are handled by synchronizing a copy of the Git repository with a certain commit in upstream. Currently, [nixos-22.05](https://github.com/nixos/nixpkgs/tree/nixos-22.05) and [nixos-unstable](https://github.com/nixos/nixpkgs/tree/nixos-unstable) are the two common branches:



* nixos-22.05 contains stable (but slightly outdated) packages.
* nixos-unstable contains the latest packages, some of which may be unstable (hence the name.

In some cases, you may wish to use a newer or older versions of particular packages. For example, if you wish to use a newer version of NodeJS, you may pick the latest commit from the nixos-unstable branch, as it’s more likely to have a much newer version of NodeJS. Nix lets you easily do this within its shell.

Assuming you already have a config, modify your shell.nix file like so:


```
{ systemPkgs ? import <nixpkgs> {} }:

let pkgs = import (systemPkgs.fetchFromGitHub {
	owner  = "NixOS";
	repo   = "nixpkgs";
	rev    = "bcc6842";
	sha256 = "${systemPkgs.lib.fakeSha256}";
}) {};

in pkgs.mkShell {} # …
```


Initially, with the original shell.nix, you're telling Nix to use whatever version of Nixpkgs is available on the system, which is `&lt;nixpkgs>`. This is not always reliable; some systems can (and often do) have wildly different Nixpkgs versions. As such, we're replacing our `pkgs` variable with one that we import directly from GitHub using the fixed commit `bcc6842` (which is described in `rev`).

When running this new file, Nix will error out with a hash mismatch:


```
building '/nix/store/1ayrf4h67bmrkxivlfwhqqzkd53zqifn-source.drv'...

trying https://github.com/NixOS/nixpkgs/archive/bcc6842.tar.gz
unpacking source archive /build/bcc6842.tar.gz
hash mismatch in fixed-output derivation '/nix/store/0jd2s12864n6qkgxviwqgg9glrw3mrk4-source':
  wanted: sha256:0000000000000000000000000000000000000000000000000000
  got:	sha256:0z7mc1l0qhimhsq9sxhf4a3w1i2rn9k75zqc8yj1i62aa6p7nq03
```


This is because of how Nix works: **everything that Nix creates has to have a known output hash**, because it has to be able to calculate the final output hash without having to execute everything. This allows for maximum cache efficiency as well as guaranteed reproducibility, but using it is more inconvenient.

To solve the error, simply copy the hash in the `got` field and replace the `${systemPkgs.lib.fakeSha256}` part. Using a fake SHA256 is how we get Nix to download and resolve new assets for its hash, since [nothing can have an all-zero hash, not even nothing](https://twitter.com/theregister/status/727596439484825600?lang=en).

Once replaced, the file will look something like this:


```
{ systemPkgs ? import <nixpkgs> {} }:

let pkgs = import (systemPkgs.fetchFromGitHub {
		owner  = "NixOS";
		repo   = "nixpkgs";
		rev    = "bcc6842";
		sha256 = "0z7mc1l0qhimhsq9sxhf4a3w1i2rn9k75zqc8yj1i62aa6p7nq03";
	}) {};

in pkgs.mkShell {} # …
```


You should now be all set.

**Note:** It is absolutely possible to mix-and-match multiple Nixpkgs within the same shell. For example, you can do `buildInputs = [ pkgs.nodejs systemPkgs.deno ];` which will fetch NodeJS from the newer Nixpkgs while not caring about Deno. You can also fetch multiple copies of Nixpkgs within the same shell if you wish to do so.


## Direnv

By combining Nix shell with Direnv, you can automatically execute the shell.nix file by only going into the directory. **This is a terminal integration; it does not concern with VSCode.**

To activate Nix shell with Direnv, make a .envrc file in the same directory as the shell.nix with the following content:


```
use nix
```


After that, Direnv will warn you that it has detected an .envrc file, although it won’t trust that. Run `direnv allow `for it to execute.

**Note:** It is also advised to add .envrc to .git/info/exclude for the same reason as above. It also clutters the repository for what is otherwise a very minor feature.
