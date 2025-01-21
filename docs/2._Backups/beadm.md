# Rolling back a bad OS update (boot environments)

## Brief introduction to boot environments

FreeBSD has a concept of `boot environments`.
A ZFS boot environment is a bootable clone of the datasets needed to boot the operating system.
Creating a boot environment before performing an upgrade provides a low-cost safeguard: if there is a problem with the update, the system can be rolled back to the point in time before the upgrade.

The FreeBSD boot loader was rewritten for 12.0 to add BE support. Additionally, the default ZFS layout in the FreeBSD installer understands BEs.

## Introduction to `beadm`

`beadm` is a small shell utility which you can easily install using the `pkg`:

```shell
pkg install beadm
```

`beadm` helps you manage your boot environments. Let's say you've had a bad system update and one of the OS or `Hoster` components has stopped working correctly.
That's where `beadm` comes in.
The FreeBSD is smart enough to automatically create a snapshot of the root filesystem during the `freebsd-update fetch install`, and to store it as a separate boot environment.

So far - so good, right? Well, not quite. It's a bit tedious to manage the boot environments by hand, so we need `beadm` to simplify it for us.

## Activate an old boot env

Let's activate our old boot environment (because we've realized that something went wrong).
Execute `beadm list` to show all boot environments that are available to us:

```log
# Example output
[root@hoster-0106 ~]# beadm list
BE                             Active Mountpoint  Space Created
default                        NR     /            5.9G 2023-08-09 19:07
13.2-RELEASE_2023-10-04_092508 -      -            1.1G 2023-10-04 09:25
```

To activate our previous working environment execute the below:

```shell
beadm activate 13.2-RELEASE_2023-10-04_092508
```

At this point simply reboot, and you'll be using the previous OS version when the system boots up.

## More reading

Want to know more? `Klara Systems` has a really nice and an in-depth article on a similar boot environment management tool `bectl`:

```text
https://klarasystems.com/articles/managing-boot-environments/
```
