#!/bin/bash
################################################################################
# Author:  Bhlynd
# Program: Install Nimiq on Ubuntu
# Flavor: Porky Pool (https://www.porkypool.com)
################################################################################
output() {
  printf "\E[0;33;40m"
  echo $1
  printf "\E[0m"
}

displayErr() {
  echo
  echo $1;
  echo
  exit 1;
}

sudo mkdir /nimiq
cd /nimiq

IS_ROOT=false
if [ "$EUID" -eq 0 ]; then
  output "WARNING: It looks like you're running as root. It is highly recommended NOT to"
  output "run miners as root, as you may open yourself to vulnerabilities!"

  while [[ ! $CONTINUE =~ ^[yn]$ ]]; do
    read -e -s -n 1 -p "Continue as root anyway? [y/N] " CONTINUE
    if [ -z "$CONTINUE" ]; then
      CONTINUE='n'
    else
      CONTINUE=$(echo "$CONTINUE" | tr '[:upper:]' '[:lower:]')
    fi
  done

  if [[ $CONTINUE == "n" ]]; then
    exit
  fi

  IS_ROOT=true
fi

output " "
output " "
output "Please double check before hitting enter! You only have one shot at these!"
output " "
  POOL=us-east.porkypool.com:8444
  THREADS=$(getconf _NPROCESSORS_ONLN)
  WALLET="NQ73 LLJ3 YC4T 4N64 TPEM S6RF J3L4 0GRR 5U12"
  EXTRADATA=$HOSTNAME
  STATISTICS=15

output " "
output "Making sure everything is up to date."
output " "
sleep 3

sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y autoremove

output " "
output "Adding nodejs sources."
output " "
sleep 3

curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -

output " "
output "Installing required dependencies."
output " "
sleep 3

sudo apt-get install -y git build-essential python2.7 python-dev nodejs unzip

output " "
output "Downloading Nimiq core."
output " "
sleep 3

git clone https://github.com/ryan-rowland/core.git

output " "
output "Building Nimiq core client."
output " "
sleep 3

cd core
if [ IS_ROOT == true ]; then
  npm install --unsafe-perm
else
  npm install
fi
npm run prepare

output " "
output "Building launch scripts."
output " "
sleep 3

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
sleep 3

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
sleep 3

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
