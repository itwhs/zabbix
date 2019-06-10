#!/bin/bash
if (whiptail --title "install lamp+zabbix or lnmp+zabbix" --yes-button "lamp+zabbix" --no-button "lnmp+zabbix"  --yesno "What do you want to install?" 10 60) then
    bash lampzbx.sh
else
    bash lnmpzbx.sh
fi
