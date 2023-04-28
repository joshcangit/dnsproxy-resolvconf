# dnsproxy-resolvconf
A systemd service for [AdguardTeam/dnsproxy](https://github.com/AdguardTeam/dnsproxy) to provide DNS.

This is for Linux systems installed with the [**`resolvconf`**](https://repology.org/project/resolvconf/) package to modify the `/etc/resolv.conf` file.

The **adguard-dnsproxy-setup.service** uses an argument of **`linux-amd64`** in its `ExecStart` line.

Refer to assets in [AdguardTeam/dnsproxy Releases](https://github.com/AdguardTeam/dnsproxy/releases) for other OS architectures.

> Examples:
>
> - `linux-386` for i386 / x86
> - `linux-arm64` for aarch64 / arm64
> - `linux-arm6` for armv6l / armhf

## Install

After cloning this repository, run the command below to download and start up this DNS proxy server.

```shell
make
```

Using `sudo` is optional since the Makefile already checks for admin access.

Admin access is need to be permitted to bind IP addresses for listening.

> If you want to run the exact targets, run **`make install start`**.

> If you are not in the **`dnsproxy-systemd`** git folder, you may run **`make -C dnsproxy-systemd`** if you have cloned into the current directory.

### Customization

The Makefile has 2 variables to customize, BINDIR and CONFDIR.

```shell
make BINDIR=/opt/adguard CONFDIR=/etc/adguard
```

If you change their values, be sure the chosen directory is _root-owned_.

Due to certain _file conflicts_, `/etc` and `/usr/sbin` are some of the directories not allowed.

## `dnsproxy.yml` file
Refer to the options in [Adguard/dnsproxy main.go](https://github.com/AdguardTeam/dnsproxy/blob/master/main.go) for yaml configuration.

The **`listen-addrs`** option is required.

Make sure **adguard-dnsproxy.service** is stopped when editing this option.

Make sure any IP addresses in this option are not already used on port 53.

Check for IP address on port 53 with `ss`, `netstat` or `lsof`.

```shell
sudo ss -tnlp | grep :53
```

```shell
sudo netstat -tnlp | grep :53
```

```shell
sudo lsof -Pni:53 -sTCP:LISTEN
```

## UDP Receive Buffer Size

Linux and BSD may encounter errors for any QUIC or UDP transfers, especially DNS over QUIC.

This is solved by setting the maximum buffer size to a high enough level.

It can be done by using `sysctl -w` or permanently to `/etc/sysctl.conf` as shown below.

### Linux

```shell
sudo sh -c 'echo "net.core.rmem_max=26214400" >> /etc/sysctl.conf'
```

### BSD

```shell
sudo sh -c 'echo "kern.ipc.maxsockbuf=30146560" >> /etc/sysctl.conf'
```

[UDP Receive Buffer Size · lucas-clemente/quic-go Wiki](https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size)
