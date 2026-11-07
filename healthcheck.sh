#!/bin/sh
# Healthy when the Docker API answers /_ping through the TCP port,
# i.e. the listener and the Docker socket both work.
set -eu

printf 'GET /_ping HTTP/1.0\r\nHost: localhost\r\n\r\n' |
  socat -t 5 - "TCP:127.0.0.1:${SOCAT_PORT:-2375}" |
  grep -q '^OK'
