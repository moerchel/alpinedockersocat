# alpinedockersocat

Small [Alpine](https://alpinelinux.org) based image that forwards a TCP port to the Docker socket with [socat](http://www.dest-unreach.org/socat/). Tools that only speak the Docker API over TCP can use it to reach the Docker daemon of the host.

Inspired by [binlab/docker-socat](https://github.com/binlab/docker-socat).

This image is available for the following architectures:

* amd64
* arm64
* armv7

## Security warning

The forwarded port gives **full, unauthenticated access to the Docker API**, without encryption. Anybody who can reach it can start privileged containers and therefore has root access to the host. Mounting the socket read-only (`:ro`) doesn't change that.

* Don't publish the port on a public interface.
* Prefer no published port at all and reach the container over an internal Docker network (see [docker compose](#docker-compose)).
* If the port must be published, bind it to `127.0.0.1` or a trusted interface, e.g. `-p 127.0.0.1:2375:2375`. A plain `-p 2375:2375` listens on all interfaces of the host.

## Available image tags

Images are published on [GitHub Container Registry](https://github.com/moerchel/alpinedockersocat/pkgs/container/alpinedockersocat):

* _latest_ / _main_: the newest release.
* _YYYYMMDD_: a specific [release](https://github.com/moerchel/alpinedockersocat/releases), e.g. `20261107`. Further releases on the same day are numbered `20261107.1`, `20261107.2`, …
* _sha-xxxxxxx_: the image built from a specific commit.

The image is always based on the newest Alpine release (`alpine:latest`) with all package updates installed. It is rebuilt every Monday, so new Alpine releases (e.g. 3.24 → 3.25) and security fixes are picked up automatically. Before an image is published, a smoke test checks that the Docker API is reachable through the port and the health check passes.

Releases are created automatically:

* for every change of the image on the `main` branch (changes to documentation only don't create a release),
* by the weekly rebuild every Monday, if Alpine provides updated packages or a new release. The release notes list the updated packages. Without updates no new image and no release is published.

Old images are removed weekly from the registry: untagged images (old builds) and `sha-*` tags older than 30 days. Release images, _latest_ and _main_ are kept.

Every image is scanned with [Trivy](https://github.com/aquasecurity/trivy) before it is published. Builds with fixable HIGH or CRITICAL vulnerabilities are not published, all findings are listed in the repository's [Security tab](https://github.com/moerchel/alpinedockersocat/security/code-scanning).

## Build instructions

Clone this repo and then:

    cd alpinedockersocat
    docker build -t alpinedockersocat .

Or pull the prebuilt image:

    docker pull ghcr.io/moerchel/alpinedockersocat:latest

## How to run it

The Docker socket of the host must be mounted to `/var/run/docker.sock`:

    docker run -d --name dockersocat --restart unless-stopped \
           -v /var/run/docker.sock:/var/run/docker.sock \
           -p 127.0.0.1:2375:2375 \
           ghcr.io/moerchel/alpinedockersocat:latest

Test it from the host:

    curl http://127.0.0.1:2375/_ping
    DOCKER_HOST=tcp://127.0.0.1:2375 docker ps

### Options

| Variable | Default | Description |
|---|---|---|
| `SOCAT_PORT` | `2375` | TCP port inside the container. When you change it, change the port mapping as well. |
| `SOCAT_DEBUG` | `no` | `yes` logs every accepted connection with the client address and port (`docker logs dockersocat`). |

The container stops with an error if `/var/run/docker.sock` isn't mounted or an option has an invalid value.

With `SOCAT_DEBUG=yes` every connection is logged as one line, errors and warnings of socat are logged as well:

    2026/11/07 11:33:15 socat[1] N accepting connection from AF=2 172.19.0.4:37666 on AF=2 172.19.0.3:2375

Connections from outside the Docker host show the address of the client, connections from the host itself through a published port show the gateway address of the Docker network (e.g. `172.17.0.1`). The connections of the health check (from `127.0.0.1` inside the container) are not logged.

### Health check

The image has a health check that requests `/_ping` from the Docker API through the TCP port, so it fails if either the listener or the Docker socket doesn't work. `docker ps` shows the state as `healthy` or `unhealthy`.

### Own socat arguments

Arguments given to the container are passed to socat unchanged, e.g. to listen on another socket:

    docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 127.0.0.1:2375:2375 \
           ghcr.io/moerchel/alpinedockersocat:latest \
           -d -d TCP-LISTEN:2375,reuseaddr,fork UNIX-CLIENT:/var/run/docker.sock

The health check uses `SOCAT_PORT`. If socat listens on another port, set `SOCAT_PORT` to it or disable the health check with `--no-healthcheck`.

### docker compose

Without a published port only containers in the same network can reach the Docker API, as `tcp://dockersocat:2375`:

```yaml
services:
  dockersocat:
    image: ghcr.io/moerchel/alpinedockersocat:latest
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - docker-api

  app:
    image: your/app
    environment:
      DOCKER_HOST: tcp://dockersocat:2375
    networks:
      - docker-api

networks:
  docker-api:
    internal: true
```

`internal: true` keeps the network without access to the outside. Remove it if `app` needs internet access, and attach `app` to a second network for that instead.

To reach the API from the host, publish the port on localhost only:

```yaml
    ports:
      - '127.0.0.1:2375:2375'
```

## License

[MIT](LICENSE)
