- Not production ready!

# Docker container for a MaxScale database proxy in your Galera cluster
This is a small demo for running a MaxScale database proxy in your MariaDB Galera Cluster.
Docker hub : [bstaijen/mariadb-maxscale-for-galera-cluster](https://hub.docker.com/r/bstaijen/mariadb-maxscale-for-galera-cluster/)

## How does it work?
This project consists out of one docker image. The docker image depends on consul for service discovery. The demo uses [gliderlabs/registrator](https://github.com/gliderlabs/registrator) for its service registration. If set up the right way MaxScale will automatically connect and load balance between the MariaDB Galera instances.

## Requirements
- [gliderlabs/docker-consul](https://github.com/gliderlabs/docker-consul) - For MariaDB Server Discovery
- [gliderlabs/registrator](https://github.com/gliderlabs/registrator) - For Automatic Server Registration
- [mariadb-disover-tool](https://github.com/bstaijen/mariadb-discover-tool) - For querying Consul Registry

## Environment Arguments
- `CONSUL_HOST` - Link to consul instance. eg: `CONSUL_HOST=consul:8500`
- `GALERA_SERVICE_NAME` - Name of the galera services in consul. eg: `GALERA_SERVICE_NAME=galera-db`

## Usage
- TODO

## To Do List
- Testing / Debugging
- Write usages
- Implement healthchecks
- Monitoring
- Auto Fail Over?
- etc
- ?