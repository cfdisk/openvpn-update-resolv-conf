#!/usr/bin/env sh
#
# Parses DHCP options from openvpn to update resolv.conf
# To use set as 'up' and 'down' script in your openvpn *.conf:
# up /etc/openvpn/update-resolv-conf
# down /etc/openvpn/update-resolv-conf
#
# Used snippets of resolvconf script by Thomas Hood <jdthood@yahoo.co.uk>
# and Chris Hanson
# Licensed under the GNU GPL.  See /usr/share/common-licenses/GPL.
# 13/10/2017 cfdisk: added support for busybox shells (POSIX)
# 12/10/2017 cfdisk: added shell testmode
# 07/2013 colin@daedrum.net Fixed intet name
# 05/2006 chlauber@bnc.ch
#
# Example envs set from openvpn:

## The 'type' builtins will look for file in $PATH variable, so we set the
## PATH below. You might need to directly set the path to 'resolvconf'
## manually if it still doesn't work, i.e.
## RESOLVCONF=/usr/sbin/resolvconf

# disable ipv6= 1=disable 0=enable
DISABLE_IPV6=1;

# testmode for bash: just parse, dont run resolvconf
TESTMODE=1;
if [ $TESTMODE -ne 0 ]; then
    echo "Testmode"
    foreign_option_1='dhcp-option DNS 193.43.27.132'
    foreign_option_2='dhcp-option DNS 193.43.27.133'
    foreign_option_3='dhcp-option DOMAIN be.bnc.ch'
    foreign_option_4='dhcp-option DOMAIN-SEARCH bnc.local'
    script_type=up
    dev=tun0
fi
#####################################################################################

# store ipv6 setting
DEFAULT_DISABLE_IPV6=$(sysctl -n net.ipv6.conf.default.disable_ipv6)
ALL_DISABLE_IPV6=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

export PATH=$PATH:/sbin:/usr/sbin:/bin:/usr/bin
RESOLVCONF=$(type -p resolvconf)

tmpvars=`set |grep "foreign_option_"`
tmpvars=`echo $tmpvars | sed s/foreign_option_..//g |sed s/"'"//g`

count=0
for line in ${tmpvars}; do
    if [ `expr $count % 3` = 0 -a $count != 0 ]; then
        preoption=`/bin/echo -en "$preoption\n$line "`
    else
        preoption="$preoption$line "
    fi
    count=$(expr $count + 1)
done

case $script_type in
up)
    if [ $DISABLE_IPV6 -eq 1 ]; then
	echo "disable ipv6..."
	sysctl -w net.ipv6.conf.all.disable_ipv6=1
	sysctl -w net.ipv6.conf.default.disable_ipv6=1
    fi

    IFS=$'\n'

  for optionname in ${preoption} ; do
    option=${optionname}
    #echo "->>$option"
    part1=$(echo "$option" | cut -d " " -f 1)
    if [ "$part1" == "dhcp-option" ] ; then
      part2=$(echo "$option" | cut -d " " -f 2)
      part3=$(echo "$option" | cut -d " " -f 3)
      if [ "$part2" == "DNS" ] ; then
        IF_DNS_NAMESERVERS="$IF_DNS_NAMESERVERS $part3"
      fi
      if [[ "$part2" == "DOMAIN" || "$part2" == "DOMAIN-SEARCH" ]] ; then
        IF_DNS_SEARCH="$IF_DNS_SEARCH $part3"
      fi
    fi
  done
  unset IFS
  R=""
  if [ "$IF_DNS_SEARCH" ]; then
    R="search "
    for DS in $IF_DNS_SEARCH ; do
      R="${R} $DS"
    done
  R="${R}
"
  fi

  for NS in $IF_DNS_NAMESERVERS ; do
    R="${R}nameserver $NS
"
  done
  #echo -n "$R" | $RESOLVCONF -x -p -a "${dev}"
    if [ $TESTMODE -eq 0 ]; then
        echo -n "$R" | $RESOLVCONF -a "${dev}.inet"
    fi
    echo -n "$R"  ;;

down)
    if [ $TESTMODE -eq 0 ]; then
        $RESOLVCONF -d "${dev}.inet"
    fi
  ;;
esac

echo "restore ipv6 settings..."
sysctl -w net.ipv6.conf.all.disable_ipv6=$ALL_DISABLE_IPV6
sysctl -w net.ipv6.conf.default.disable_ipv6=$DEFAULT_DISABLE_IPV6

# Workaround / jm@epiclabs.io
# force exit with no errors. Due to an apparent conflict with the Network Manager
# $RESOLVCONF sometimes exits with error code 6 even though it has performed the
# action correctly and OpenVPN shuts down.
exit 0
