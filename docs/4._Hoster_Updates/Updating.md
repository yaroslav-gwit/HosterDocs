# Updating your installation

## Using the `RELEASE` version

> Note! Hoster is in a very active development at this stage, and it's guaranteed to have breaking changes. Every new GitHub release will include a detailed description, a changelog, and any steps you need to take as a system administrator in order to make your systems compatible with the latest version.

You'd want to keep your `Hoster` version up-to-date, which is exactly why I created `self_update_service` binary. You can execute it like so:

```shell
/opt/hoster-core/self_update_service
```

Please note that it's usually a good idea to run it before you initialize `Hoster` after a reboot. Otherwise `hoster` binary will most likely be updated, but `vm_supervisor` would not:

```txt
Could not replace vm_supervisor_service: open /opt/hoster-core/vm_supervisor_service: text file busy
```

This is the expected behavior as `vm_supervisor_service` binary might be busy, because it's tracking the VM's state and keeps them all running (cannot be replaced on the fly, while running).

## Using the `DEV` Version

It's really easy to switch to a dev version of Hoster if needed. Be it for testing the new features, patching the bug you have, or anything else you can think of.

### Steps to install the DEV version

- Make sure you have `git` installed

```shell
pkg install git
```

- Clone the repo into a convenient place (as root please, otherwise you'll face permission issues all around the place)

```shell
git clone https://github.com/yaroslav-gwit/HosterCore.git
```

- Install the latest available version of Go (FreeBSD packages include an up-to-date Go version)

```shell
pkg install go
```

- Stop all hoster related services, or simply reboot the node to avoid `text file is busy` file system locks

- After the reboot, and before you execute `hoster init`, `cd` into the folder with HosterCore and execute the DEV version installation script

```shell
bash install_dev_version.sh
```

That's pretty much it, you should have your dev version up-and-running now.

### Script description

The script itself is very simple too:

- Pull the latest changes from github
- Build all of the required binaries
- Place all of the binaries into /opt/hoster-core/
- Exit

### Replace only a specific binary

It's also possible to replace a single binary, if required. To do this, `cd` into the HosterCore git folder and pull the latest changes:

```shell
bash pull_changes.sh
```

Then execute a build process:

```shell
bash build.sh
```

Now you can simply pick a binary you wanted to replace, and `cp` it into the `/opt/hoster-core/` overwriting the old one, like so:

```shell
cp hoster /opt/hoster-core/
```

### Warning

Running a dev version of `hoster` is not recommended, as it may include some unfinished or debugging code that can break your system. Always test the dev version on a lab machine first, and only transfer fully tested and fully working binaries to your production nodes.
