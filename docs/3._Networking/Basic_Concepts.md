# Basic Concepts

## Introduction

There are 2 supported networking types: so called `external` network type and the `internal` network type.
In both cases we use VM's `TAP` interface connected to the `bridge`, but the difference is that `external` network connects to an external bridge, which is directly connected to an outer network in your homelab or production.
`internal` network on the other hand, is an empty bridge that only exists within the `Hoster` node itself.

It has proven itself to be very useful on the bare metal cloud servers (think Hetzner bare-metal), as it provides a simple way to implement NAT, firewalling and other things required in such a environment.
`internal` network also uses our own implementation of the DNS resolver, so that all local VMs can be resolved by their name from other VMs or a host itself.

## Using the `external` network

On every new VM deployment, `Hoster` will automatically pick an IP address from the pool specified in the `network_config.json` file, which usually looks like so (take note of the `range_start` and `range_end` options):

```json
[
    {
        "network_name": "internal",
        "network_gateway": "10.0.105.254",
        "network_subnet": "10.0.105.0/24",
        "network_range_start": "10.0.105.10",
        "network_range_end": "10.0.105.200",
        "bridge_interface": "None",
        "apply_bridge_address": true,
        "comment": "Internal Network"
    }
]
```

Let's add an external network:

```json
[
    {
        "network_name": "internal",
        "network_gateway": "10.0.105.254",
        "network_subnet": "10.0.105.0/24",
        "network_range_start": "10.0.105.10",
        "network_range_end": "10.0.105.200",
        "bridge_interface": "None",
        "apply_bridge_address": true,
        "comment": "Internal Network"
    },
    {
        "network_name": "external",
        "network_gateway": "192.168.118.254",
        "network_subnet": "192.168.118.0/24",
        "network_range_start": "192.168.118.220",
        "network_range_end": "192.168.118.230",
        "bridge_interface": "em0",
        "apply_bridge_address": false,
        "comment": "External Network"
    }
]
```

Keep in mind that `Hoster` VMs don't support the DHCP (yet), so you'll have to manage the VM IP ranges from within your `Hoster` nodes.

Now simply execute `hoster init` and make sure you set `apply_bridge_address` directive to `false`.
Otherwise `init` command will try to set the bridge address to use whatever is in `network_gateway`, which will most likely become a conflict on your outer network, and might create a routing loop.

Now, let's deploy a new VM, and put it into this new external network:

```shell
hoster vm deploy --name awesomeVmName --network-name external --dns-server 1.1.1.1 --ip-address 192.168.118.200
```

Couple of notes:

- `--dns-server` is required here, because by default our internal DNS server is used. If that is something you want to avoid (in cases where you'd like to use your own DNS server, for example), then don't forget to include this flag during the deployment.
- `--ip-address` can be specified manually, should you have a need for it.
- `--network-name` must be the same as the `network_name` directive in your `network_config.json`.
- gateway and network mask will be automatically picked up from the `network_config.json`. Make sure you specify the correct information there.

Finally, let's allow this VM to communicate with other VMs and vice-versa: `vim /etc/pf.conf`:

```pf
### FIREWALL RULES ###
# Allow internal NAT networks to go out + examples #
# Keep these rules below this section

# PF supports DNS names, including the short definitions
# But it will only work, if you use our internal DNS server/resolver
pass in quick inet from { awesomeVmName } to { 192.168.118.0/24 }
pass in quick inet from { 192.168.118.0/24 } to { awesomeVmName }
```

Apply the `PF` settings:

```shell
pfctl -f /etc/pf.conf
```

> Note: As you can see the firewall is active even if you use the `external` network. Hoster was designed this way to prevent any unwanted VM access. Make sure you put in the firewall exceptions in case this VM has to communicate with other resources on your Hoster node, or on your external network.

In case you want to turn off the PF for a specific network interface, use this directive in the `pf.conf` (and don't forget to apply the settings):

```pf
set skip on { vm-external }
```

> Note: insert this PF directive below a record that looks like this: `set skip on lo0`. Otherwise it may not work, or the PF may refuse/fail to reload. As with any other firewall system: the order matters.
