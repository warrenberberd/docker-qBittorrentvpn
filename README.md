[preview]: https://raw.githubusercontent.com/MarkusMcNugen/docker-templates/master/qbittorrentvpn/Screenshot.png "qBittorrent Preview"

# qBittorrent with WebUI and OpenVPN
Docker container which runs the latest headless qBittorrent client with WebUI while connecting to OpenVPN with iptables killswitch to prevent IP leakage when the tunnel goes down.

![alt text][preview]

## Docker Features
* Base: Alpine 3.7
* Always builds latest qBittorrent client
* Size: 287MB
* Selectively enable or disable OpenVPN support
* IP tables kill switch to prevent IP leaking when VPN connection fails
* Specify name servers to add to container
* Configure UID and GID for config files and downloads by qBittorrent

# Run container from Docker registry
The container is available from the Docker registry and this is the simplest way to get it.
To run the container use this command:

```
$ docker run --privileged  -d \
              -v /your/config/path/:/config \
              -v /your/downloads/path/:/downloads \
              -e "VPN_ENABLED=yes" \
              -e "LAN_NETWORK=192.168.1.0/24" \
              -e "NAME_SERVERS=8.8.8.8,8.8.4.4" \
              -e "PUID=99" \
              -e "PGID=100" \
              -p 8080:8080 \
              -p 8999:8999 \
              -p 8999:8999/udp \
              markusmcnugen/qbittorrentvpn
```

# Variables
## Environment Variables
| Variable | Required | Function | Example |
|----------|----------|----------|----------|
|`VPN_ENABLED`| Yes | Enable VPN? (yes\|no) Default:yes|`VPN_ENABLED=yes`|
|`LAN_NETWORK`| Yes | Local Network with CIDR notation |`LAN_NETWORK=192.168.1.0/24`|
|`NAME_SERVERS`| No | Comma delimited name servers |`NAME_SERVERS=8.8.8.8,8.8.4.4`|
|`PUID`| No | UID applied to config files and downloads |`PUID=99`|
|`PGID`| No | GID applied to config files and downloads |`PGID=100`|

## Volumes
| Volume | Required | Function | Example |
|----------|----------|----------|----------|
| `config` | Yes | qBittorrent and OpenVPN config files | `/your/config/path/:/config`|
| `downloads` | No | Default download path for torrents | `/your/downloads/path/:/downloads`|

## Ports
| Port | Proto | Required | Function | Example |
|----------|----------|----------|----------|----------|
| `8080` | TCP | Yes | qBittorrent WebUI | `8080:8080`|
| `8999` | TCP | Yes | qBittorrent listening port | `8999:8999`|
| `8999` | UDP | Yes | qBittorrent listening port | `8999:8999/udp`|

# Access the WebUI
Access http://IPADDRESS:8080 from a browser on the same network.

**Note:** qBittorrent throws a header mismatch error if trying to open the WebUI in unRAID with the WebUI link. Type https://IPADDRESS:PORT into a browser on the same network and it will work.

## Default Credentials
| Credential | Default Value |
|----------|----------|
|`WebUI Username`|admin |
|`WebUI Password`|adminadmin |

# How to use OpenVPN
The container will fail to boot if `VPN_ENABLED` is set to yes or empty and a .ovpn is not present in the /config/openvpn directory. Drop a .ovpn file from your VPN provider into /config/openvpn and start the container again. You may need to edit the ovpn configuration file to load your VPN credentials from a file by setting `auth-user-pass`.

**Note:** The script will use the first ovpn file it finds in the /config/openvpn directory. Adding multiple ovpn files will not start multiple VPN connections.

## Example auth-user-pass option
`auth-user-pass credentials.conf`

## Example credentials.conf
username<br>
password

## PUID/PGID
User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:

```
id <username>
```

# Issues
If you are having issues with this container please submit an issue on GitHub.
Please provide logs, docker version and other information that can simplify reproducing the issue.
Using the latest stable verison of Docker is always recommended. Support for older version is on a best-effort basis.

# Building the container yourself
To build this container, clone the repository and cd into it.

## Build it:
```
$ cd /repo/location/qbittorrentvpn
$ docker build -t qbittorrentvpn .
```
## Run it:
```
$ docker run --privileged  -d \
              -v /your/config/path/:/config \
              -v /your/downloads/path/:/downloads \
              -e "VPN_ENABLED=yes" \
              -e "LAN_NETWORK=192.168.1.0/24" \
              -e "NAME_SERVERS=8.8.8.8,8.8.4.4" \
              -e "PUID=99" \
              -e "PGID=100" \
              -p 8080:8080 \
              -p 8999:8999 \
              -p 8999:8999/udp \
              qbittorrentvpn
```

This will start a container as described in the "Run container from Docker registry" section.
