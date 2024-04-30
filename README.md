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

> If you are not in the **`dnsproxy-systemd`** git directory, you may run **`make -C dnsproxy-systemd`** if you have cloned into the current directory.

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

This is solved by setting the maximum buffer sizes to a high enough level.

It can be done by using `sysctl -w` or permanently by adding a new file to the `sysctl` directory.

### Linux

#### Temporarily

```shell
sudo sysctl -w net.core.wmem_max=7864320
sudo sysctl -w net.core.rmem_max=7864320
```

#### Permanently

```shell
sudo sh -c 'printf "# Maximum send buffer size\nnet.core.wmem_max=7864320\n# Maximum receive buffer size\nnet.core.rmem_max=7864320" > /etc/sysctl.d/10-max-buffer-size.conf'
```

### BSD

#### Temporarily

```shell
su -c 'sysctl -w kern.ipc.maxsockbuf=8441037'
```

#### Permanently

```shell
su -c 'printf "# Maximum socket buffer\nkern.ipc.maxsockbuf=8441037" > /etc/sysctl.kld.d/10-max-socket-buffer.conf'
```

[UDP Buffer Sizes · quic-go/quic-go Wiki](https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes)
