#!/bin/sh

# 0-bhyve install script (C) 2022 Jim Salter and Klara Systems
#
# This script will install the packages and make the configuration
# changes necessary to give a freshly-installed FreeBSD 13.1 system
# a Gnome3 desktop, virtualization support, and the vm-bhyve CLI
# management system for new VMs.
#
# NOTE: script assumes the FreeBSD system was installed to a ZFS root
# pool named zroot. If you changed the pool name, adjust accordingly!

echo Updating package system...
pkg update

echo Installing GNOME3 desktop environment...
pkg install xorg gdm gnome-desktop

echo Configuring /etc/rc.conf for GNOME3 desktop environment...
sysrc gnome_enable="YES"
sysrc moused_enable="YES"
sysrc dbus_enable="YES"
sysrc hald_enable="YES"
sysrc gdm_enable="YES"

echo Enabling /proc filesystem...
echo "proc /proc procfs rw 0 0" >> /etc/fstab

echo Installing packages for vm-bhyve and reecho lated tools...
pkg install vm-bhyve tigervnc-viewer

echo Creating VM root on /zroot/bhyve...
zfs create zroot/bhyve
zfs set recordsize=64K zroot/bhyve
zfs create zroot/bhyve/.templates

echo Copying uefi.conf template from this directory to .templates...
cp ./uefi.conf /zroot/bhyve/.templates/uefi.conf

echo Adding support for virtualization to rc.conf and loader.conf...
echo 'vmm_load="YES"' >> /etc/loader.conf
sysrc vm_enable="YES"
sysrc vm_dir="zfs:zroot/bhyve"

echo Determining primary network interface...
IF=`route get 8.8.8.8 | grep interface | awk '{print $2}'`

echo Creating switch public on interface $IF...
vm init
vm switch create public
vm switch add public $IF

echo Congratulations! Your FreeBSD system should be ready to boot
echo to a GNOME3 desktop and start running Bhyve guests now.
echo 
echo However, you probably still need to manually install the correct
echo video driver for your system. To find the correct package, look
echo for your GPU hardware in the output of pkg search xf86-video. Once
echo you\'ve found the correct driver package, pkg install xf86-video-\<yourcard\>
echo and reboot the system with shutdown -r now.
