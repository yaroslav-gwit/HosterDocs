# PCI and/or GPU passthrough

## Intro

> Please, make sure you are familiar with the official documentation: `https://wiki.freebsd.org/bhyve/pci_passthru`

`bhyve` supports passing of host PCI devices to a virtual machine for its exclusive use of them.
With `Hoster` you can easily set up `bhyve` to use your node's PCI and/or GPU devices on the guest machine (if your hardware supports it).
Please, follow the steps below to achieve the `passthru` on your node.

## Hardware requirements

Please, make sure that:

- your CPU supports Intel IOMMU (a.k.a. VT-d)
- the PCI device in question (and it's driver) supports MSI/MSI-x interrupts

Host VT-d support can be determined by searching for a DMAR table in the ACPI tables (at least one record must be returned by `grep`):

```shell
acpidump -t | grep DMAR
```

PCI card MSI/MSI-x support can be determined in 2 steps.
First run the below, in order to find the device ID for the device you are interested in:

```shell
pciconf -lv
```

Example output:

```text
vgapci0@pci0:0:2:0: class=0x030000 rev=0x06 hdr=0x00 vendor=0x8086 device=0x1912 subvendor=0x1734 subdevice=0x121c
    vendor     = 'Intel Corporation'
    device     = 'HD Graphics 530'
    class      = display
    subclass   = VGA
xhci0@pci0:0:20:0:  class=0x0c0330 rev=0x31 hdr=0x00 vendor=0x8086 device=0xa12f subvendor=0x1734 subdevice=0x121d
    vendor     = 'Intel Corporation'
    device     = '100 Series/C230 Series Chipset Family USB 3.0 xHCI Controller'
    class      = serial bus
    subclass   = USB
```

In my particular case, I want to passthrough `vgapci0`.
To check if it's supported by the FreeBSD/bhyve, execute the below (at least 1 line must be returned):

```shell
pciconf -lc vgapci0 | grep MSI
```

Example input/output:

```text
# pciconf -lc vgapci0 | grep MSI
    cap 05[ac] = MSI supports 1 message
```

As you can see my device is indeed supported to be "passed through", but your milage may vary.

## Blacklist the devices in question

Blacklisting PCI devices on the host system is done to prevent the host operating system from automatically claiming and initializing specific PCI devices.
By blacklisting these devices, you reserve them for passthrough to virtual machines (VMs), allowing the VMs to have exclusive control and direct access to the hardware.

Run this to find the devices you want to `passthru`:

```shell
pciconf -lvc 
```

Example output:

```text
vgapci0@pci0:0:2:0: class=0x030000 rev=0x06 hdr=0x00 vendor=0x8086 device=0x1912 subvendor=0x1734 subdevice=0x121c
    vendor     = 'Intel Corporation'
    device     = 'HD Graphics 530'
    class      = display
    subclass   = VGA
    cap 09[40] = vendor (length 12) Intel cap 0 version 1
    cap 10[70] = PCI-Express 2 root endpoint max data 128(128) FLR
                 max read 128
    cap 05[ac] = MSI supports 1 message 
    cap 01[d0] = powerspec 2  supports D0 D3  current D0
    ecap 001b[100] = Process Address Space ID 1
    ecap 000f[200] = ATS 1
    ecap 0013[300] = Page Page Request 1
xhci0@pci0:0:20:0:  class=0x0c0330 rev=0x31 hdr=0x00 vendor=0x8086 device=0xa12f subvendor=0x1734 subdevice=0x121d
    vendor     = 'Intel Corporation'
    device     = '100 Series/C230 Series Chipset Family USB 3.0 xHCI Controller'
    class      = serial bus
    subclass   = USB
    cap 01[70] = powerspec 2  supports D0 D3  current D0
    cap 05[80] = MSI supports 8 messages, 64 bit enabled with 1 message
```

Make sure the device you need has the `MSI` line in it's `pciconf` output.

Now you can add them to the `/boot/loader.conf` like so:

```shell
pptdevs="0/2/0 0/20/0"
```

## PCI Device name parsing

As you can see above, we've mentally parsed this PCI Device string:

```text
vgapci0@pci0:0:2:0:
```

into something `bhyve` can work with:

```text
"0/2/0"
```

Here is how you can do it too:

- start with `vgapci0@pci0:0:2:0:`
- drop the driver name `vgapci0@`, which leaves us with `pci0:0:2:0:`
- drop the `pci0:` part, because it's universal across all devices, which leaves us with `0:2:0:`
- then replace mid `:` separator with `/`, which leaves us with `0/2/0:`
- and finally drop the last symbol `:` to finalize our parsing
- now you have a string which can be used in `/boot/loader.conf`: `"0/2/0"`

## Add the required kernel modules to `loader.conf`

Please, keep in mind that for the `passthru` to work, you must load `bhyve` or more specifically `vmm` module before the kernel is fully loaded.
I usually keep the `vmm` module at the very top of the file, along with the blacklisted devices to avoid any driver conflicts.
So the beginning of my `/boot/loader.conf` file looks like so:

```shell
pptdevs="0/2/0 0/20/0"
vmm_load="YES"
# only add the line below for the AMD processors
hw.vmm.amdvi.enable=1
```

If you init/load `vmm` after the kernel has been loaded (for example via `kldload`), then `pptdevs` will not work.

Multiple devices can be added (space-separated) to the `pptdevs` entry (just like we did above).
The `pptdevs` entry supports up to 128 characters in the single record (more specifically a string within the `"` symbols, eg `"0/2/0 0/20/0"`).
Any additional entries must be added with a numbered `pptdevs[index]` like so:

```shell
pptdevs="2/0/0 1/2/6 4/9/0"
pptdevs2="123/5/0 123/8/0"
pptdevs3="200/2/0 200/3/0"
```

## Reboot the system

Once everything above is completed you must reboot your node to apply the changes.

## List the `passthru` devices you can use

After your node has been rebooted and `hoster` initialized you can start using the `passthru`.
`Hoster` has a convenient interface to show you all the devices you can work with:

```shell
hoster passthru list
```

Example output:

```text
╭─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│                                                             Bhyve Passthru Devices                                                              │
├────────────┬─────────────┬────────────────┬──────────────┬────────────────────┬──────────────────────────────────────────┬──────────────────────┤
│ PPT Device │ PCI ID Raw  │      Type      │ Bhyve PCI ID │       Vendor       │                  Model                   │        Status        │
├────────────┼─────────────┼────────────────┼──────────────┼────────────────────┼──────────────────────────────────────────┼──────────────────────┤
│ ppt0       │ pci0:1:0:0: │ display/VGA    │ 1/0/0        │ NVIDIA Corporation │ GP107GL Quadro P600                      │ In use by: test-vm-1 │
├────────────┼─────────────┼────────────────┼──────────────┼────────────────────┼──────────────────────────────────────────┼──────────────────────┤
│ ppt1       │ pci0:1:0:1: │ multimedia/HDA │ 1/0/1        │ NVIDIA Corporation │ GP107GL High Definition Audio Controller │ In use by: test-vm-1 │
╰────────────┴─────────────┴────────────────┴──────────────┴────────────────────┴──────────────────────────────────────────┴──────────────────────╯
```

Take a look at the `Status` column specifically as it will show you if the device is already in use by any particular VM.

## Use your PCI device in the VM

Just add this line to your VM config (PCI IDs are taken from the table output above):

```json
"passthru": [ "1/0/0", "1/0/1" ],
```

Which will result in this bhyve command being appended (major PCI IDs are calculated and grouped dynamically in this case):

```shell
-s 6:0,passthru,1/0/0 -s 6:1,passthru,1/0/1
```

This allows us to pass 1 device with multiple functions (`6:0` and `6:1` in our case), as stated in the `bhyve passthru` official docs:

```text
Caveats: multi-function devices are not always independent, and may have to be assigned to guests with the functions being the same.
An example is QLogic FC adapters, where function 0 is used for firmware loading, while the other functions are for port data transfer.
For these, the mappings of functions must be the same in the guest e.g.

   -s 7:0,passthru,4/0/0 -s 7:1,passthru,4/0/1 -s 7:2,passthru,4/0/2
```

You can also split the passed-through device with multiple functions into the multiple independent devices on the VM/guest side (official docs again):

```text
Intel network adapters *do not* have this issue and can be split out to different guest slots e.g. an Intel adapter at host 6/5/0 and with 2 functions could be setup in the guest as two separate devices at slot 3 and slot 8:

   -s 3:0,passthru,6/5/0   -s 8:0,passthru,6/5/1
```

To achieve this on `Hoster` simply append `-` (minus) to the device name, like so (minus prevents the device grouping by a major PCI lane ID, eg `1/0`):

```json
"passthru": [ "-1/0/0", "-1/0/1" ],
```

The above will result in this (`6:0` and `7:0` instead of `6:0` and `6:1` which we had earlier):

```shell
-s 6:0,passthru,1/0/0 -s 7:0,passthru,1/0/1
```

You might need to experiment with the device function grouping before the `passthru` becomes stable on the VM/Guest side.
Unfortunately there isn't much docs from vendors we can use, so experimentation is the only way for now.

We would be very happy to work together with those whom may be interested in this functionality to assist building a most common compatibility list by default in the future.
Your input would be appreciated.
