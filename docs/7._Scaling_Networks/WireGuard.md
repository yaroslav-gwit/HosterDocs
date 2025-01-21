# WireGuard

WireGuard is a lightweight and efficient VPN protocol designed for simplicity and performance.
It establishes secure point-to-point connections and operates with a minimal codebase, making it easy to implement and audit.
WireGuard utilizes state-of-the-art cryptography for privacy and security.
Its simplicity, speed, and security have contributed to its popularity for creating secure communication channels across networks.

## Install WireGuard

Please keep in mind that `wg` is included in the `RELEASE` version of FreeBSD (past `13.0` version), so you don't need to install or load the kernel module itself if you use the `RELEASE` (haven't tested other builds, but it may be included there too).
All you need is `wireguard-tools` to make it easier to configure `wg` interfaces.

Install `wireguard-tools` using `pkg`

```shell
pkg install wireguard-tools
```

## Configure WireGuard

On both servers:

`cd` into a `WireGuard` configuration directory, and create public/private key pair

```shell
cd /usr/local/etc/wireguard/
umask 077
wg genkey | tee private.key | wg pubkey > public.key
```

Create `wg0.conf` configuration file

On server 1:

```wireguard
[Interface]
PrivateKey = ${SERVER_1_PRIVATE_KEY}
Address = 172.16.0.1/24
 
[Peer]
PublicKey = ${SERVER_2_PUBLIC_KEY}
AllowedIPs = 172.16.0.2/32
Endpoint = ${SERVER_2_PUBLIC_IP}:${WG_PORT}
 
## Keep connection alive ##
PersistentKeepalive = 15
```

On server 2:

```wireguard
[Interface]
PrivateKey = ${SERVER_2_PRIVATE_KEY}
Address = 172.16.0.2/24
 
[Peer]
PublicKey = ${SERVER_1_PUBLIC_KEY}
AllowedIPs = 172.16.0.1/32
Endpoint = ${SERVER_1_PUBLIC_IP}:${WG_PORT}
 
## Keep connection alive ##
PersistentKeepalive = 15
```

## Start the WireGuard server

On both servers:

```shell
wg-quick up wg0
```

## Apply the Required `pf` Firewall Rules

Add a new line to your `pf.conf` similar to this one, on both servers (to allow full peer-to-peer communications):

```pf
pass in quick log (all) inet proto { tcp udp icmp } from 172.16.0.0/24 to any
```

## Advantages and Disadvantages of WireGuard

### Advantages of WireGuard

#### Simplicity and Efficiency

WireGuard is known for its simplicity, with a minimal codebase. This simplicity makes it easier to understand, implement, and audit compared to some other VPN protocols.

#### High Performance

WireGuard is designed to be fast and efficient, resulting in lower latency and higher throughput compared to many traditional VPN solutions. This makes it suitable for high-performance scenarios.

#### Quick Connection Establishment

WireGuard is built to establish connections quickly, reducing the time it takes for devices to establish secure communication channels. This is beneficial for real-time applications and scenarios requiring rapid connectivity.

#### Modern Cryptography

WireGuard is available for various operating systems, including FreeBSD, Linux, Windows, macOS, Android, and iOS, making it versatile and widely compatible.

#### Dynamic Routing

WireGuard supports dynamic routing, allowing for easy integration into complex network configurations.

### Disadvantages of WireGuard

#### Limited Adoption in Legacy Systems

While WireGuard is gaining popularity, it may not be as widely supported in legacy systems or devices that have not yet integrated WireGuard support.

#### Less Feature-Rich Than Some Alternatives

WireGuard intentionally focuses on simplicity, which means it may lack some of the advanced features found in more complex VPN solutions.

#### Interoperability Issues

Some network environments or firewalls may not be fully compatible with WireGuard, potentially leading to interoperability issues.

#### Limited Protocol Support

WireGuard focuses on IP-based protocols, which may limit its use in scenarios that require support for non-IP protocols.

#### The Lack of Logging

One aspect of WireGuard's design philosophy is its intentional lack of logging. WireGuard aims to keep its codebase and functionality minimal, and this includes minimizing logging to reduce complexity and potential security risks. While this design choice has some advantages, it also raises considerations related to troubleshooting, monitoring, and auditing.

### Summary

As with any technology, the choice to use WireGuard depends on the specific requirements of the use case, the existing infrastructure, and the preferences of the organization deploying it.
