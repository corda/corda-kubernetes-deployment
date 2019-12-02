FROM azul/zulu-openjdk-alpine:8u192

RUN apk upgrade --update && \
    apk add --update --no-cache bash iputils nfs-utils nss curl netcat-openbsd lftp openssh-client openssh-server jq && \
    rm -rf /var/cache/apk/* && \
    # Add user to run the app && \
    addgroup corda && \
    adduser -G corda -D -s /bin/bash corda && \
    # Create /opt/corda directory && \
	mkdir -p /opt/corda/workspace

ADD --chown=corda:corda corda.jar /opt/corda/corda.jar
ADD --chown=corda:corda corda-tools-health-survey.jar /opt/corda/corda-tools-health-survey.jar
ADD --chown=corda:corda startCorda.sh /opt/corda/startCorda.sh
ADD --chown=corda:corda checkHealth.sh /opt/corda/checkHealth.sh

# Permissioning
RUN chown -R corda:corda /opt/corda

RUN dos2unix /opt/corda/startCorda.sh /opt/corda/startCorda.sh
RUN chmod +x /opt/corda/startCorda.sh
RUN dos2unix /opt/corda/checkHealth.sh /opt/corda/checkHealth.sh
RUN chmod +x /opt/corda/checkHealth.sh

# Working directory for the Node
WORKDIR /opt/corda
ENV HOME=/opt/corda
USER corda

# Informational Port exposure below (recommended ports to use)
# P2P
EXPOSE 40000
# RPC
EXPOSE 30000
# H2 DB console access (only for development use)
EXPOSE 55555
# SSH
EXPOSE 2223

# Start it
CMD ./startCorda.sh