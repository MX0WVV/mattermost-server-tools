#!//usr/bin/bash
DATE=$(date +'%F-%H-%M')
VERSION=$1
URL=https://releases.mattermost.com/${VERSION}/mattermost-team-${VERSION}-linux-amd64.tar.gz

# We must be running as root, exit otherwise
function check_root {
    if [[ $EUID != 0 ]]; then
        echo Please run this script as root
        exit -1
    fi
}

# Check user has supplied version number of desired Mattermost install
function check_version_number {
    if [[ $VERSION == "" ]]; then
        echo ENTER A VERSION NUMER
        exit -1
    fi
}

# Clean up downloaded files and optionally local backup
function clean_up {
    rm -r /tmp/mattermost-upgrade/
    rm -i /tmp/mattermost*.gz
    echo PLEASE CHECK THE MATTERMOST SERVICE, IF YOU WISH TO DELETE THE LOCAL BACKUP ENTER \(\Y\)
    read v
    if [[ $v == "Y" ]]; then
        rm -r mattermost-back-$DATE
    fi
    echo MATTERMOST UPGRADE COMPLETE
}

# Ask for confirmation before running upgrade
function confirm_run {
    echo $URL
    echo confirm the above URL looks correct \(\Y\)
    read v
    if [[ $v != "Y" ]]; then
        echo Please correct the version number
        exit -1
    fi
    run
}

# Run the upgrade
function run {
    cd /tmp
    wget $URL

    # If there is already a version of Mattermost downloaded, stop and ask user to clean up
    ls -- mattermost*.gz
    if [[ $?  != 0 ]]; then
        echo Please clean up the tmp directory of Mattermost files
        exit -1
    fi

    tar -xf mattermost*.gz --transform='s,^[^/]\+,\0-upgrade,'
    service_control stop
    cd /opt/
    cp -ra mattermost/ mattermost-back-$DATE/

    # clean up old installed files, ignore persistent paths
    find mattermost/ mattermost/client/ -mindepth 1 -maxdepth 1 \! \( -type d \( -path mattermost/client -o -path mattermost/client/plugins -o -path mattermost/config -o -path mattermost/logs -o -path mattermost/plugins -o -path mattermost/data \) -prune \) | sort | sudo xargs rm -r

    cp -an /tmp/mattermost-upgrade/. mattermost/
    chown -R mattermost:mattermost mattermost
    setcap cap_net_bind_service=+ep ./mattermost/bin/mattermost
    service_control start
    clean_up
}

# Wrapper for service control
function service_control {
    systemctl $1 mattermost
}


check_root
check_version_number
confirm_run
