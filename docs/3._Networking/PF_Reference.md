# PF Reference (firewall management)

`Hoster` uses FreeBSD's `PF` as a firewall of choice (which is enabled/enforced on every `hoster init` execution).
The `/etc/pf.conf` is the main configuration file for `pf`.

## NAT section

### Regular NAT rule

> `1.1.1.1` is not a `CloudFlare` server in this scenario - imagine it is our public IP address (simply easier to type)

```pf
rdr pass on { em0 } proto { tcp } from any to { 1.1.1.1 } port { 80 } -> { vmOrJailName } port 80  # HTTP redirection
```

### NAT reflection rule

We can simply clone the `NAT` rule above, but change the interface to our local one.
> Please keep in mind, that in the rare case where reflection doesn't work - use a TCP load balancer to forward or reflect the connection

```pf
rdr pass on { vm-internal } proto { tcp } from any to { 1.1.1.1 } port { 80 } -> { vmOrJailName } port 80  # HTTP local redirection
```

### Simplified NAT rules

To make your life easier, instead of the hardcoded IP addresses you can simply use an ethernet port name, like so:

```pf
rdr pass on { em0 } proto { tcp } from any to { em0 } port { 80 } -> { vmOrJailName } port 80  # HTTP redirection
```

The same goes for the reflection rule.

```pf
rdr pass on { vm-internal } proto { tcp } from any to { em0 } port { 80 } -> { vmOrJailName } port 80  # HTTP redirection
```

I always try to explicitly set the IP address for the NAT forwardings, but the usecase for this scenario is a dynamic IP address on a public interface.
It also works really well for the interfaces with a single IP address bound to them.

## Filter section

### VM subnets filter

```pf
pass in quick inet proto { tcp } from { vmOrJailName } to { 10.0.101.0/24 }
# or
pass in quick inet proto { tcp } from { vmOrJailName } to { vm-internal }

# from any to a specific VM
pass in quick inet proto { tcp udp } from any to { vmOrJailName } port { 1514 }
```

### Host filter

```pf
pass in proto { tcp } to port { 5900:5999 } keep state
pass in quick on { em0 } proto { tcp } to port { 19999 } keep state
```
