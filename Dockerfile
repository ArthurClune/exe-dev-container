FROM ghcr.io/boldsoftware/exeuntu:latest

LABEL exe.dev/login-user="exedev"

ENV DEBIAN_FRONTEND=noninteractive
USER root

# Copy and set up init script (required for systemd)
COPY files/init /usr/local/bin/init
RUN chmod +x /usr/local/bin/init

CMD ["/usr/local/bin/init"]
