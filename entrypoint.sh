#!/bin/sh
# Forwards TCP port SOCAT_PORT to the Docker socket.
# Arguments given to the container are passed to socat unchanged instead.
set -eu

if [ "$#" -gt 0 ]; then
  exec socat "$@"
fi

error() {
  echo "ERROR: $*" >&2
  exit 1
}

port=${SOCAT_PORT:-2375}
socket=/var/run/docker.sock

case $port in
  '' | *[!0-9]*) error "SOCAT_PORT must be a number, got '$port'" ;;
esac
if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
  error "SOCAT_PORT must be between 1 and 65535, got '$port'"
fi

if [ ! -S "$socket" ]; then
  error "$socket is not a socket, mount it with -v /var/run/docker.sock:/var/run/docker.sock"
fi

listen="TCP-LISTEN:$port,reuseaddr,fork"
target="UNIX-CLIENT:$socket"

case ${SOCAT_DEBUG:-no} in
  no)
    echo "Forwarding TCP port $port to $socket"
    exec socat "$listen" "$target"
    ;;
  yes) ;;
  *) error "SOCAT_DEBUG must be 'yes' or 'no', got '$SOCAT_DEBUG'" ;;
esac

# SOCAT_DEBUG=yes: socat logs about ten notice lines per connection. Keep one
# line per accepted connection (with the client address) plus all errors and
# warnings; the health check's connections from 127.0.0.1 are left out.
echo "Forwarding TCP port $port to $socket, logging connections"
fifo=$(mktemp -u /tmp/socat-log.XXXXXX)
mkfifo "$fifo"
awk '/ N accepting connection from / && !/ from AF=2 127\.0\.0\.1:/ || / [EFW] / { print; fflush() }' \
  < "$fifo" >&2 &
exec socat -d -d "$listen" "$target" 2> "$fifo"
