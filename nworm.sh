#!/bin/bash

echo "Scanning $1 for SMTP"
smtp=$(nmap -T5 -vv -Pn -p 25 $1/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1) # smtp ports
echo "Found port 25 on $1/24 subnet range"
for check_port_25 in $smtp; do
	echo "[+] Open port 25 on $smtp"
done
if [ "$smtp" ]; then
	echo "SMTP service is open for $smtp"
	echo "Enumerating SMTP users"
	smtp_user_scan=$(nmap -T4 -vv -sV -Pn $smtp--script=smtp-enum-users)
	if [ "$smtp_scan" ]; then
		echo "SMTP users found:"
		echo "$smtp_scan"
	fi
fi

port_80_check=$(nmap -T5 -vv -Pn -p 80 "$1"/24 | tee nmap &> /dev/null; grep "open" nmap | awk '{print $6}' | cut -d '/' -f 1 > http_servers.txt) # http ports
clear
	open_port_80=$(cat http_servers.txt)
	echo ""
	echo "Found port 80 on $1/24 subnet range"
	for port_80 in $open_port_80
	do
		echo "[+] Open port 80 on $port_80"
	done

echo ""
cat http_servers.txt | httprobe > http_urls.txt # http probes
echo "Fuzzing $1 subnet"
while read ips_url; do
	gobuster dir -u "$ips_url" --no-error -t 50 -w /usr/share/wordlists/dirb/common.txt -b "204,301,307,401,403,404,202,418,323,429,503" >> http_fuzzer_output.txt
done < http_urls.txt

echo "HTTP/HTTPS 443/80 results stored in: http_fuzzer_output.txt"
