# pgstyle/h2db
This is yet another **unofficial** Docker image of H2DB server. While there are some other H2DB server images on the Docker Hub, we find that they have not much support in shutdown signal handling. We think allowing the H2DB server shutdown gracefully can reduce the risk of data corruptions.

## Features
- This image uses the official 1.4.200 H2DB library.
- Just like many other H2DB server Docker images, this image can host the H2DB server in PG mode, TCP mode and Web mode.
- Modes are selectable.
- This image supports TCP and Web password.
- And the **most important one** (we think), this image can handle `docker stop` signal and shut down the TCP server gracefully.

## Change history
- **0.9.13**  
bug fix: copy file missed /opt/h2/tools/h2shell
- **0.9.12**  
initially pushed to Docker Hub

## Image variants
based on [openjdk:8-jre](https://hub.docker.com/_/openjdk): `pgstyle/h2db-latest`, `pgstyle/h2db-0.9.12`  
based on [openjdk:8-jre-alpine](https://hub.docker.com/_/openjdk): `pgstyle/h2db-alpine`, `pgstyle/h2db-0.9.12-alpine`

## Usage
Most basic usage:  
```
$ docker run -d -p 5435:5435 -p 8082:8082 -p 9092:9092 -v /opt/pgstyle/docker/h2-data:/opt/h2-data --name h2db pgstyle/h2db
```
This command will create a container named as "h2db" and host PG, TCP, Web server of the H2DB server.

In order to control the behaviour of the container, there are some environment variables that can be set for telling the server loader what to do with the H2DB server. There are the environment variables can be used.

> `H2_DATADIR`: the directory for storing the data files of the H2DB server, default value: `/opt/h2-data`  
> `H2_MODE`: the server mode selector of the server loader, default value: `TCP|WEB|PG`  
> `H2_OPEN`: the open connection selector of the server loader (which make the corresponding server accessible from other containers), default value: `TCP|WEB|PG`  
> `H2_TCPPWD`: the password for the TCP server (which is used to prevent unauthorised server shutdown via org.h2.tools.Server), default value: _`null`_ (disabled)  
> `H2_WEBPWD`: the password for the Web UI (which is used to prevent unauthorised access to the admin panel of the Web UI), default value: _`null`_ (disabled)

## H2Shell
There is an H2Shell available for doing administrative work (especially DB creation). Use the following command to open the H2Shell.
```
$ docker exec -it h2db /bin/sh /opt/h2/tools/h2shell
```
or
```
$ docker exec -it h2db /bin/sh
# h2shell
```

## Github
See source and more information on [Github](https://github.com/pgstyle/docker-h2db)

## Future addition (TODO list)
- Rewrite shutdown handler for mode TCP is off (for fixing a known issue). The current shutdown handler is hardcoded to shut down the TCP server, even if there is no TCP server.
- Add health check
- Add more image variants
- Add `-key` setting in server loader
