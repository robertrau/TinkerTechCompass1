#!/bin/bash
# This script takes a fresh Raspberry Pi Zero NOOBS 2.8.2 install and sets up a Raspberry Pi Zero for the TinkerTech board
#
# Written: 9/30/2018
#    Rev.: 1.00
#      By: Robert S. Rau & Rob F. Rau II
#  Source: Swiped form PyFly setup script 1.58
#
# Updated: 
#    Rev.: 1.01
#      By: Robert S. Rau & Rob F. Rau II
# Changes: 
#
#
TINKERTECH1SETUPVERSION=1.00
#
# Things to think about
#
#
#
#
# Organization
# 0) Pre run checks. Check that we are running with root permissions, we have a internet connection and log who we are and what is connected.
# 1) Setup directory structure
# 2) Set up Raspberry Pi configuration
# 3) install RF transmitters and modulators
# 4) install audio support
# 5) Graphics for Video downlink support
# 6) High current/GPS/RF/LED output support
# 7) IMU (MPS9250) support
# 8) RTC support
# 9) Developer tools
#
#
#
#
mydirectory=$(pwd)     #  remember what directory I started in
#
########## 0) Pre run checks. Check that we are running with root permissions, we have a internet connection and log who we are and what is connected.
tput setaf 5        # highlight text magenta
echo "Set Terminal Scroll-back lines to 4500 to record whole install. Set terminal window to full width of screen for best readability."
tput setaf 7        # return text to normal
#
if [[ $EUID > 0 ]]; then
	echo "Please run using: sudo ./TinkerTechsetup.sh"
    sudo echo "TinkerTech1 Setup: Aborted, not in sudo." $(date +"%A,  %B %e, %Y, %X %Z") >> $logFilePath
    exit
fi
logFilePath=/var/log/tinkertechinstalllog.txt
runlogFilePath=/var/log/tinkertechrunlog.txt
echo "" >> $logFilePath
echo "Install started " $(date +"%A,  %B %e, %Y, %X %Z") >> $logFilePath
echo "TinkerTech1 Setup: Script version" $TINKERTECH1SETUPVERSION >> $logFilePath
echo "TinkerTech1 Setup: ran from directory:" $mydirectory >> $logFilePath
whoami >> $logFilePath
ping -c 1 8.8.8.8
if [[ $? > 0 ]]; then
    echo ""
    echo "No Network connection. Have you connected with your WiFi network or plugged in your network cable before running this?"
    echo "TinkerTech1 Setup: Aborted, no network connection, ping 8.8.8.8 failed" >> $logFilePath
    exit
fi
echo "TinkerTech1 Setup: Have network connection" >> $logFilePath
echo "" >> $logFilePath
echo "TinkerTech1 Setup: uname -a:" >> $logFilePath
uname -a >> $logFilePath
echo "" >> $logFilePath
echo "TinkerTech1 Setup: cat /proc/cpuinfo:" >> $logFilePath
cat /proc/cpuinfo >> $logFilePath
echo "" >> $logFilePath
echo "TinkerTech1 Setup: lsusb -t:" >> $logFilePath
lsusb -t  >> $logFilePath
echo "" >> $logFilePath
echo "TinkerTech1 Setup: lsmod:" >> $logFilePath
lsmod >> $logFilePath
#
df -PBMB | grep -E '^/dev/root' | awk '{ print "TinkerTech1 Setup: Free SD card space before install " $4 " of " $2 }' >> $logFilePath
#
#
#
#
#
#
#
#
########## 1) Setup directory structure
echo "TinkerTech1 setup: Starting directory setup and git update" >> $logFilePath
echo "" >> $logFilePath
echo "TinkerTech1 setup: Starting directory setup"
cd /home/pi
if [ -d tinkertech ]; then
  echo "TinkerTech1 Setup: tinkertech directory already exists: result" $? >> $logFilePath
else
  mkdir tinkertech
  echo "TinkerTech1 Setup: tinkertech directory created: result" $? >> $logFilePath
fi
chown pi:pi tinkertech     # because when this script is run with sudo, everything belongs to root
echo "TinkerTech1 Setup: mkdir tinkertech: result" $? >> $logFilePath
# switch to install directory
cd /home/pi/tinkertech
#
#
#
apt-get update
echo "TinkerTech1 Setup: apt-get update: result" $? >> $logFilePath
#
#
echo "New install of tinkertechsetup version " $TINKERTECH1SETUPVERSION " on" $(date +'%A,  %B %e, %Y, %X %Z') >> $runlogFilePath
#
#
#
#
########## 2) Set up Raspberry Pi configuration
# see:https://www.raspberrypi.org/forums/viewtopic.php?f=44&t=130619
# for SPI see (see DMA note at bottom):https://www.raspberrypi.org/documentation/hardware/raspberrypi/spi/README.md
echo "TinkerTech1 Setup: Starting Raspberry Pi configuration"
#
#
# shutdown support
# http://www.recantha.co.uk/blog/?p=13999
#
# HALTGPIOBIT selects the GPIO port (BCM number, not pin number)
HALTGPIOBIT=26
echo "TinkerTech1 Setup: Starting push button halt setup" >> $logFilePath
cd /home/pi/tinkertech
if [ -d Adafruit-GPIO-Halt ]; then
  cd Adafruit-GPIO-Halt
  git pull
  echo "TinkerTech1 Setup: git pull of Adafruit_GPIO_Halt: result" $? >> $logFilePath
else
  git clone https://github.com/robertrau/Adafruit-GPIO-Halt
  echo "TinkerTech1 Setup: git clone of Adafruit_GPIO_Halt: result" $? >> $logFilePath
  cd Adafruit-GPIO-Halt
fi
#
#
#
make &>> $logFilePath
echo "TinkerTech1 Setup: make of Adafruit_GPIO_Halt: result" $? >> $logFilePath
make install &>> $logFilePath
echo "TinkerTech1 Setup: make install of Adafruit_GPIO_Halt: result" $? >> $logFilePath
#
cat /etc/rc.local | grep -q gpio-halt
GPIO_HALT_NOT_FOUND=$?
if [ $GPIO_HALT_NOT_FOUND -eq 1 ]; then
#    **** These next lines add gpio-halt... to end of rc.local before exit 0 line. They also combine the error codes to one number (just for fun)
  echo "TinkerTech1 Setup: gpio-halt not found in rc.local" >> $logFilePath
  sed -i.bak -e "s/exit 0//" /etc/rc.local
  GPIOHALTRES=$(($?*10))
  echo "gpio mode" $HALTGPIOBIT "up" >> /etc/rc.local
  echo "/usr/local/bin/gpio-halt" $HALTGPIOBIT "&" >> /etc/rc.local
  GPIOHALTRES=$(($?+$GPIOHALTRES))
  GPIOHALTRES=$((10*$GPIOHALTRES))
  echo "exit 0" >> /etc/rc.local
  GPIOHALTRES=$(($?+$GPIOHALTRES))
  echo "TinkerTech1 Setup: /etc/rc.local editing for gpio-halt" $HALTGPIOBIT "&: result" $GPIOHALTRES >> $logFilePath
  cd /home/pi/pifly
  chown -R pi:pi Adafruit-GPIO-Halt     # because when this script is run with sudo, everything belongs to root, must chown
else
  echo "TinkerTech1 Setup: gpio-halt already in rc.local" >> $logFilePath
fi
#
#
# Setup camera
#
#   with help from
#     https://raspberrypi.stackexchange.com/questions/10357/enable-camera-without-raspi-config/14400
#     https://core-electronics.com.au/tutorials/create-an-installer-script-for-raspberry-pi.html
#
#echo "TinkerTech1 Setup: Starting camera setup" >> $logFilePath
#grep "start_x=1" /boot/config.txt
#if grep "start_x=1" /boot/config.txt
#then
#        echo "TinkerTech1 Setup: Camera already installed" >> $logFilePath
#else
#        sed -i "s/start_x=0/start_x=1/g" /boot/config.txt
#fi
#
#
# If a line containing "gpu_mem" exists
#if grep -Fq "gpu_mem" $CONFIG
#then
	# Replace the line
#	echo "TinkerTech1 Setup: Modifying gpu_mem"
#	sed -i "/gpu_mem/c\gpu_mem=128" $CONFIG
#else
	# Create the definition
#	echo "TinkerTech1 Setup: gpu_mem not defined. Creating definition"
#	echo "gpu_mem=128" >> $CONFIG
#fi
#
#
#
#
# update run log on startup
sed -i.bak -e "s/exit 0//" /etc/rc.local
echo 'echo "PiFly booted on " $(date +"%A,  %B %e, %Y, %X %Z") >> /var/log/piflyrunlog.txt' >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
#
#
#
#
########## 3) install RF transmitters and modulators
#
#  nbfm - narrow band FM - 144MHz transmitter, uses GPIO4
echo "TinkerTech1 Setup: Starting nbfm setup" >> $logFilePath
cd /home/pi/pifly
if [ -d NBFM ]; then
  cd NBFM
  git pull
  echo "TinkerTech1 Setup: git pull of nbfm: result" $? >> $logFilePath
else
  git clone https://github.com/fotografAle/NBFM
  echo "TinkerTech1 Setup: git clone of nbfm: result" $? >> $logFilePath
  cd ./NBFM
fi
chmod +x TX-CPUTemp.sh
echo "TinkerTech1 Setup: chmod +x TX-CPUTemp.sh: result" $? >> $logFilePath
echo "TinkerTech1 Setup: Starting gcc -O3 -lm -std=gnu99 -o nbfm nbfm.c &> $logFilePath" >> $logFilePath
gcc -O3 -lm -std=gnu99 -o nbfm nbfm.c &>> $logFilePath                 # changed from -std=c99 to -std=gnu99, and -o3 to -O3
echo "TinkerTech1 Setup: gcc -O3 -lm -std=gnu99 -o nbfm nbfm.c &>> $logFilePath: result" $? >> $logFilePath
cd /home/pi/pifly
chown -R pi:pi NBFM     # because when this script is run with sudo, everything belongs to root
echo "TinkerTech1 Setup: chown -R pi:pi NBFM: result" $? >> $logFilePath
#
#
#  rpitx - able to TX on 440MHz band, uses GPIO18 or GPIO4
echo "TinkerTech1 Setup: Starting rpitx setup" >> $logFilePath
cd /home/pi/pifly
if [ -d rpitx ]; then
  cd rpitx
  git pull
  echo "TinkerTech1 Setup: git pull of rpitx: result" $? >> $logFilePath
else
  git clone https://github.com/F5OEO/rpitx
  echo "TinkerTech1 Setup: git clone of rpitx: result" $? >> $logFilePath
  cd ./rpitx
fi
./install.sh
echo "TinkerTech1 Setup: rpitx install: result" $? >> $logFilePath
#
# Fetch demo scripts
cp /home/pi/piflySetupScript/text2RFrpitx.sh .
echo "TinkerTech1 Setup: cp /home/pi/piflysetupscript/text2RFrpitx.sh .: result" $? >> $logFilePath
mv /home/pi/piflySetupScript/Demo144-39MHz.sh .
echo "TinkerTech1 Setup: mv /home/pi/piflysetupscript/Demo144-39MHz.sh .: result" $? >> $logFilePath
cd /home/pi/pifly
chown -R pi:pi rpitx     # because when this script is run with sudo, everything belongs to root
echo "TinkerTech1 Setup: chown -R pi:pi rpitx: result" $? >> $logFilePath
#
#
#
#
#  pifm - able to TX on 144MHz band, uses GPIO4
echo "TinkerTech1 Setup: Starting pifm setup" >> $logFilePath
cd /home/pi/pifly
if [ -d pifm ]; then
  cd pifm
  git pull
  echo "TinkerTech1 Setup: git pull of pifm: result" $? >> $logFilePath
else
  git clone https://github.com/rm-hull/pifm
  echo "TinkerTech1 Setup: git clone of pifm: result" $? >> $logFilePath
  cd ./pifm
fi
chown pi:pi pifm.cpp     # because when this script is run with sudo, everything belongs to root
echo "TinkerTech1 Setup: chown pi:pi pifm.cpp: result" $? >> $logFilePath
g++ -O3 -o pifm pifm.cpp &>> $logFilePath
echo "TinkerTech1 Setup: pifm:g++ pifm: result" $? >> $logFilePath
cd /home/pi/pifly
chown -R pi:pi pifm     # because when this script is run with sudo, everything belongs to root
#
#
#  Packet radio modulator. Text to modem .WAV file
cd /home/pi/pifly
wget https://raw.githubusercontent.com/km4efp/pifox/master/pifox/pkt2wave
echo "TinkerTech1 Setup: wget pkt2wave: result" $? >> $logFilePath
chmod +x pkt2wave
chown pi:pi pkt2wave     # because when this script is run with sudo, everything belongs to root
#
#
#
#  slow scan TV
# will add later
#https://www.element14.com/community/community/raspberry-pi/raspberrypi_projects/blog/2014/01/27/pi-noir-and-catch-santa-challenge--the-dutch-way
#
#
#
#
#
#
#
#
#
#
#
#
########## 5) Graphics for Video downlink support
#
# Python matplotlib
echo "TinkerTech1 Setup: Starting python-matplotlib setup" >> $logFilePath
apt-get -y install python-matplotlib
#
echo "TinkerTech1 Setup: apt-get python-matplotlib: result" $? >> $logFilePath
#
#
#
#
#
#
#
#
########## 6) GPIO support
#
cat /etc/rc.local | grep -q write
HIGH_CURRENT_OUT_NOT_FOUND=$?
if [ $HIGH_CURRENT_OUT_NOT_FOUND -eq 1 ]; then
  echo "TinkerTech1 Setup: High current/GPS support not found in rc.local" >> $logFilePath
  sed -i.bak -e "s/^exit 0//" /etc/rc.local   # remove the exit 0 at end (not the one in the comment)
  echo "gpio -g mode 21 out   # GPS reset to output" >> /etc/rc.local
  echo "gpio -g write 21 0   # assert GPS reset" >> /etc/rc.local
  echo "gpio -g mode 17 out   # Fire A output" >> /etc/rc.local
  echo "gpio -g mode 22 out   # Fire B output" >> /etc/rc.local
  echo "gpio -g mode 23 out   # Fire C output" >> /etc/rc.local
  echo "gpio -g mode 24 out   # Fire D output" >> /etc/rc.local
  echo "gpio -g write 17 0   # Fire A set to zero" >> /etc/rc.local
  echo "gpio -g write 22 0   # Fire B set to zero" >> /etc/rc.local
  echo "gpio -g write 23 0   # Fire C set to zero" >> /etc/rc.local
  echo "gpio -g write 24 0   # Fire D set to zero" >> /etc/rc.local
  echo "gpio -g mode 25 out   # Arm clock set to output" >> /etc/rc.local
  echo "gpio -g write 25 0   # Arm clock set to zero" >> /etc/rc.local
  echo "gpio -g mode 16 out   # LED Shutdown Ack output" >> /etc/rc.local
  echo "gpio -g mode 6 out   # LED & Radio RF amplifier output" >> /etc/rc.local
  echo "gpio -g write 16 0   # LED Shutdown Ack off" >> /etc/rc.local
  echo "gpio -g write 6 0   # LED & Radio RF amplifier off" >> /etc/rc.local
  echo "gpio -g write 21 1   # release GPS reset" >> /etc/rc.local
  echo "gpio -g mode 5 in   # interrupt input" >> /etc/rc.local
  echo "gpio mode 5 up   # interrupt input" >> /etc/rc.local
  echo "gpio -g mode 12 in   # interrupt input" >> /etc/rc.local
  echo "gpio mode 12 up   # interrupt input" >> /etc/rc.local
  echo "gpio mode 2 up   # i2c input/output" >> /etc/rc.local
  echo "gpio mode 3 up   # i2c input/output" >> /etc/rc.local
  echo "gpio mode 9 up   # SPI MISO input" >> /etc/rc.local
  echo "gpio mode 20 up   # I2S input" >> /etc/rc.local
  echo "exit 0" >> /etc/rc.local
  echo "TinkerTech1 Setup: High current/GPS/RF/LED setup added to rc.local" >> $logFilePath
fi
#
#
echo "TinkerTech1 Setup: raspi-gpio get:" >> $logFilePath
raspi-gpio get  >> $logFilePath
#
#
#
#
########## 7) IMU (MPS9250) support
#
#
#
#
# First, tools to build all this...
# for libpifly and RTIMULib
apt-get -y install cmake
echo "TinkerTech1 Setup: apt-get -y install cmake: result" $? >> $logFilePath
#
#
# Second, Qt dependancies for demo programs
#
cd /home/pi/pifly
apt-get -y install qt4-dev-tools qt4-bin-dbg qt4-qtconfig qt4-default
#
if [ -d RTIMULib2 ]; then
  cd RTIMULib2
  echo "TinkerTech1 Setup: RTIMULib2 directory already exists, cd RTIMULib2: result" $? >> $logFilePath
  git pull
else
  git clone http://github.com/RTIMULib/RTIMULib2
  echo "TinkerTech1 Setup: git clone http://github.com/RTIMULib/RTIMULib2: result" $? >> $logFilePath
  cd RTIMULib2
fi
#chown -R pi:pi /home/pi/pifly/RTIMULib2     # because when this script is run with sudo, everything belongs to root
#
# build lib
echo "TinkerTech1 Setup: Starting RTIMULib library install" >> $logFilePath
cd RTIMULib
mkdir build
#chown -R pi:pi build
cd build
cmake ../ &>> $logFilePath
make &>> $logFilePath
make install &>> $logFilePath
#
# build demos
echo "TinkerTech1 Setup: Starting RTIMULib Demos install" >> $logFilePath
cd /home/pi/pifly/RTIMULib2/Linux/
mkdir build
#chown -R pi:pi /home/pi/pifly/RTIMULib2/
cd build
cmake ../ &>> $logFilePath
#chown -R pi:pi /home/pi/pifly/RTIMULib2/
make &>> $logFilePath
#chown -R pi:pi /home/pi/pifly/RTIMULib2/
make install &>> $logFilePath
ldconfig
#
#
#
chown -R pi:pi /home/pi/pifly/RTIMULib2     # because when this script is run with sudo, everything belongs to root
#
#
#
# Now copy the version of RTIMULib.ini for the pifly
cp /home/pi/piflySetupScript/RTIMULib.ini /home/pi/pifly/RTIMULib2/Linux/build/RTIMULibGL/CMakeFiles
#
#
#
#
#
########## 9) Developer tools
#
# Screen capture tool
echo "TinkerTech1 Setup: Starting scrot setup" >> $logFilePath
apt-get -y install scrot
echo "TinkerTech1 Setup: apt-getapt-get scrot: result" $? >> $logFilePath
#
#
#
# Python stuff
apt-get -y install python-smbus python3-smbus build-essential python-dev python3-dev python-picamera
echo "TinkerTech1 Setup: apt-get -y install python-smbus python3-smbus build-essential python-dev python3-dev: result" $? >> $logFilePath
#
#
#
# Install I2C tools    already in 2.8.2
#echo "TinkerTech1 Setup: Starting i2c-tools setup" >> $logFilePath
#apt-get -y install i2c-tools
#echo "TinkerTech1 Setup: apt-get install i2c-tools: result" $? >> $logFilePath
#
#
# To view serial data for GPS
# to use:
#    screen /dev/ttyAMA0 9600
apt-get -y install screen
echo "TinkerTech1 Setup: apt-get -y install screen: result" $? >> $logFilePath
#
#
#
#  GPS format conversion tool
apt-get -y install gpsbabel
echo "TinkerTech1 Setup: apt-get -y install gpsbabel: result" $? >> $logFilePath
#
#
# setserial serial port configuration/reporting utility
apt-get -y install setserial
echo "TinkerTech1 Setup: apt-get -y install setserial: result" $? >> $logFilePath
#
#
# Adafruit PCA9685 Python library
cd /home/pi/pifly
git clone https://github.com/adafruit/Adafruit_Python_PCA9685.git
cd Adafruit_Python_PCA9685
echo "TinkerTech1 Setup: cd Adafruit_Python_PCA9685: result" $? >> $logFilePath
python setup.py install
echo "TinkerTech1 Setup: python setup.py install: result" $? >> $logFilePath
cd /home/pi/pifly
chown -R pi:pi Adafruit_Python_PCA9685     # because when this script is run with sudo, everything belongs to root
#
#
# Setup a handy alias
echo "TinkerTech1 Setup: Starting ~/.bashrc appending for an alias" >> $logFilePath
echo "alias ll='ls -alh'"  >> /home/pi/.bashrc
echo "TinkerTech1 Setup: ~/.bashrc appending for an alias: result" $? >> $logFilePath
#
#
# Add the gpio man page
cd /home/pi/pifly
if [ -d wiringPi ]; then
  cd wiringPi
  git pull
  echo "TinkerTech1 Setup: git pull of wiringPi: result" $? >> $logFilePath
  cp gpio/gpio.1 /usr/local/man/man1
else
  git clone git://git.drogon.net/wiringPi
  echo "TinkerTech1 Setup: git clone of wiringPi: result" $? >> $logFilePath
  cp wiringPi/gpio/gpio.1 /usr/local/man/man1
fi
#
#
echo "" >> $logFilePath
echo "" >> $logFilePath
echo ""
echo ""
tput setaf 2      # highlight summary text green to make it more attention getting.
echo "TinkerTech1 Setup Script version" $TINKERTECH1SETUPVERSION
echo "Most software is installed under ~/tinkertech. These files were changed: /boot/cmdline.txt, /etc/rc.local, and /home/pi/.bashrc"
echo "Installed software: gpio, gpio-halt, gpio_alt, gpsbabel, scrot, screen, cmake, RTIMULib, and setserial."
echo "Installed Python libraries: python-picamera, matplotlib, python-smbus, python3-smbus, build-essential, python-dev, python3-dev, adafruit-pca9685, and RTIMULib2"
echo "Hardware shutdown can be done by grounding GPIO" $HALTGPIOBIT "using switch SW4"
echo "Added smbus (i2c) support to Python. ll alias setup in .bashrc."
df -PBMB | grep -E '^/dev/root' | awk '{ print "Free SD card space " $4 " of " $2 }'
df -PBMB | grep -E '^/dev/root' | awk '{ print "TinkerTech1 Setup: Free SD card space after install " $4 " of " $2 }' >> $logFilePath
echo "TinkerTech1 Setup: Install complete " $(date +"%A,  %B %e, %Y, %X %Z") >> $logFilePath
echo ""
#
# enable SW4 to do shutdown
/usr/local/bin/gpio-halt $HALTGPIOBIT &
tput setaf 5        # highlight text magenta
echo "You must re-boot for the changes to take effect, you can use button SW4 for this now. Remember to set country, time zone and enable i2c and spi in preferences."
tput setaf 7        # back to normal
echo "Install complete " $(date +"%A,  %B %e, %Y, %X %Z") >> $runlogFilePath

# 
