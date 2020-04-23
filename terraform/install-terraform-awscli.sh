#!/bin/bash

# Originally the Mordor script: install-terraform-packer.sh
# Original Mordor script description: Install Terraform for Linux or Mac
# Original Author: Roberto Rodriguez (@Cyb3rWard0g)
# Updated by: Dustin Lee and Wes Lambert
# License: GPL-3.0

SYSTEM_KERNEL="$(uname -s)"


[ "$SYSTEM_KERNEL" == "Linux" ] && apt-get update

if ! [ -x "$(command -v wget)" ]; then
    echo "[TERRAFORM-INFO] Installing Wget for $SYSTEM_KERNEL"
    if [ "$SYSTEM_KERNEL" == "Linux" ]; then
	apt-get install -y --no-install-recommends wget
    elif [ "$SYSTEM_KERNEL" == "Darwin" ]; then
        brew install wget
    fi
fi

if ! [ -x "$(command -v unzip)" ]; then
    echo "[TERRAFORM-INFO] Installing Unzip for $SYSTEM_KERNEL"
    if [ "$SYSTEM_KERNEL" == "Linux" ]; then
        apt-get install -y --no-install-recommends unzip
    elif [ "$SYSTEM_KERNEL" == "Darwin" ]; then
        brew install unzip
    fi
fi

if ! [ -x "$(command -v pip3)" ]; then
    echo "[TERRAFORM-INFO] Installing pip3 for $SYSTEM_KERNEL"
    if [ "$SYSTEM_KERNEL" == "Linux" ]; then
        apt-get install -y --no-install-recommends python3-pip
	python3 -m pip install -U setuptools
    elif [ "$SYSTEM_KERNEL" == "Darwin" ]; then
        brew install pip3
    fi
fi

if ! [ -x "$(command -v awscli)" ]; then
    if [ -x "$(command -v python3)" ]; then
        echo "[TERRAFORM-INFO] Installing awscli for $SYSTEM_KERNEL via pip"
	python3 -m pip install -U awscli
    else
        echo "[TERRAFORM-INFO] python3 is needed for this step.."
        exit 1
    fi
fi

if ! [ -x "$(command -v awsebcli)" ]; then
    if [ -x "$(command -v python3)" ]; then
        echo "[TERRAFORM-INFO] Installing awsebcli for $SYSTEM_KERNEL via pip"
        python3 -m pip install -U awsebcli
    else
        echo "[TERRAFORM-INFO] python3 is needed for this step.."
        exit 1
    fi
fi

TERRAFORM_VERSION=0.12.2

if [ "$SYSTEM_KERNEL" == "Linux" ]; then 
    OPERATING_SYSTEM=linux
elif [ "$SYSTEM_KERNEL" == "Darwin" ]; then
    OPERATING_SYSTEM=darwin
fi

TERRAFORM_DOWNLOAD=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OPERATING_SYSTEM}_amd64.zip

echo "[TERRAFORM-INFO] Installing Terraform & Packer for $SYSTEM_KERNEL"

if ! [ -x "$(command -v /usr/local/bin/terraform)" ]; then
    echo "[TERRAFORM-INFO] Installing Terraform.."
    wget $TERRAFORM_DOWNLOAD -P /tmp/
    unzip -j /tmp/*.zip -d /usr/local/bin/
    rm /tmp/*.zip
fi
