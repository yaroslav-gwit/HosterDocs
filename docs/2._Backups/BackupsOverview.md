# Backups Overview

RAIDz is not a backup. Neither are mirrors, and neither is DRAID.
Many people look at redundant topologies — like conventional RAID5, or OpenZFS RAIDz2—and think "well, that’s backup sorted." This is an enormous mistake, and it will bite the person who makes it, probably much sooner than they expected.

Redundant topologies are important for two things in OpenZFS: improving system uptime and allowing the system to automatically heal (self-repair) corrupt data and metadata.  

Although this does allow the system to survive specific types of hardware failure (most notably, individual drive failures) it does not protect the system from common failure modes that proper backup methods should: catastrophic hardware failure, catastrophic environment failure, human user error, and human administrator error.

If your server catches on fire, RAIDz won’t save you. If a tornado destroys your facility, RAIDz won’t help. If a user deletes a file, RAIDz won’t bring it back. If an administrator destroys the entire pool, RAIDz absolutely won’t help you.

## VM snapshots (ZFS snapshots)

Snapshots are only a part of the good `Hoster` backup strategy.
OpenZFS snapshots are, frankly, amazing. They can be taken instantaneously, capture the entire contents of one or several datasets with atomic precision, and do not negatively impact system performance like LVM snapshots do.

By themselves, however, snapshots are still not a complete backup. Taking a snapshot can protect your system from human user error, and even user malice. A snapshot still cannot entirely protect your system from human administrator error, however, and it’s no protection whatsoever from administrator-level malice.

Snapshots also do not protect a system from catastrophic hardware or environmental failures — at least, locally stored snapshots don’t. But that’s where OpenZFS snapshot replication comes in, and `Hoster` makes it really easy to replicate your ZFS-backed VMs across the multiple nodes (more on it later, with real usage examples).

### Manual Snapshots

`Hoster` VM Snapshots are simply ZFS snapshots. They do not include VM memory, and as of now `Hoster` doesn't support snapshots that copy and store the VM memory. Snapshots feel instant (which they almost are) to the end user. VM does not need to paused or stopped to take a new snapshot or to remove the old one, but you will need to `stop` the VM first if you want to roll back to an earlier snapshot. You can also store as many snapshots as you want, so long you have the available storage to keep them around.

To take a new snapshot, execute the command below:

```shell
hoster snapshot new vmName
```

This will create a new snapshot of `custom` type, and will give it a name similar to this: `zroot/vm-encrypted/vmName@custom_2023-08-12_13-21-36`. Snapshot types are implemented purely in the snapshot names, and do not mean anything for the underlying ZFS storage - it will simply make it easier for you, whenever you need to rollback or replicate your VM.

You can list all snapshots present on any given system by executing:

```shell
hoster snapshot list-all

# Example output
╭─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│                                                      Hoster ZFS Snapshots                                                       │
├────┬──────────────┬─────────────────────────────────────────────────────────────────┬─────────────────────┬─────────────────────┤
│ #  │   VM Name    │                          Snapshot Name                          │ Snapshot Size Human │ Snapshot Size Bytes │
├────┼──────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────┼─────────────────────┤
│  1 │ test-vm-1    │ zroot/vm-encrypted/test-vm-1@daily_2023-08-12_13-33-55          │                  1M │             2068480 │
├────┼──────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────┼─────────────────────┤
│  2 │ test-vm-1    │ zroot/vm-encrypted/test-vm-1@custom_2023-08-12_14-04-21         │                  0K │                   0 │
├────┼──────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────┼─────────────────────┤
│  3 │ test-vm-1    │ zroot/vm-encrypted/test-vm-1@custom_2023-08-12_14-04-22         │                  0K │                   0 │
├────┼──────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────┼─────────────────────┤
│  4 │ test-vm-0105 │ zroot/vm-encrypted/test-vm-0105@hourly_2023-08-14_12-33-00      │                  2M │             2912256 │
├────┼──────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────┼─────────────────────┤
│  5 │ test-vm-0105 │ zroot/vm-encrypted/test-vm-0105@hourly_2023-08-14_13-33-00      │                  2M │             2621440 │
├────┼──────────────┼─────────────────────────────────────────────────────────────────┼─────────────────────┼─────────────────────┤
│  6 │ test-vm-0105 │ zroot/vm-encrypted/test-vm-0105@hourly_2023-08-14_14-33-00      │                  0K │                   0 │
╰────┴──────────────┴─────────────────────────────────────────────────────────────────┴─────────────────────┴─────────────────────╯
```

You can also list snapshots for a particular VM:

```shell
hoster snapshot list vmName
```

For more up-to-date documentation on available arguments and flags consult `hoster snapshot --help`, `hoster snapshot new --help`, or use `--help` with any other sub-command available.

### Automatic Snapshots on schedule (`cron` way)

Just execute the code block below, and it will make sure you have VM snapshots taken automatically every hour, day, week and month by adding a new recurring cron job. `yearly` snapshots are also available, and you can consider using them if there is enough storage to keep that much data on your server.

```shell
cat <<'EOF' | cat > /etc/cron.d/hoster_snapshots
# $FreeBSD$
#
SHELL=/bin/sh
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin

#== AUTOMATIC SNAPSHOTS ==#
33 * *  * *      root  /opt/hoster-core/hoster snapshot all  --stype  hourly   --keep 3
5  4 *  * *      root  /opt/hoster-core/hoster snapshot all  --stype  daily    --keep 5
5  5 *  * 3      root  /opt/hoster-core/hoster snapshot all  --stype  weekly   --keep 3
5  3 15 * *      root  /opt/hoster-core/hoster snapshot all  --stype  monthly  --keep 6

EOF
```

## Storage Replication

Using the ZFS replication, an administrator can not only preserve the local storage system’s state but replicate it to an entirely separate `Hoster` node.

The policies and procedures surrounding both replication itself, and the replication target, are what can extend OpenZFS snapshotting into a viable, full-service backup strategy. If the replication target is on a separate hardware, the system’s data is protected from catastrophic hardware failure. If the replication target is offsite, the system’s data is protected from catastrophic environmental failure.

Protecting the system from human administrator-level error or malice is, of course, trickier. In a sufficiently paranoid environment, the replication target can be turned off entirely, away from the production environment, and from any other security concerns. Such a system may only be powered-on on the specific schedule (once a week, for example) to receive the fresh replication data, and then immediately powered off again.

Another small trick - if you keep your VMs on the `vm-encrypted` dataset, it will boost your physical security too: even if someone manages to steal your offline copy machine, they would not be able to boot the VMs or to recover the VM data.

Before you start, here are some requirements:

- Access to TCP port 22 (or any other TCP port your SSH service is running on)
- Only push based replication is available, so you'll have to design your solution around that fact
- Key based auth must be available using `root` account from the source system to the destination system (only `root` user is supported for the replication to take place)

### Manual Replication

`Hoster` storage replication is based on good old ZFS snapshot replication, but with a bit of automation added to it.

To start using `Hoster` storage replication copy over your root public SSH key onto the node you want to replicate to:

```shell
ssh-copy-id -i /root/.ssh/id_rsa.pub root@endpointIpAddress
```

 > Or drop it in manually, if the password based auth is disabled for `root` user

Now make sure you can SSH as `root` into that remote system, using an SSH key.
 > We are not ignoring the SSH fingerprints in our replication command, so keep that in mind while replacing the servers but keeping the old server addresses.

```shell
ssh root@endpointIpAddress
```

The best practice is to run at least one replication job manually first, to confirm that everything is running smoothly (run it twice, to make sure you transfer all snapshots):

```shell
# this is not a typo, the initial job has to be executed twice

# initial replication job - transfers only 1st available snapshot
hoster vm replicate-all --endpoint endpointIpAddress

# incremental replication job - transfers the rest of the snapshots
hoster vm replicate-all --endpoint endpointIpAddress
```

 > At some point I might add in the logic, that will execute both of these from a single command, but for now I want to keep it in, so that `Hoster` users understand what ZFS does under the hood, and in what order.

### Automatic Replication (`cron` way)

#### Basic Setup

To enable automatic storage replication simply add `replicate-all` job to the list of cronjobs.
Edit the `/etc/cron.d/hoster_replication` file to replace the endpoint IP address and you are good to go (don't forget that you need to make sure the password-less root SSH access is enabled, same as with manual replication):

```shell
cat <<'EOF' | cat > /etc/cron.d/hoster_replication
# $FreeBSD$
#
SHELL=/bin/sh
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin

#== AUTOMATIC REPLICATION ==#
# Sleep is required to run the replication just a few seconds later after the scheduled time,
# in order to avoid conflicts with the other snapshot or replication jobs
# snapshot or replication will fail to execute if there is an active replication job taking place
50 * *  * *      root  sleep 10 && /opt/hoster-core/hoster vm replicate-all --endpoint endpointIpAddress

EOF
```

#### Advanced Setup

My own configurations usually consist of separate shell scripts that are executed via `cron` inside of a `tmux` session.
This way, if there are any issues - I can simply SSH into the server, run `tmux a` and check the latest output.
Also `/var/run/replication/ERROR_${REPLICATION_NAME}` is being checked by `node_exporter_custom`, and if it exists - Grafana or AlertManager will send a notification about the replication failure.

Create a new script, at any location you'd like, `/root/replication_to_hoster01.sh` in this particular case, that looks like this:

```shell
#!/usr/local/bin/bash

REPLICATION_NAME=to_hoster01
REPLICATION_ENDPOINT=10.5.199.85
REPLICATION_SPEED_LIMIT=90
REPLICATION_COMMAND="/opt/hoster-core/hoster vm replicate-all --endpoint ${REPLICATION_ENDPOINT} --speed-limit ${REPLICATION_SPEED_LIMIT} --script-name ${REPLICATION_NAME}"

/usr/local/bin/tmux new-session -d -s ${REPLICATION_NAME}
/usr/local/bin/tmux send-keys -t ${REPLICATION_NAME}:0 "${REPLICATION_COMMAND}" Enter
/usr/local/bin/tmux send-keys -t ${REPLICATION_NAME}:0 "if [ $? -lt 1 ]; then /usr/local/bin/tmux kill-session -t ${REPLICATION_NAME}; else touch /var/run/replication/ERROR_${REPLICATION_NAME}; fi" Enter
```

Then make it executable `chmod +x /root/replication_to_hoster01.sh`, and add it to the `/etc/cron.d/hoster_replication`:

```shell
# $FreeBSD$
#
SHELL=/bin/sh
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin

#== AUTOMATIC REPLICATION ==#
# Sleep is required to run the replication just a few seconds later after the scheduled time,
# in order to avoid conflicts with the other snapshot or replication jobs
# snapshot or replication will fail to execute if there is an active replication job taking place

*/5 * *  * *      root  sleep 3;  /root/replication_to_hoster01.sh

```

Or a single line to your `/etc/crontab`:

```shell
*/5 * *  * *      root  sleep 3;  /root/replication_to_hoster01.sh
```

## Restore the VM from backup

To restore the VM from backup you'll want to list all of the VM snapshots first:

```shell
hoster snapshot list vmName
```

And then roll back to the most recent working snapshot:

```shell
hoster snapshot rollback vmName zroot/vm-encrypted/vmName@hourly_2023-08-12_13-33-00 --force-stop --force-start
```

 > `--force-stop` and `--force-start` will stop the VM automatically, rollback, and start it back up, which minimizes the time your VM has to be offline. Please keep in mind, that it's a destructive operation: any newer snapshot will be destroyed.

## Start the VM on a new host

If your hoster node dies unexpectedly, it's not a problem, you'll be able to start VMs on one of the replication hosts.

- Option 1: `hoster change parent --vm vmName`

This option works well if your VMs were connected to the same external network. But if you need to reset the VM settings at the same time, because of SSH access, lost passwords, or whatever the case may be - use Option 2.

- Option 2: `hoster vm cireset vmName`

This option will reset most of the settings on the VM, making sure it's compatible with the new parent.
