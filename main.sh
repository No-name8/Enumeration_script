#!/bin/bash

if which nmap > /dev/null; then
    echo "nmap is installed"
else
  sudo apt install -y nmap
fi
if which ncat > /dev/null; then
    echo "ncat is installed"
else
  sudo apt install -y ncat
fi
if which curl > /dev/null; then
    echo "curl is installed"
else
  sudo apt install -y curl
fi

echo "please enter the target ip address"
read -r target_ip

nmap -F "$target_ip" > nmap_r.txt

if  ! grep -q "open" nmap_r.txt;  then
    nmap "$target_ip" > nmap_r.txt
    if ! grep -q "open" nmap_r.txt;  then
        echo "no open ports found"
        
    elif  grep -q "open" nmap_r.txt;  
    then
        grep  'open' nmap_r.txt | cut -d '/' -f 1 | while read -r port; do
        nmap "$target_ip" -p- "$port" -sV > nmap_r.txt
    done
    fi 
fi

echo "if target is a web page, please enter the URL"
read -r target_url

if [ -z "$target_url" ]; then
    echo "No URL provided, skipping curl request."
else
    curl -s "$target_url"/robots.txt > curl_r.txt
fi

# print number of open ports

echo "scan results:"

echo "open ports:"
grep -oP '\d+/open' nmap_r.txt | cut -d '/' -f 1
echo "robots.txt:"
cat curl_r.txt 

if grep -q "telnet" nmap_r.txt | grep -q "ftp" nmap_r.txt | grep -q "ssh" nmap_r.txt | grep -q "smtp" nmap_r.txt | grep -q "http" nmap_r.txt | grep -q "https" nmap_r.txt; then
    echo "vulnerable ports:"
    grep -oP '\d+/open' nmap_r.txt | cut -d '/' -f 1 | while read -r port; do
        if [ "$port" == "23" ]; then
            echo "telnet"
        elif [ "$port" == "21" ]; then
            echo "ftp"
        elif [ "$port" == "22" ]; then
            echo "ssh"
        elif [ "$port" == "25" ]; then
            echo "smtp"
        elif [ "$port" == "80" ]; then
            echo "http"
        elif [ "$port" == "443" ]; then
            echo "https"
        fi
    done
fi


