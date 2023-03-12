#!//usr/bin/bash
VERSION=$1
URL=https://releases.mattermost.com/${VERSION}/mattermost-team-${VERSION}-linux-amd64.tar.gz

if [[ $EUID != 0 ]]; then
    echo Please run this script as root
    exit -1
fi

if [[ $1 == "" ]]; then
    echo ENTER A VERSION NUMER
    exit -1
fi

echo $URL
echo confirm the above URL looks correct \(\Y\)
read v
if [[ $v != "Y" ]]; then
    echo Please correct the version number
    exit -1
fi

cd /tmp
wget $URL
ls -- mattermost*.gz

if [[ $?  != 0 ]]; then
    echo Please clean up the tmp directory of Mattermost files
    exit -1
fi

tar -xf mattermost*.gz --transform='s,^[^/]\+,\0-upgrade,'

systemctl stop mattermost

cd /opt/
cp -ra mattermost/ mattermost-back-$(date +'%F-%H-%M')/
find mattermost/ mattermost/client/ -mindepth 1 -maxdepth 1 \! \( -type d \( -path mattermost/client -o -path mattermost/client/plugins -o -path mattermost/config -o -path mattermost/logs -o -path mattermost/plugins -o -path mattermost/data \) -prune \) | sort | sudo xargs rm -r
cp -an /tmp/mattermost-upgrade/. mattermost/
chown -R mattermost:mattermost mattermost
setcap cap_net_bind_service=+ep ./mattermost/bin/mattermost
systemctl start mattermost

rm -r /tmp/mattermost-upgrade/
rm -i /tmp/mattermost*.gz

echo MATTERMOST UPGRADE COMPLETE
