#!/bin/bash

echo -e "\033[1;32mSet hostname type:\033[0m"
read hostname;
hostnamectl set-hostname $hostname

echo -e "\033[1;32m\033[0m"

echo -e "\033[1;32mUpdating repository\033[0m"
if ! yum -y update
then
    echo -e "\033[1;31m Update Error\033[0m"
    exit 1
fi
echo -e "\033[1;32mSuccessfully Updated\033[0m"

echo -e "\033[1;32m\033[0m"

echo -e "\033[1;32mAdding EPEL repository\033[0m"
if ! yum -y install epel-release
then
    echo -e "\033[1;31m Added Error\033[0m"
    exit 1
fi
echo -e "\033[1;32mSuccessfully Added\033[0m"

echo -e "\033[1;32m\033[0m"

echo -e "\033[1;32mSet SELinux in Permissive Mode by running the commands below\033[0m"
setenforce 0
sed -i 's/\(^SELINUX=\).*/\SELINUX=permissive/' /etc/selinux/config

echo -e "\033[1;32m\033[0m"

echo -e "\033[1;32mInstalling all required dependencies\033[0m"
if ! yum -y install wget vim net-tools
then
    echo -e "\033[1;31m Installation Error\033[0m"
    exit 1
fi
echo -e "\033[1;32mSuccessfully Installation\033[0m"

echo -e "\033[1;32m\033[0m"

echo -e "\033[1;32mInstalling Development Tools\033[0m"
if ! yum -y groupinstall 'Development Tools'
then
    echo -e "\033[1;31m Installation Error\033[0m"
    exit 1
fi
echo -e "\033[1;31m Installation Error\033[0m"

echo -e "\033[1;32m\033[0m"

echo -e "\033[1;32mInstalling Other Packages\033[0m"
if ! yum -y install libedit-devel sqlite-devel psmisc gmime-devel ncurses-devel libtermcap-devel sox newt-devel libxml2-devel libtiff-devel audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion kernel-devel kernel-devel-$(uname -r) git subversion kernel-devel crontabs cronie cronie-anacron wget vim
then
    echo -e "\033[1;31m Installation Error\033[0m"
    exit 1
fi
echo -e "\033[1;31m Installation Error\033[0m"

echo -e "\033[1;32m\033[0m"
echo -e "\033[1;32minstalling JANSSON\033[0m"
cd /usr/src/
git clone https://github.com/akheron/jansson.git
cd jansson
autoreconf  -i
./configure --prefix=/usr/
make && make install

echo -e "\033[1;32m\033[0m"
echo -e "\033[1;32minstalling PJSIP\033[0m"
cd /usr/src/
export VER="2.8"
wget http://www.pjsip.org/release/${VER}/pjproject-${VER}.tar.bz2
tar -jxvf pjproject-${VER}.tar.bz2
cd pjproject-${VER}
./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr
make dep
make
make install
ldconfig

echo -e "\033[1;32m\033[0m"
echo -e "\033[1;32mDownloading and Configuring Asterisk\033[0m"
cd /usr/src/
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz
tar xvfz asterisk-16-current.tar.gz
rm -f asterisk-16-current.tar.gz
cd asterisk-*
./configure --libdir=/usr/lib64

echo -e "\033[1;32m\033[0m"
echo -e "\033[1;32minstalling MP3 Source\033[0m"
make menuselect
contrib/scripts/get_mp3_source.sh

echo -e "\033[1;32m\033[0m"
echo -e "\033[1;32minstalling Asterisk\033[0m"
make
make install
make samples
make config
ldconfig

echo -e "\033[1;32m\033[0m"
echo -e "\033[1;32mPermission on Asterisk Folders\033[0m"
groupadd asterisk
useradd -r -d /var/lib/asterisk -g asterisk asterisk
usermod -aG audio,dialout asterisk
chown -R asterisk.asterisk /etc/asterisk
chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk
chown -R asterisk.asterisk /usr/lib64/asterisk

sed -i 's/#AST_USER="asterisk"/AST_USER="asterisk"/g' /etc/sysconfig/asterisk
sed -i 's/#AST_GROUP="asterisk"/AST_GROUP="asterisk"/g' /etc/sysconfig/asterisk

sed -i 's/;runuser = asterisk/runuser = asterisk/g' /etc/asterisk/asterisk.conf
sed -i 's/;rungroup = asterisk/rungroup = asterisk/g' /etc/asterisk/asterisk.conf

echo -e "\033[1;32m\033[0m"
echo -e "\033[1;32mRestarting and Enabling Asterisk on Startup\033[0m"
systemctl restart asterisk
systemctl enable asterisk
