#!/bin/sh

#Get into the installation path /root/
cd /root/
currentpath=`pwd`
if [ "$currentpath" != "/root" ]; then
    echo "Cannot get into installation path"
    exit 0
fi

#Update the opkg package info
try=0
opkg update
if [ $? -ne 0 ]; then
    echo "opkg update failed, check the network connection."
    exit 0
fi

#Install python3.6
echo "Install python3.6"
opkg install python3
if [ $? -ne 0 ]; then
    echo "Install python3.6 failed, check the network connection."
    exit 0
fi

#Download and install latest pip for python3
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo "Download python3 pip installation script, try $try"
        curl https://bootstrap.pypa.io/get-pip.py > get-pip.py
        if [ $? -ne 0 ]; then
            rm ./get-pip.py
            continue
        else
            break
        fi
    else
        echo "Download python3 pip installation script failed, exit."
        exit 0
    fi
done

#Install python3 pip
python3 get-pip.py
if [ $? -ne 0 ]; then
    echo "Install python3 pip failed, exit."
    exit 0
fi
rm ./get-pip.py

#Install gcc
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo "Download gcc installation package, try $try"
        curl http://download.gl-inet.com/releases/packages-3.x/ipq40xx/packages/gcc_4.8.3-1_ipq806x.ipk > gcc_4.8.3-1_ipq806x.ipk
        if [ $? -ne 0 ]; then
            rm ./gcc_4.8.3-1_ipq806x.ipk
            continue
        else
            break
        fi
    else
        echo "Download gcc installation package failed, exit."
        exit 0
    fi
done

#Install gcc package
opkg install ./gcc_4.8.3-1_ipq806x.ipk
if [ $? -ne 0 ]; then
    echo "Install gcc failed, exit."
    exit 0
fi
rm ./gcc_4.8.3-1_ipq806x.ipk

#Install dependent C library
opkg install python3-dev
if [ $? -ne 0 ]; then
    echo "Install python3-dev failed, exit."
    exit 0
fi
echo "Install C library......libffi"
mkdir -p /usr/include/ffi && \
cp ./HomeAssistantInstallation/ffi* /usr/include/ffi && \
ln -s /usr/lib/libffi.so.6.0.1 /usr/lib/libffi.so
echo "Install C library......libopenssl"
cp -r ./HomeAssistantInstallation/openssl /usr/include/python3.6/ && \
ln -s /usr/lib/libcrypto.so.1.0.0 /usr/lib/libcrypto.so && \
ln -s /usr/lib/libssl.so.1.0.0 /usr/lib/libssl.so
echo "Install C library......libsodium"
opkg install libsodium
if [ $? -ne 0 ]; then
    echo "Install libsodium failed, exit."
    exit 0
fi
cp ./HomeAssistantInstallation/sodium.h /usr/include/python3.6/ && \
cp -r ./HomeAssistantInstallation/sodium /usr/include/python3.6/ && \
ln -s /usr/lib/libsodium.so.23.1.0 /usr/lib/libsodium.so

#Install dependent python module
echo "Install python module......PyNaCl"
SODIUM_INSTALL=system pip3 install pynacl
if [ $? -ne 0 ]; then
    echo "Install PyNaCl failed, exit."
    exit 0
fi
echo "Install python module......cryptography"
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo "Download cryptography package, try $try"
        curl https://files.pythonhosted.org/packages/07/ca/bc827c5e55918ad223d59d299fff92f3563476c3b00d0a9157d9c0217449/cryptography-2.6.1.tar.gz > cryptography-2.6.1.tar.gz
        if [ $? -ne 0 ]; then
            rm ./cryptography-2.6.1.tar.gz
            continue
        else
            break
        fi
    else
        echo "Download cryptography package failed, exit."
        exit 0
    fi
done
tar -xzvf cryptography-2.6.1.tar.gz && \
cd ./cryptography-2.6.1 && \
LDFLAGS=-pthread python3 setup.py install && \
cd ../
if [ $? -ne 0 ]; then
    echo "Install cryptography failed, exit."
    exit 0
fi
rm -rf ./cryptography-2.6.1*

#Python module aiohttp_cors
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo "Install necessary python module......aiohttp_cors, try $try"
        pip3 install aiohttp_cors==0.7.0
        if [ $? -ne 0 ]; then
            continue
        else
            break
        fi
    else
        echo "Install aiohttp_cors failed, exit."
        exit 0
    fi
done
#Python module sqlalchemy
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo "Install necessary python module......sqlalchemy, try $try"
        pip3 install sqlalchemy==1.3.3
        if [ $? -ne 0 ]; then
            continue
        else
            break
        fi
    else
        echo "Install sqlalchemy failed, exit."
        exit 0
    fi
done
#Python module pycryptodome
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo "Install necessary python module......pycryptodome, try $try"
        pip3 install pycryptodome==3.3.1
        if [ $? -ne 0 ]; then
            continue
        else
            break
        fi
    else
        echo "Install pycryptodome failed, exit."
        exit 0
    fi
done
#Python module home-assistant-frontend
try=0
while true
do
    try=$((try+1))
    if [ $try -le 5 ]; then
        echo "Install necessary python module......home-assistant-frontend, try $try"
        pip3 install home-assistant-frontend
        if [ $? -ne 0 ]; then
            continue
        else
            break
        fi
    else
        echo "Install home-assistant-frontend failed, exit."
        exit 0
    fi
done
#Install Home Assistant
echo "Install HomeAssistant"
python3 -m pip install homeassistant
if [ $? -ne 0 ]; then
    echo "Install homeassistant failed, exit."
    exit 0
fi
#Config the web ip
echo "server_host: 192.168.8.1" >> ./.homeassistant/configuration.yaml
echo "server_port: 8123" >> ./.homeassistant/configuration.yaml
#Clean the installation path
rm -rf ./.cache/
#Add multicast router rule
echo "Add multicast route rule"
ip route add broadcast 224.0.0.0/24 dev br-lan
#Install finished
echo "HomeAssistant installation finished."
