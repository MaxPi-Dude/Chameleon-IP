#!/bin/bash

# ANSI color codes
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[92m"
YELLOW="\033[93m"
RED="\033[91m"

LOG_FILE="ChameleonIP.log"

# Check if the user is running as root or with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW} Please run this tool as root or with sudo${RESET}"
        exit 1
    fi
}

# Log messages to file
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check and install dependencies from requirements.txt
install_dependencies() {
    echo -e "${GREEN}[+] Checking dependencies...${RESET}"

    if [ ! -f requirements.txt ]; then
        echo -e "${RED}[!] requirements.txt not found.${RESET}"
        exit 1
    fi

    while IFS= read -r pkg || [ -n "$pkg" ]; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            echo -e "${RED}[!] $pkg is not installed. Installing...${RESET}"
            sudo apt update && sudo apt install "$pkg" -y
            echo -e "${GREEN}[+] $pkg installed successfully.${RESET}"
        else
            echo -e "${GREEN}[+] $pkg is already installed.${RESET}"
        fi
    done < requirements.txt
}

# Display banner
display_banner() {
    clear
    echo -e "${RED}${BOLD}"
    cat << "EOF"
     
   _____ _                          _                    _____ _____  
  / ____| |                        | |                  |_   _|  __ \ 
 | |    | |__   __ _ _ __ ___   ___| | ___  ___  _ __     | | | |__) |
 | |    | '_ \ / _` | '_ ` _ \ / _ | |/ _ \/ _ \| '_ \    | | |  ___/ 
 | |____| | | | (_| | | | | | |  __| |  __| (_) | | | |  _| |_| |     
  \_____|_| |_|\__,_|_| |_| |_|\___|_|\___|\___/|_| |_| |_____|_|     
                                                                     

  Developer: MaxPi-Dude                                  Version: 1.6
                                                                        
EOF
    echo -e "${RESET}${YELLOW}* GitHub: https://github.com/MaxPi-Dude/${RESET}"
    echo
    echo -e "${GREEN}Change your SOCKS to 127.0.0.1:9050${RESET}"
    echo
}

# Start Tor service
start_tor() {
    echo -e "${GREEN}[+] Starting Tor service...${RESET}"
    if command -v systemctl >/dev/null; then
        sudo systemctl start tor
    else
        sudo service tor start
    fi
    echo -e "${GREEN}[+] Tor service started.${RESET}"
    log "Tor service started"
}

# Stop Tor service
stop_tor() {
    echo -e "${RED}[!] Stopping Tor service...${RESET}"
    if command -v systemctl >/dev/null; then
        sudo systemctl stop tor
    else
        sudo service tor stop
    fi
    echo -e "${RED}[!] Tor service stopped.${RESET}"
    log "Tor service stopped"
    exit 0
}

# Handle script termination
trap stop_tor SIGINT SIGTERM

# Change identity using Tor control port
change_identity() {
    echo -e "${YELLOW}[~] Requesting new identity...${RESET}"
    echo -e 'AUTHENTICATE ""\r\nSIGNAL NEWNYM\r\nQUIT\r\n' | socat - TCP4:127.0.0.1:9051
    echo -e "${YELLOW}[~] Identity changed.${RESET}"
    log "Tor identity changed"
}

# Fetch external IP and location
fetch_ip_and_location() {
    local ip country region city

    ip=$(curl --silent --socks5-hostname 127.0.0.1:9050 http://httpbin.org/ip | jq -r .origin 2>/dev/null)

    if [ -z "$ip" ]; then
        echo -e "${RED}Error: Unable to fetch IP.${RESET}"
        log "Failed to fetch IP"
    else
        location=$(curl --silent --socks5-hostname 127.0.0.1:9050 "https://ipapi.co/$ip/json/" | jq -r '.country_name, .region, .city')

        country=$(echo "$location" | sed -n '1p')
        region=$(echo "$location" | sed -n '2p')
        city=$(echo "$location" | sed -n '3p')

        echo -e "${GREEN}[+] New IP: $ip${RESET}"
        echo -e "${GREEN}[+] Location:${RESET}"
        echo -e "${GREEN}   Country: $country${RESET}"
        echo -e "${GREEN}   Region: $region${RESET}"
        echo -e "${GREEN}   City: $city${RESET}"

        log "New IP: $ip | Country: $country | Region: $region | City: $city"
    fi
}

# Main function
main() {
    display_banner
    start_tor

    echo -ne "${YELLOW}[+] Enter interval (seconds) between IP changes [default: 60]: ${RESET}"
    read -r interval
    interval=${interval:-60}

    echo -ne "${YELLOW}[+] Enter number of IP changes (0 for infinite): ${RESET}"
    read -r cycles
    cycles=${cycles:-0}

    if [[ "$cycles" -eq 0 ]]; then
        echo -e "${GREEN}[+] Infinite mode activated. Press Ctrl+C to stop.${RESET}"
        while true; do
            change_identity
            sleep "$interval"
            fetch_ip_and_location
        done
    else
        for ((i = 1; i <= cycles; i++)); do
            change_identity
            sleep "$interval"
            fetch_ip_and_location
        done
    fi
}

# Run the script
check_sudo
install_dependencies
main
