#!/bin/bash

if [ "$nmap"!= "0" ]; then
    nmap -T5 -vv -Pn -p 25 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1
    http_servers=$(nmap -T5 -vv -Pn -p 80 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # http ports
    whatweb_scan=$($http_servers | httprobe)
    whatweb $whatweb_scan --no-errors | tee whatweb_scan_nmap &> /dev/null
    gobuster dir -u $A --no-error -w /usr/share/wordlists/dirb/common.txt -b "204,301,307,401,403,404,202,418,323" > http_fuzzer_output.txt 
    echo "HTTP/HTTPS 443/80 results stored in: whatweb_scan_nmap"
    echo "Checking for XSSER vulns"
    xss_scan=$(xsser -v --list-xsser -a -p $http_servers | tee xsser &> /dev/null; grep "XSSer detected" xsser)
    if [ "$xss_scan"!= "" ]; then
        echo "xsser vulnerabilities found:"
        echo "$xss_scan"
    echo "checking for sql injection vulns"
    sql_scan=$(sqlninja -s -d $whatweb_scan | tee sqlninja &> /dev/null; grep "SQL injection detected" sqlninja)
    if [ "$sql_scan"!= "" ]; then
        echo "sql injection vulnerabilities found:"
        echo "$sql_scan"
    fi
fi

smtp=$(nmap -T5 -vv -Pn -p 25 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # smtp ports
if [ "$smtp"!= "" ]; then
    echo "SMTP service is open for $smtp"
    echo "Enumerating SMTP users"
    smtp_user_scan=$(nmap -T4 -vv -sV -Pn $smtp--script=smtp-enum-users)
    if [ "$smtp_scan"!= "" ]; then
        echo "SMTP users found:"
        echo "$smtp_scan"
    fi
fi
