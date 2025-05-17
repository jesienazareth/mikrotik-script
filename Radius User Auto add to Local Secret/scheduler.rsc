# ==========================================================
# Script Name : PPPoE Auto User Creator
# Description : Automatically creates PPPoE users from a Active tab area
# Author      : jesienazareth
# Version     : v1.0, 2025-05-17
# Target      : MikroTik RouterOS 7.x+
# Usage       : Import to System > Scripts or run via terminal
# ==========================================================
/system scheduler
add interval=6h name=Auto-PPPoE-User-Creation on-event=\
    Auto-PPPoE-User-Creation policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
