# ZeroTier

ZeroTier is a software-defined networking platform that enables secure and direct communication between devices across the globe.
It creates a virtual LAN-like network, allowing devices to connect as if they were on the same local network.
ZeroTier employs end-to-end encryption for privacy and operates without the need for complex network configurations.
It is often used for remote work, multi-cloud connectivity, and building scalable and secure networks.

## Install ZeroTier using `pkg`

```shell
pkg install zerotier
```

Now enable the service, so it is automatically started during the system startup

```shell
service zerotier enable
service zerotier start
```

## Configure ZeroTier

Edit `local.conf` in order to stop `ZeroTier` from slowing down or crashing the whole network stack.
You can find out more here: <https://github.com/zerotier/ZeroTierOne/issues/779#issuecomment-767198156>, but the TLDR is:
the workaround blocks ZeroTier from routing ZeroTier packets over itself, which in it's turn prevents routing loops, and network buffer exhaustion.

```shell
vim /var/db/zerotier-one/local.conf
```

Add this content to the file:

```json
{
   "settings": {
       "interfacePrefixBlacklist": [
           "vm",
           "tun",
           "epair",
           "wg",
           "pf",
           "tap",
           "vxlan"
       ],
       "allowTcpFallbackRelay": false
   }
}
```

`"interfacePrefixBlacklist"` includes the interfaces (or their prefixes to be more precise) which ZeroTier will ignore and will not try to bind to.
But you can still use them for bridging and routing over the ZeroTier network.

## Start the service and connect to your `ZeroTier` network

Stop the service (just in case you had it running before)

```shell
service zerotier stop
```

Start the service (ZT will be using the config file above from now on)

```shell
service zerotier start
```

Check if ZeroTier is online:

```shell
zerotier-cli info
```

Join your ZeroTier network:

```shell
zerotier-cli join <network_id>
```

## Set the interface IP address

Sometimes ZeroTier can't pick up a network address.
In that case just set the address manually:

```shell
ifconfig <zerotier_interface> inet 192.168.100.30/24
```

## Downloads for other OSes

You can find ZeroTier client for other operating systems here:

```shell
https://download.zerotier.com/RELEASES/
```

## Advantages and disadvantages of ZeroTier

### Advantages

#### Ease of Use

ZeroTier is known for its simplicity and ease of use.
Setting up a virtual network is straightforward, and the platform provides a user-friendly experience for both individual users and organizations.

#### Cross-Platform Compatibility

ZeroTier supports a wide range of operating systems, including FreeBSD, Linux, Windows, macOS, Android, iOS, and others.
This cross-platform compatibility makes it versatile and accessible across different devices.

#### Global Connectivity

ZeroTier allows devices to connect seamlessly across the globe, creating virtual LAN-like networks regardless of physical location.
This is particularly beneficial for remote work scenarios and distributed teams.

#### Secure Network Communications

ZeroTier employs end-to-end encryption to secure communication channels between connected devices.
This ensures data privacy and security, making it suitable for sensitive information and communications.

#### Scalability

ZeroTier is designed to scale efficiently, allowing for the easy addition of new devices to a network.
This scalability makes it suitable for a variety of use cases, from small-scale setups to large distributed networks.

#### Peer-to-Peer Architecture

ZeroTier operates on a peer-to-peer architecture, enabling direct communication between devices without the need for a central server.
This decentralized approach enhances efficiency and can contribute to better performance.

#### Network Virtualization

ZeroTier provides network virtualization capabilities, allowing users to create isolated and secure networks over the internet.
This is useful for scenarios where traditional physical networks are not practical.

#### Decentralized Route Management

ZeroTier employs a distributed and decentralized approach to route management, utilizing a peer-to-peer architecture.
In a ZeroTier network, each device (or "node") participates in the routing decisions, and there isn't a central router or gateway responsible for managing all traffic.
Instead, route information is distributed across the connected nodes.

### Disadvantages

#### Centralized Controllers

While ZeroTier operates on a peer-to-peer model, it does rely on central controllers for network configuration and management.
In certain scenarios, the dependence on centralized controllers may be a consideration.

#### Subscription Tiers for Advanced Features

Some advanced features of ZeroTier, such as specific network rules and management capabilities, may be available under subscription plans.
Users or organizations requiring these features may need to subscribe to a paid plan.

#### Limited Control Over Infrastructure

ZeroTier abstracts much of the networking infrastructure, which can be advantageous for simplicity but may limit the level of control and customization available to users who require more granular control over network configurations.

#### Potential Dependency on External Services

ZeroTier's functionality relies on external servers for initial setup and network controller services.
If there are issues with these external services, it could impact the ability to create or manage networks.

#### Learning Curve for Advanced Features

While basic usage of ZeroTier is straightforward, users looking to leverage advanced features may encounter a learning curve.
Understanding and configuring more intricate network settings may require additional effort.

#### Dependency on Internet Connectivity

ZeroTier relies on internet connectivity for devices to communicate across networks.
In scenarios where devices are offline or have limited internet access, the functionality may be impacted.

#### Outdated Packages

Official FreeBSD packages (from the RELEASE branch) may be few versions behind the upstream.
Building from source is not very straight forward on FreeBSD due to the GNU based compiler dependencies.

#### Stability Concerns

ZeroTier service on FreeBSD requires you to keep track of your local network interfaces (and blacklisting them), in order to support a stable connection and to avoid the routing loops.

### Summary

As with any networking solution, the suitability of ZeroTier depends on the specific requirements of the use case, the desired level of control, and the trade-offs an organization or individual is willing to make. Careful consideration of the advantages and disadvantages will help determine if ZeroTier is the right solution for a particular scenario.
