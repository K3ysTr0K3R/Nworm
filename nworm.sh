#!/bin/bash

function start_clear(){
	clear
}

current_directory='pwd'
if [ ls ${current_directory} | grep http_fuzzer_output.txt ]; true
	rm http_servers.txt
fi

nmap -T5 -vv -Pn -p 80 "$1"/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1 > http_servers.txt # http ports
start_clear
open_port_80='cat http_servers.txt'
echo "Found port 80 on $1/24 subnet range"
for port_80 in open_port_80
do
	echo "[+] Open port 80: $port_80"
done

cat http_servers.txt | httprobe > http_urls.txt # http probes
while read ips_url; do
	echo "HTTP/HTTPS 443/80 results stored in: http_fuzzer_output.txt"
	gobuster dir -u "$ips_url" i --no-error -w /usr/share/wordlists/dirb/common.txt -b "204,301,307,401,403,404,202,418,323,429" >> http_fuzzer_output.txt 
	echo "Checking for XSSER vulns"
	xss_scan=$(xsser -u "$ips_url" | tee xsser &> /dev/null; grep "XSSer detected" xsser)
	if [ "$xss_scan" ]; then
		echo "xsser vulnerabilities found:"
		echo "$xss_scan"
		echo "checking for sql injection vulns"
		sql_scan=$(sqlninja -s -d "$ips_url" | tee sqlninja &> /dev/null; grep "SQL injection detected" sqlninja)
		if [ "$sql_scan" ]; then
			echo "sql injection vulnerabilities found:"
			echo "$sql_scan"
		fi
	fi
done < http_urls.txt

smtp=$(nmap -T5 -vv -Pn -p 25 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # smtp ports
if [ "$smtp" ]; then
	echo "SMTP service is open for $smtp"
	echo "Enumerating SMTP users"
	smtp_user_scan=$(nmap -T4 -vv -sV -Pn $smtp--script=smtp-enum-users)
	if [ "$smtp_scan" ]; then
		echo "SMTP users found:"
		echo "$smtp_scan"
	fi
fi

smb=$(nmap -T4 -vv -Pn -p 445 --script smb-enum-shares | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # smb ports
if [ "$smb" ]; then
	echo "SMB service is open for $smb"
	echo ""
	echo "scanning SMB vulns"
	smb_vulns=$(nmap --script=smb-vuln* 38.6.21.154 -T4 -vv -p 445 -Pn)
	if [ "$smb_vulns" ]; then
		echo "SMB vulns found:"
		echo "$smb_vulns"
	fi
fi

dns=$(nmap -T4 -vv -Pn -p 53 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # dns ports
if [ "$dns" ]; then
	echo "DNS service is open for $dns"
fi
