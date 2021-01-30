# PGStyle H2DB Dockerfile
ARG OPENJDK_VERSION=8-jre
FROM openjdk:${OPENJDK_VERSION}

LABEL maintainer="PGKan <pgkan@pgstyle.org>"

# Install H2DB
ARG H2_SOURCE=https://h2database.com/h2-2019-10-14.zip
ARG H2_DATADIR=/opt/h2-data
RUN \
cd /tmp                               && \
wget -O h2.zip ${H2_SOURCE}           && \
unzip h2.zip -d /opt/ > /dev/null     && \
rm h2.zip                             && \
cd /opt/h2/                           && \
rm docs/ src/ service/ build.* -r

# Setup network and H2 server parameters
WORKDIR /opt/h2-data
EXPOSE 5435/tcp 8082/tcp 9092/tcp
ENV H2_DATADIR=${H2_DATADIR}   \
    H2_MODE=TCP|WEB|PG         \
    H2_OPEN=TCP|WEB|PG         \
    H2_TCPPWD=                 \
    H2_WEBPWD=                 \
    PATH=${PATH}:/opt/h2/tools

# Copy files 
COPY copy-file/ /

# Define default command
ENTRYPOINT [ "/docker-entrypoint.sh" ]

# Seal of verson
ENV IMAGE_VERSION=0.9.14
