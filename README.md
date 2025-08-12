# 🦎 Chameleon IP

A Bash script that automates IP rotation using the Tor network and logs geolocation data. Useful for anonymity, scraping, and bypassing geo-restrictions.

---

## 🚀 Features

- Changes IP using Tor's control port (`NEWNYM`)
- Displays current IP and location (country, region, city)
- Logs all activity to `tor_ip_changer.log`
- Installs required dependencies automatically
- Supports infinite or fixed number of IP changes
- Color-coded terminal output for clarity

---

## 📦 Requirements

- Linux (Debian/Ubuntu-based)
- `tor`, `curl`, `jq`, `socat`
- Tor must be configured to allow control port access

### 🔧 Tor Configuration

Edit `/etc/tor/torrc` and add:

ControlPort 9051 
CookieAuthentication 1


Then restart Tor:

sudo systemctl restart tor


## 📄 Installation

Clone the repo and run the script:

git clone https://github.com/MaxPi-Dude/Chameleon-IP.git

cd ChameleonIP

chmod +x ChameleonIP.sh

sudo ./ChameleonIP.sh


## 🧪 Example Output

[+] New IP: 185.220.101.1

[+] Location:

   Country: Germany
   
   Region: Bavaria
   
   City: Munich



