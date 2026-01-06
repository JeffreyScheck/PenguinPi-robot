

#Check if we are running with sudo
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Download the git repo if using this script stand-alone
cd /home/pi
if [ ! -d "./PenguinPi-robot" ]; then
	git clone https://github.com/qcr/PenguinPi-robot.git
fi


#install libraries and python modules
apt-get update
apt-get install hostapd python3-netifaces python3-opencv

if ! grep -q "dtparam=uart=on" /boot/firmware/config.txt; then 
	# install penguinpi scripts
	cd ./PenguinPi-robot/software/scripts
	bash update_networking_script.sh
	bash startup/install-webserver.sh

	# Create the crontab entry
	crontab -l > tempCron
	mkdir -p /var/log/pibot/ppweb
	mkdir -p /var/log/pibot/GPIOSoftShutdown
	echo "@reboot python /home/pi/PenguinPi-robot/software/python/robot/ppweb.py >/var/log/pibot/ppweb 2>&1" >> tempCron
	echo "@reboot python /home/pi/PenguinPi-robot/software/scripts/GPIOSoftShutdown.py >/var/log/pibot/GPIOSoftShutdown 2>&1" >> tempCron
	crontab tempCron
	rm tempCron

	#Enable SSH
	systemctl enable ssh
	service sshd start
	#Enable UART for communicating with the AVR board
	echo "dtparam=uart0=on" >> /boot/firmware/config.txt
fi

echo "Done! Reboot is required."
