# silverblue lessons

some lessons during my first few hours on Fedora Silverblue as a long-time Nix user.

## rpm-ostree tricks

When installing with `rpm-ostree install`, you will have to reboot your system to observe the changes. To bypass this, you may do:

```sh
rpm-ostree install --apply-live PACKAGES...
```

You might also assume that uninstalling is similar, something akin to `uninstall --apply-live`, and you'd be horribly wrong! When uninstalling, do this:

```sh
rpm-ostree uninstall PACKAGES...
sudo rpm-ostree apply-live --allow-replacement
```

The last command seems to apply all `rpm-ostree` changes, including ones with "replacements" (I guess we're replacing our uninstalling packages with nothing here?).

This trick presumably works for `install` too.

### tangent

The OSTree people have [this to write about Nix](https://ostreedev.github.io/ostree/related-projects/#nixos--nix):

> NixOS supports switching OS images on-the-fly, by maintaining both booted-system and current-system roots. It is not clear how well this approach works. OSTree currently requries a reboot to switch images.

As a long-time Nix user, this section is hilarious. Unsure if it's because they're speaking of Nix as if it's some weird, crazy, foreign species doing things unheard of (partially true), or if it's just them weaseling themselves out of actually implementing this.

By the way, it works! Nix does it, and it does it very well. It works. 

### advice

If you haven't noticed already, `rpm-ostree install` sucks. It sucks a lot more than `nix profile install`, which is already very much frowned upon.

If you find yourself needing development tools, strongly consider using Toolbox/Distrobox. Start with Nix Toolbox if you're a past Nix user like me, and it'll be a lot nicer. If you do need GUI development tools though, then I'm sorry. Maybe not do that?

If you find yourself needing GUI apps, just use Flatpak. Swallow your pride; it's fine. Maybe a bit slow. At least it's not lobotomized like `rpm-ostree install` is.

## nix tricks

DO NOT USE Toolbox. Toolbox's hostname issues are annoying. See [issue #210](https://github.com/containers/toolbox/pull/210) (this issue was replaced by 3 other issues before the last one got abandoned/open).

Instead, choose Distrobox, and create the Nix container with a different home than the host's. Here's what I have:

```sh
$ mkdir .distrobox
$ distrobox create \
	--image ghcr.io/thrix/nix-toolbox:42 \
	--hostname hackadoll3v2-dev \
	--name hackadoll3v2-dev \
	--home ~/.distrobox/hackadoll3v2-dev
```

By using a separate home directory, you're saving yourself from a range of headaches:

- Nix overriding Fedora's `.bashrc`, breaking its shell outside the container.
- Your projects get to live hidden within home, so slightly less clutter when browsing around.
- Just less `.nix-*` clutter in general, making it easier to reinstall if needed.

Note that I'm on Fedora 43 Beta. The `:42`  doesn't seem to matter.

This would probably have been a lot more painful and messy without the awesome work of [Nix Toolbox](https://thrix.github.io/nix-toolbox/) (even though I'm using Distrobox, which this officially supports).