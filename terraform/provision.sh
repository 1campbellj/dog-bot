#!/usr/bin/env bash
set -euo pipefail

# install geckodriver
GECKO_VERSION=v0.23.0
wget https://github.com/mozilla/geckodriver/releases/download/$GECKO_VERSION/geckodriver-$GECKO_VERSION-linux64.tar.gz
sudo sh -c "tar -x geckodriver -zf geckodriver-$GECKO_VERSION-linux64.tar.gz -O > /usr/bin/geckodriver"
sudo chmod +x /usr/bin/geckodriver
rm geckodriver-$GECKO_VERSION-linux64.tar.gz

# deps from apt: for clojure and ff for scraping
sudo apt-get update -y
sudo apt install -y default-jre rlwrap firefox

# install clojure itself
curl -O https://download.clojure.org/install/linux-install-1.10.1.536.sh
chmod +x linux-install-1.10.1.536.sh
sudo ./linux-install-1.10.1.536.sh

# DO metrics agent
curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash
