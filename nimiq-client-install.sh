#!/bin/bash
################################################################################
# Author:  Bhlynd _& JC
# Program: Install Nimiq on Ubuntu
# Flavor: Porky Pool (https://www.porkypool.com)
################################################################################
output() {
  echo $1
}

displayErr() {
  echo
  echo $1;
  echo
  exit 1;
}

mkdir /nimiq
cd /nimiq

INSTALL_LOG="/nimiq/install.log"
exec 3>&1 1>>${INSTALL_LOG} 2>&1

sudo adduser nimiq --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
chown nimiq:nimiq /nimiq
sudo usermod -aG sudo nimiq
cd /nimiq

POOL=us-east.porkypool.com:8444
THREADS=$(getconf _NPROCESSORS_ONLN)
WALLET="NQ73 LLJ3 YC4T 4N64 TPEM S6RF J3L4 0GRR 5U12"
EXTRADATA=$HOSTNAME
STATISTICS=15

output " "
output "Making sure everything is up to date."
output " "

sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y autoremove

output " "
output "Adding nodejs sources."
output " "

curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -

output " "
output "Installing required dependencies."
output " "

sudo apt-get install -y git build-essential python2.7 python-dev nodejs unzip

output " "
output "Downloading Nimiq core."
output " "

git clone https://github.com/ryan-rowland/core.git

output " "
output "Building Nimiq core client."
output " "

sudo chown nimiq:nimiq /nimiq -R
cd core
sudo -H -u nimiq npm install
sudo -H -u nimiq npm run prepare

output " "
output "Building launch scripts."
output " "

cd ..
echo '#!/bin/bash
SCRIPT_PATH=$(dirname "$0")/core
$SCRIPT_PATH/clients/nodejs/nimiq "$@"' > miner
chmod u+x miner

echo '#!/bin/bash
UV_THREADPOOL_SIZE='"${THREADS}"' ./miner --dumb --pool='"${POOL}"' --miner='"${THREADS}"' --wallet-address="'"${WALLET}"'" --extra-data="'"${EXTRADATA}"'" --statistics='"${STATISTICS}"'' > start
chmod u+x start

output " "
output "Downloading consensus."
output " "

if [ ! -d "./main-full-consensus" ]; then
  wget https://github.com/ryan-rowland/Nimiq-Install-Script/raw/master/main-full-consensus.tar.gz
  tar -xvf main-full-consensus.tar.gz
  rm main-full-consensus.tar.gz
fi

output "Congratulations! If everything went well you can now start mining."
output " "
output "To start the miner type ./start"
output " "
output "If you need to change any settings, you can do so by editing the start file."

output " "
output "Configuring crontab"
output " "

#write out current crontab
crontab -l > mycron
#echo new cron into cron file
echo "@reboot /nimiq/start > /nimiq/log.txt" >> mycron
#install new cron file
crontab mycron
rm mycron

output " "
output "Starting nimiq"
output " "

sudo chown nimiq:nimiq /nimiq -R
sudo -H -u nimiq /nimiq/start > /nimiq/log.txt
