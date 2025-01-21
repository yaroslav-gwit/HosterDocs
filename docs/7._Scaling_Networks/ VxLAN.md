# VxLAN

> This page is still a work in progress.

## Clean-up the old VxLAN config

If you have an old VxLAN config still in place, execute the below on both Nodes:

```shell
ifconfig vxlan0 destroy
route delete 0.0.0.0/8
```

## Set-up the route and the interface

On Node 1:

```shell
route add -net 224/8 -interface zt80lm2s8e1am68
ifconfig vxlan create vxlanid 420 vxlanlocal 192.168.196.10 vxlangroup 224.0.0.1 vxlandev zt80lm2s8e1am68 inet 10.10.99.1/24 up
```

On Node 2:

```shell
route add -net 224/8 -interface zt80lm2s8e1am68
ifconfig vxlan create vxlanid 420 vxlanlocal 192.168.196.20 vxlangroup 224.0.0.1 vxlandev zt80lm2s8e1am68 inet 10.10.99.2/24 up
```

## Set an MTU (if required)

Default MTU for ZeroTier is 2800, so only apply the below if you've changed the default value (make the VxLAN MTU smaller than your interface MTU value by at least 50):

```shell
ifconfig vxlan0 mtu 1450
```
