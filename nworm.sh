#!/bin/bash

if [ "$nmap"!= "0" ]; then
    nmap -T5 -vv -Pn -p 25 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1
    http_servers=$(nmap -T5 -vv -Pn -p 80 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # http ports
    whatweb_scan=$($http_servers | httprobe)
    whatweb $whatweb_scan --no-errors 
    w3af_scan=$($http_servers | w3af | tee w3af &> /dev/null; grep "http server" w3af | awk '{print $3}' | cut -d '/' -f 1) # http servers
    xss_scan=$(xsser -v --list-xsser -a -p $http_servers | tee xsser &> /dev/null; grep "XSSer detected" xsser)
    rce_scan=$(rceer -v --list-rceer -a -p $http_servers | tee rceer &> /dev/null; grep "RCEer detected" rceer)
    if [ "$xss_scan"!= "" ] && [ "$rce_scan"!= "" ]; then
        echo "xsser and rceer vulnerabilities found:"
        echo "$xss_scan"
        echo "$rce_scan"

    smb=$(nmap -T5 -vv -Pn -p 445 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # smtp ports
    if [ "$smb"!= "0" ]; then
        $smb | smbprobe
    fi
    tftp=$(nmap -T5 -vv -Pn -p 69 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # tftp ports
    if [ "x$tftp"!= "x0" ]; then
        $tftp | tftp-enum-passwords
    fi
    ftp=$(nmap -T5 -vv -Pn -p 21 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # ftp ports
    if [ "x$ftp"!= "x0" ]; then
        $ftp | ftp-user-enum
    fi
    ssh=$(nmap -T5 -vv -Pn -p 22 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # ssh ports
    if [ "x$ssh"!= "x0" ]; then
        $ssh | ssh-keyscan -p 22
    fi
    telnet=$(nmap -T5 -vv -Pn -p 23 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # telnet ports
    if [ "x$telnet"!= "x0" ]; then
    	$telnet | telnet -e
    fi
    snmp=$(nmap -T5 -vv -Pn -p 161 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # snmp ports
    if [ "x$snmp"!= "x0" ]; then
    	$snmp | snmp-brute
    fi
