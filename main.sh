#!/bin/bash
SysName=""
SysCount=""
 
[[ $(id -u) != '0' ]] && echo '[Error] Please use root to run this script.' && exit;
egrep -i "centos" /etc/issue && SysName='centos';
egrep -i "debian" /etc/issue && SysName='debian';
egrep -i "ubuntu" /etc/issue && SysName='ubuntu';
[[ "$SysName" == '' ]] && echo '[Error] Your system is not supported this script' && exit;
SysBit='32' && [ `getconf WORD_BIT` == '32' ] && [ `getconf LONG_BIT` == '64' ] && SysBit='64';
CpuNum=`cat /proc/cpuinfo |grep 'processor'|wc -l`;
RamTotal=`free -m | grep 'Mem' | awk '{print $2}'`;
RamSwap=`free -m | grep 'Swap' | awk '{print $2}'`;
RamSum=$[$RamTotal+$RamSwap];
FileMax=`cat /proc/sys/fs/file-max`
OSlimit=`ulimit -n`
ADMINUSER_ADD(){
    AdminUser=""
    AdminPwd=""
    [[ "$AdminUser" == '' ]] && echo "Please input AdminUser's name:";read AdminUser
    [[ "$AdminPwd" == '' ]] && echo "Please input AdminUser's password:";read AdminPwd
    useradd -G sudo -d /home/$AdminUser -m -N -s /bin/bash $AdminUser
    echo "$AdminPwd" |passwd --stdin $AdminUser
}
INSTALL_BASE_PACKAGES(){
    if [ "$SysName" == 'centos' ]; then
        echo '[yum-fastestmirror Installing] ************************************************** >>';
        [[ "$SysCount" == '' ]] && yum -y install yum-fastestmirror && SysCount="1"
        cp /etc/yum.conf /etc/yum.conf.back
        sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf
        for arg do
            echo "[${arg} Installing] ************************************************** >>";
            yum -y install $arg; 
        done;
        mv -f /etc/yum.conf.back /etc/yum.conf;
    else
        [[ "$SysCount" == '' ]] && apt-get update && SysCount="1"
        for arg do
            echo "[${arg} Installing] ************************************************** >>";
            apt-get install -y $arg --force-yes;apt-get -fy install;apt-get -y autoremove; 
        done;
    fi;
}
SYSTEM_BASE_PACKAGES(){
    [ "$SysName" == 'centos' ] && BasePackages="wget crontabs iptables logrotate openssl expect" || BasePackages="ntp logrotate wget cron curl openssl expect"
    INSTALL_BASE_PACKAGES $BasePackages
}
TIMEZONE_SET(){
    rm -rf /etc/localtime;
    ln -s /usr/share/zoneinfo/Asia/Chongqing /etc/localtime;
    echo '[ntp Installing] ******************************** >>';
    [ "$SysName" == 'centos' ] && yum install -y ntp || apt-get install -y ntpdate;
    ntpdate -u pool.ntp.org;
    echo "0 * * * * /usr/sbin/ntpdate cn.pool.ntp.org >> /dev/null 2>&1 ;hwclock -w" >> /etc/crontab
    [ "$SysName" == 'centos' ] && /etc/init.d/crond restart || /etc/init.d/cron restart
}
BASE_OS_SET(){
# EOF **********************************
    cat >> /etc/sysctl.conf <<EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 1
#net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 1024 65000
EOF
# **************************************
    sysctl -p
# EOF **********************************
    cat >> /etc/security/limits.conf << EOF
*                     soft     nofile             `expr $FileMax / 4`
*                     hard     nofile             `expr $FileMax / 2`
EOF
# **************************************
}
SELECT_SYSTEM_BASE_FUNCTION(){
    clear;
    echo "[Notice] Which system_base_function you want to run:"
    select var in "Admin user add" "System base packages install" "Timezone set" "System core set" "back";do
        case $var in
            "Admin User Add")
                ADMINUSER_ADD;;
            "System base packages install")
                SYSTEM_BASE_PACKAGES;;
            "Timezone set")
                TIMEZONE_SET;;
            "System core set")
                BASE_OS_SET;;
            "back")
                SELECT_RUN_SCRIPT;;
            *)
                SELECT_SYSTEM_BASE_FUNCTION;;
        esac
        break
    done
}

#**********************************************************

