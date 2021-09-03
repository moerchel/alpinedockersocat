FROM alpine:latest

RUN apk add --no-cache socat

EXPOSE 2375

ENTRYPOINT ["socat"]
CMD ["TCP-LISTEN:2375,reuseaddr,fork", "UNIX-CLIENT:/var/run/docker.sock"]
