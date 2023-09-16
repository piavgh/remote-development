#!/bin/bash

set -e

read -p "Enter desired app name or press return to have a name generated:" APP_NAME

if [ -z "$APP_NAME" ]; then
    APP_NAME="--generatename"
fi

read -p "Enter desired organization name or press return to use your personal org:" ORG_NAME

if [ -z "$ORG_NAME" ]; then
    ORG_NAME="personal"
fi

read -p "Enter desired region:" REGION

if [ -z "$REGION" ]; then
    REGION="sin"
fi

read -p "Enter disk size in GB or press return for default 1GB:" DISK_SIZE_NUM

if [ -z "$DISK_SIZE_NUM" ]; then
    DISK_SIZE=""
else
    DISK_SIZE="${DISK_SIZE_NUM}"
fi

read -p "Use Docker on remote machine (y/n):" usedockerresponse

case $usedockerresponse in 
[Yy])
    usedocker="--build-arg USE_DOCKER=y"
;;
*)
    usedocker=""
;;
esac

echo

read -p "Any extra packages:" extrapackages


AUTHORIZED_KEYS=$(cat ~/.ssh/id_rsa.pub)

echo "
app = \"$APP_NAME\"
primary_region = \"$REGION\"

[[services]]
internal_port = 22
protocol = \"tcp\"

[[services.ports]]
port = 10022

[[mounts]]
source = \"clouddevdata\"
destination = \"/data\"
">fly.toml

# Create a Fly.io application (once)
fly launch --name $APP_NAME --org $ORG_NAME --no-deploy --copy-config

# Set secrets for HOME_SSH_AUTHORIZED_KEYS
fly secrets set HOME_SSH_AUTHORIZED_KEYS="$AUTHORIZED_KEYS"

# Create the persistent volume (once)
fly volumes create clouddevdata --region $REGION --size $DISK_SIZE

fly deploy --build-arg EXTRA_PKGS="$extrapackages" $usedocker 

echo
echo
echo "To use in VS Code, tell the remote-ssh package to connect to $(whoami)@$(fly info --host):10022"

