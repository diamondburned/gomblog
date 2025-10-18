# silverblue and a btrfs swapfile

quick guide on having a swapfile inside a LUKS-encrypted btrfs partition on Fedora Silverblue.

## why should i care

if you need working hibernation (i actually didn't! but i preferred doing this anyway), then a random-encrypted swap is [out of the picture](https://wiki.archlinux.org/title/Dm-crypt/Swap_encryption#Without_suspend-to-disk_support).

if you're like me and forgot to put btrfs inside a LVM2 before putting in LUKS, then you also won't have the luxury of having an already-encrypted swap partition.

in that case, your only viable choice left without doing partition changes to btrfs is to create a swapfile.

## in a normal world...

creating a btrfs swapfile [on something like Arch](https://wiki.archlinux.org/title/Btrfs#Swap_file) would be pretty simple. the workflow kinda goes like this:

```sh
sudo btrfs subvolume create /swap
sudo btrfs filesystem mkswapfile ... /swap/swapfile
```

and then you edit `/etc/fstab`. all done!

**don't actually do this**. you will break your Silverblue install.

not many people document this either; i saw a single reddit thread and they showed like half the steps and just hand-waved the `fstab` part... well, that part was why i had to recover my system like 10 times on a live Linux USB.

## the Silverblue way

first, you still need a btrfs subvolume, but **it must be in /var**. in Silverblue, `/` is a "composefs":

```
composefs on / type overlay (ro,relatime,seclabel,lowerdir+=/run/ostree/.private/cfsroot-lower,datadir+=/sysroot/ostree/repo/objects,redirect_dir=on,metacopy=on)
```

figuring out how to modify `/` is a no-go therefore, and will probably give you a headache.

to do this, do:

```sh
sudo btrfs subvolume create /var/swap
```

then create the swapfile as usual, but in this subvolume:

```sh
sudo btrfs filesystem mkswapfile /var/swap/swapfile --size 32g -U time
```

then, edit `/etc/fstab` to add the new subvolume *and* the swapfile.

to do this, first make note of what the UUID of the root mount is. in my case, it's this line:

```
UUID=3d312850-544d-4a06-a493-5a03028ed061 /         btrfs subvol=root,x-systemd.device-timeout=0,ro,compress=zstd:1,discard=async 0 0
```

duplicate this line for the swap subvolume. something like this:

```
UUID=3d312850-544d-4a06-a493-5a03028ed061 /var/swap btrfs subvol=swap,x-systemd.device-timeout=0,nofail,nodatacow,nodatasum 0 0
```

then, add the swapfile mount:

```
/var/swap/swapfile none swap defaults,nofail 0 0
```

then, reload systemd:

```sh
sudo systemctl daemon-reload
```

THIS STEP IS INCREDIBLY IMPORTANT. you may not be able to boot to your current build or even previous builds without it.

as a last step, to validate that everything mounts fine, do:

```sh
sudo mount -a
sudo swapon -a
```

then validate your swapfile:

```sh
sudo swapon -s
```

then, reboot and pray!

## disclaimer

i'm writing this as a post-mortem kind of doc. i did not test this out on my machine, and a lot of these commands were on the live environment that i had to use to recover my machines, so they're unfortunately long gone.

if you're worried about breaking your setup, i recommend doing one big change at a time. for example, create the subvolume, add its entry to `fstab` with a `nofail` flag, reload then reboot. repeat for the swapfile.

if everything still breaks then, don't blame me. use a better distro like NixOS.

bye!