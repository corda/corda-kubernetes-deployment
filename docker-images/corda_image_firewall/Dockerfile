FROM azul/zulu-openjdk-alpine:8u192

RUN apk upgrade --update && \
    apk add --update --no-cache bash iputils nfs-utils nss curl netcat-openbsd lftp openssh-client openssh-server && \
    rm -rf /var/cache/apk/* && \
    # Add user to run the app && \
    addgroup corda && \
    adduser -G corda -D -s /bin/bash corda && \
    # Create /opt/corda directory && \
	mkdir -p /opt/corda/workspace

ADD --chown=corda:corda corda-firewall.jar /opt/corda/corda-firewall.jar
ADD --chown=corda:corda startFirewall.sh /opt/corda/startFirewall.sh

# Permissioning
RUN chown -R corda:corda /opt/corda
RUN dos2unix /opt/corda/startFirewall.sh /opt/corda/startFirewall.sh
RUN chmod +x /opt/corda/startFirewall.sh

# Working directory for the Firewall
WORKDIR /opt/corda
ENV HOME=/opt/corda
USER corda

# Informational Port exposure below (recommended ports to use)
# P2P to other nodes
EXPOSE 40000
# BRIDGE P2P
EXPOSE 39999

# Start it
CMD ./startFirewall.sh