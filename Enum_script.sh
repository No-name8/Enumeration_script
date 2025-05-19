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
if which enum4linux > /dev/null; then
    echo "enum4linux is installed"
else
  sudo apt install -y enum4linux
fi
if which subfinder > /dev/null; then
    echo "subfinder is installed"
else
    sudo apt install -y subfinder
fi
if which assetfinder > /dev/null; then
    echo "assetfinder is installed"
else
    sudo apt install -y assetfinder
fi 
if which httpx > /dev/null; then
    echo "httpx is installed"
else
    sudo apt install -y httpx
fi
if which ffuf > /dev/null; then
    echo "ffuf is installed"
else
    sudo apt install -y ffuf
fi
if find n0kovo_subdomains_medium.txt > /dev/null; then
    echo "n0kovo_subdomains_medium.txt is present"
else
    wget https://raw.githubusercontent.com/n0kovo/n0kovo_subdomains/refs/heads/main/n0kovo_subdomains_medium.txt
fi
echo "How would you like to enumerate the target?"
echo "1. port scan"
echo "2. webpage enumeration"
echo "3. Both"

read -r choice
case $choice in 
    1)
        port_scan=1
        web_enum=0
        ;;
    2)
        port_scan=0
        web_enum=1
        ;;
    3)
        port_scan=1
        web_enum=1
        ;;
    *)
        echo "Invalid choice, exiting."
        exit 1
        ;;
esac


echo "enter target name"
read -r target_name

if [ -z "$target_name" ]; then
    echo "No target name provided, exiting."
    exit 1
fi

mkdir -p "$target_name"

if [ $port_scan -eq 1 ]; then
    echo "please enter the target ip address"
    read -r target_ip
    if [ $port_scan -eq 1 ]; then
        nmap -F "$target_ip" > nmap_"$target_name".txt
        if  ! grep -q "open" nmap_"$target_name".txt;  then
                nmap "$target_ip" > nmap_"$target_name".txt
                if ! grep -q "open" nmap_"$target_name".txt;  then
                    nmap "$target_ip" -p- > nmap_"$target_name".txt
                    if ! grep -q "open" nmap_"$target_name".txt; then
                    echo "no open ports found"
                    exit 1 
                    fi
                fi
        elif  grep -q "open" nmap_"$target_name".txt;  
        then
            grep  'open' nmap_"$target_name".txt | cut -d '/' -f 1 | while read -r port; do
            nmap "$target_ip" -p- "$port" -sV >> nmap_"$target_name".txt
        done
        fi 
    fi
fi

if [ $web_enum -eq 1 ]; then
    echo "if target is a web page, please enter the URL " 
    echo "please enter the target URL in the format http://example.com"  
    read -r target_url

    if [ -z "$target_url" ]; then
        echo "No URL provided, skipping curl request."
        else
        curl -s "$target_url"/robots.txt > curl_"$target_name".txt
        subfinder -d "$target_url" > subfinder_"$target_name".txt
        assetfinder --subs-only "$target_url" > assetfinder_"$target_name".txt
        cat subfinder_"$target_name".txt assetfinder_"$target_name".txt | sort -u > all_subs_"$target_name".txt
        if  wc -l all_subs_"$target_name".txt -lt 1 ; then
            ffuf -u "$target_url"/FUZZ -w n0kovo_subdomains_medium.txt -o ffuf_"$target_name".txt -mc 200,204,301,302,307 
            if  wc -l ffuf_"$target_name".txt -lt 1 ; then
                # shellcheck disable=SC2002
                subdomains=$(cat all_subs_"$target_name".txt | wc -l)
                echo "no live subdomains found, total subdomains: $subdomains"
            else
            cat all_subs_"$target_name".txt ffuf_"$target_name" | sort -u > all_subs_"$target_name".txt 
            fi
        fi
        httpx -l all_subs_"$target_name".txt -o alive_subs_"$target_name".txt
        rm -rf subfinder_"$target_name".txt assetfinder_"$target_name".txt  
    fi
fi
# print number of open ports

echo "scan results:"

if [ $port_scan -eq 1 ]; 
then
    echo "open ports:"
    grep -oP '\d+/open' nmap_"$target_name".txt | cut -d '/' -f 1 > open_ports_"$target_name".txt
    echo "total open ports: $(grep -oP '\d+/open' nmap_"$target_name".txt | cut -d '/' -f 1 | wc -l)"

    if grep -q "445" open_ports_"$target_name".txt; then 
    
    enum4linux "$target_ip" > enumsmb_"$target_name".txt
    elif grep -q "139" open_ports_"$target_name".txt; 
    then
        enum4linux "$target_ip" > enumsmb_"$target_name".txt
    fi

    if  grep -q "2049" open_ports_"$target_name".txt ; then
        showmount -e "$target_ip" > nfs_"$target_name".txt
        fi
fi
