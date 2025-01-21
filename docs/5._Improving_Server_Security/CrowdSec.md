# CrowdSec

CrowdSec Security Engine is an open-source and lightweight software that allows you to detect peers with malevolent behaviors and block them from accessing your systems at various levels (infrastructural, system, applicative).

To achieve this, the Security Engine reads logs from different sources (log files, streams, etc) to parse, normalize and enrich them before matching them to threats patterns called `scenarios`.

You can think of it as a modern alternative to `Fail2Ban`, except it also shares the IP addresses of malicious actors across the entire network of `CrowdSec` enabled nodes.
This approach allows you to contribute back to the community, while continuously receiving an updated list of offenders.

I strongly recommend implementing `CrowdSec` on any internet facing `Hoster` node.

## Install CrowdSec

> Some information has been taken from this official blog post (but it's a little outdated, so I had to modify few things): <https://docs.crowdsec.net/blog/crowdsec_firewall_freebsd/>.

In order to be able to block and drop traffic, you need to append this minimal /etc/pf.conf configuration in your pf rules:

```pf
# crowdsec table, leave at the top of the file, just under the private networks table
table <crowdsec-blacklists> persist
table <crowdsec6-blacklists> persist

# place right before the allow rules in the firewall section of the file
block drop in quick from <crowdsec-blacklists> to any
block drop in quick from <crowdsec6-blacklists> to any

# I also tend to block the egress traffic, so no internal resources can access CrowdSec offenders 
block drop in quick from any to <crowdsec-blacklists>
block drop in quick from any to <crowdsec6-blacklists>
```

Apply the rules and check config

```shell
pfctl -f /etc/pf.conf
pfctl -sr
service pf check
service pf status
```

Install the `CrowdSec` packages

```shell
pkg update
pkg install crowdsec crowdsec-firewall-bouncer
```

Copy the main sample config

```shell
cp /usr/local/etc/crowdsec/config.yaml.sample /usr/local/etc/crowdsec/config.yaml
```

Review the YAML settings file if you'd like, and introduce your own changes.

Enable `CrowdSec` in your `/etc/rc.conf` so it starts back up automatically after a reboot

```shell
crowdsec_enable="YES"
crowdsec_config="/usr/local/etc/crowdsec/config.yaml"
crowdsec_flags=" -info"
```

Start the service Crowdsec Agent

```shell
service crowdsec start
service crowdsec status
```

List your current machine Agent settings

```shell
crowdsec-cli machines list
```

Example output:

```shell
-------------------------------------------------------------------------------------------------------------
 NAME                                              IP ADDRESS  LAST UPDATE           STATUS  VERSION         
-------------------------------------------------------------------------------------------------------------
 7fb0531dc09a40d288299c8377d6cfe5nJtGyC7TFsUR3XYZ  127.0.0.1   2021-07-22T09:41:47Z  ✔️       v1.1.1-freebsd 
-------------------------------------------------------------------------------------------------------------
```

Configure your first bouncer. Start by copying the sample config.

```shell
cp /usr/local/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml.sample /usr/local/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
```

Add the new bouncer and it will generate the token for `<your_api_key>` to use

```shell
crowdsec-cli bouncers add freebsd-pf-bouncer
```

Edit the YAML settings in `/usr/local/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml`. Make sure the bouncer backend mode is pf (automatically set at installation time). `api_url` and `api_key` are mandatory to be set.

```shell
api_url: http://localhost:8080/
api_key: <your_api_key>
```

List your current bouncers config

```shell
crowdsec-cli bouncers list
```

Example output:

```shell
---------------------------------------------------------------------------------------------------------
 NAME                IP ADDRESS  VALID  LAST API PULL         TYPE                       VERSION         
---------------------------------------------------------------------------------------------------------
 freebsd-pf-bouncer  127.0.0.1   ✔️      2021-07-22T09:59:33Z  crowdsec-firewall-bouncer  v0.0.13-freebsd 
---------------------------------------------------------------------------------------------------------
```

Enable this bouncer in your `/etc/rc.conf`

```shell
crowdsec_firewall_enable="YES"
```

Start the service Crowdsec Firewall

```shell
service crowdsec_firewall start
service crowdsec_firewall status
```

Use the following scenarios, parsers and collections from the Hub:

```shell
crowdsec-cli scenarios install crowdsecurity/ssh-bf
crowdsec-cli parsers install crowdsecurity/sshd-logs
crowdsec-cli parsers install crowdsecurity/syslog-logs
crowdsec-cli collections install crowdsecurity/sshd
```

Restart the crowdsec agent

```shell
service crowdsec restart
```

You should now benefit from the Crowdsec signals from the community and your own and be protected against malevolent behavior.

## CrowdSec cheat sheet

List installed configurations

```shell
cscli hub list
```

Installing configurations

```shell
cscli <configuration_type> install <item>
```

`configuration_type` can be `collections`, `parsers`, `scenarios` or `postoverflows`.

Example of installing a new collection for `nginx`:

```shell
cscli collections install crowdsecurity/nginx
```

Upgrading configurations

```shell
cscli hub update
cscli hub upgrade
```

List active decisions

```shell
cscli decisions list
```

Add/Remove decisions

```shell
cscli decisions add -i 1.2.3.4
cscli decisions delete -i 1.2.3.4
```

List alerts

```shell
cscli alerts list
```

> Follow this link to checkout even more `CrowdSec` management related commands: <https://docs.crowdsec.net/docs/getting_started/crowdsec_tour/>.
