# lab

## Infrastructure

### TLS/HTTPS

bounca is running as my certificate authority. I mainly use the API to automatically issue certificates, for more info see the bash scripts in the [ca-scripts](ca-scripts) folder.

The compose file is in [compose/bounca.yml](compose/bounca.yml).

### Traefik

Traefik is used as a reverse proxy ~~and load balancer~~. It is configured to use the certificates issued by bounca. Ideally no container should expose any ports directly, but only through Traefik, this unfortunately is not always possible. For example, the `pihole` container exposes port 53 for DNS queries, which is not (easily) supported by Traefik.

The compose file is in [compose/traefik.yml](compose/traefik.yml).

### Docker/Portainer

Portainer is used to manage the Docker containers. I use to quickly check the logs of a container or to see the status of a container. I also use it to manage the volumes and networks.

The compose file is in [compose/portainer.yml](compose/portainer.yml).

### Pihole

Pihole is here and not in [Services](#services) because it's also used to resolve the hostnames of the containers.

Pihole is used as a DNS sinkhole. It is configured to use the DNS servers of my ISP and Cloudflare. I use it to block ads and trackers. It is also used to resolve the hostnames of the containers. For example, `pihole` can be reached at `pihole.home`.

In the future I want to run pihole behind cloudflared as an upstream for DoH, for now I am simply using 1.1.1.1 w/ regular DNS.

The compose file is in [compose/pihole.yml](compose/pihole.yml).

## Services

### Paperless

paperless-ngx is a document management system that allows you to scan, upload, and manage your documents. Really useful for keeping track of all the documents you have, especially if you live in a country like Germany where you are effectively drowned in paper.
Used with the [WebDAV](#webdav) container, so I can scan directly to it from my phone.

The compose file is in [compose/paperless.yml](compose/paperless.yml).

### Tailscale

I use Tailscale to access my home network from outside. It is configured to use pihole as the DNS server for my home subnet. This allows me to access the containers by their hostnames. The daemon is also running as an exit node, so I can have my residential IP address when I am not home. 

I mainly use it to access Paperless on the go when I need to reference a document.

The compose file for the daemon is in [compose/tailscale.yml](compose/tailscale.yml).

### WebDAV

WebDAV is used to scan documents directly to paperless. I use it with the [Genius Scan](https://thegrizzlylabs.com/genius-scan/) app on my phone.

The compose file is in [compose/webdav.yml](compose/webdav.yml).

### Home Assistant

I technically also 'use' Home Assistant, but I don't really use it. I have a few automations set up, but I don't really use it for anything else. I mainly use it to control my lights and heating. Most of my devices are still running over Google (shame on me!).

The compose file is in [compose/homeassistant.yml](compose/homeassistant.yml).

## Caveats

Because of how traefik is set up (only allowing traefik over domain names) in case of failure of the pihole or traefik container, I will not be able to access any web service running in the containers. I am unsure of how to solve this. 
(I could VPN into my network and try to fix it from my phone but that seems like a hassle)