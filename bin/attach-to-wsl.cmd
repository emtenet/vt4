@echo off
rem Part of the procedures from
rem    https://learn.lushaylabs.com/os-toolchain-manual-installation/
echo "Attaching Tang Nano 9x USB to WSL"
usbipd attach -a -i 0403:6010 -w