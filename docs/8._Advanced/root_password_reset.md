# Reset `root` password on FreeBSD

Sometimes you may get into a situation in which you lose the access to your server (due to a lost `root` password, or a special character you simply can't type in the physical console).

Single user mode would not help you here, because in the latest FreeBSD releases it's protected by a `root` password by default (unless you've changed this default setting beforehand).

## Boot from the Live ISO or a Live USB

## Pick the `shell` option

## Import and mount your ZFS pool

```shell
mkdir /tmp/zfs
```

```shell
zpool import -f -R /tmp/zfs zroot
```

## Mount `/` dataset

```shell
mount -t zfs zroot/ROOT/default /mnt
```

## Use `chroot` to reset the password

```shell
chroot /mnt
```

```shell
passwd
```

```shell
exit
```

## Unmount the `/` dataset

```shell
umount /mnt
```

## Export the ZFS pool

```shell
zpool export zroot
```

## Reboot the system

```shell
reboot
```
