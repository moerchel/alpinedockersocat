# Security policy

## Supported versions

Only the newest image is supported: `latest` and the newest release tag.
Older release tags are not updated. The image is rebuilt every 3 days
with the newest Alpine release and its current packages.

## Reporting a vulnerability

Please don't open a public issue. Report it privately via
**Security → Report a vulnerability** in this repository.

## Scope

In scope: the Dockerfile, entrypoint.sh, healthcheck.sh and the GitHub
workflows of this repository.

Vulnerabilities in socat or Alpine itself should be reported upstream
(http://www.dest-unreach.org/socat/, https://security.alpinelinux.org/).
Their fixes reach this image with the next rebuild.
