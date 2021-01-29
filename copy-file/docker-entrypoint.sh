#!/usr/bin/env sh
#================================================================
# docker-entrypoint
#----------------------------------------------------------------
# This is the entrypoint of the H2DB image from PGStyle.org.
# this file checks mounted volume and create signal trap for
# shutting down the H2DB server gracefully.
#----------------------------------------------------------------
# author: PGKan
# last-modify: 2020/01/29 14:45+0800
#================================================================

# Greetings
echo -e "\e[1;32mpgstyle\e[0m/\e[1;32mh2db\e[0m";
echo "Docker image for H2DB Server, version ${IMAGE_VERSION}. Made by PGStyle.org";
echo -e "For more information, visit <https://github.com/pgstyle/docker-h2db>\n";

# Pre-deployment steps

# Volume check
echo ": testing mounted volume";
eval "echo \"${HOSTNAME}:$(date -u '+%Y%m%dT%H%M%SZ')\" >> ${H2_DATADIR}/.linked" 2>/dev/null;
if [[ $? -ne 0 ]]; then
    echo -e "\e[1;31mfailed in linking mounted volume, please check docker run arguments\e[0m">&2;
    echo -e ": exit error\n">&2;
    exit 255;
fi;
echo -e "\e[1;32mmounted volume is linked successfully, proceed\e[0m";

# Shutdown signal trap
echo ": setting up container stop signal trap";
echo -e "\e[1;33mnotice: this container will listen to the 'docker stop' signal and initiate the shutdown sequence of the H2DB server\e[0m">&2;
function stopH2() {
    echo -e "\e[1;33mreceived shutdown signal: $1\e[0m">&2;
    echo ": shutting down H2";
    java -cp /opt/h2/bin/h2*.jar org.h2.tools.Server -tcpShutdown tcp://localhost:${H2_TCPPORT} -tcpPassword ${H2_TCPPWD};
    if [[ $? -eq 0 ]]; then
        echo -e "\e[1;32mH2 server stopped\e[0m";
        echo -e ": exit success\n";
        exit 0;
    else
        echo -e "\e[1;31mfailed in stopping H2 server\e[0m">&2;
        echo -e ": exit error\n";
        exit 137;
    fi;
}
error=0
trap 'stopH2 SIGTERM' SIGTERM;
error=$((error * 256 + $?));
trap 'stopH2 SIGINT' SIGINT;
error=$((error * 256 + $?));
trap 'stopH2 SIGQUIT' SIGQUIT;
error=$((error * 256 + $?));
if [[ ${error} -ne 0 ]]; then
    echo -e "\e[1;31mfailed in setting up shutdown signal trap, with return status: $?\e[0m">&2;
    echo -e "\e[1;33mnotice: this return status is splitted into 3 8-bits parts, each parts represent the status of each trap setup\e[0m">&2;
    echo -e ": exit error\n">&2;
    exit 1;
fi;
echo -e "\e[1;32mshutdown signal trap set up successfully, proceed\e[0m";

# Construct H2 Server arguments
echo ": constructing java arguments";
farg="-ifExists -trace -baseDir \"${H2_DATADIR}\"";
echo ": append fixed arguments: ${farg}";
cmd="java -cp /opt/h2/bin/h2*.jar org.h2.tools.Server ${farg}";
echo ": append arguments for server modes";
if [[ $(expr match "${H2_MODE}" '.*TCP.*') ]]; then
    echo -e "\e[1;32mTCP mode is enabled\e[0m";
    arg="-tcp";
    larg="";
    if [[ $(expr match "${H2_OPEN}" '.*TCP.*') ]]; then
        echo -e "\e[1;32mTCP open connection is enabled\e[0m";
        arg="${arg} -tcpAllowOthers";
    fi;
    if [[ "${H2_TCPPWD}" != "" ]]; then
        echo -e "\e[1;32mTCP password is enabled\e[0m";
        larg="-tcpPassword ******";
        sarg="-tcpPassword ${H2_TCPPWD}";
    fi;
    echo ": append arguments: ${arg} ${larg}";
    cmd="${cmd} ${arg} ${sarg}";
fi;
if [[ $(expr match "${H2_MODE}" '.*PG.*') ]]; then
    echo -e "\e[1;32mPG mode is enabled\e[0m";
    arg="-pg";
    if [[ $(expr match "${H2_OPEN}" '.*PG.*') ]]; then
        echo -e "\e[1;32mPG open connection is enabled\e[0m";
        arg="${arg} -pgAllowOthers";
    fi;
    echo ": append arguments: ${arg}";
    cmd="${cmd} ${arg}";
fi;
if [[ $(expr match "${H2_MODE}" '.*WEB.*') ]]; then
    echo -e "\e[1;32mWeb mode is enabled\e[0m";
    arg="-web";
    larg="";
    if [[ $(expr match "${H2_OPEN}" '.*WEB.*') ]]; then
        echo -e "\e[1;32mWeb open connection is enabled\e[0m";
        arg="${arg} -webAllowOthers";
    fi;
    if [[ "${H2_WEBPWD}" != "" ]]; then
        echo -e "\e[1;32mWeb admin password is enabled\e[0m";
        larg="-webAdminPassword ******";
        sarg="-webAdminPassword ${H2_WEBPWD}";
    fi;
    echo ": append arguments: ${arg} ${larg}";
    cmd="${cmd} ${arg} ${sarg}";
fi;
echo ": finished in construncting java command line";
echo -e "\e[1;32mall configuration setup successfully, proceed\e[0m";

# Final
echo ": starting H2 server";
${cmd} &
echo ": issued start signal of H2 server";
echo -e ": entry processes finished, sleep indefinitely\n";
wait;
