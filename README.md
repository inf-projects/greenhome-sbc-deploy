# README

## Environment Setup

Using **Raspberry Pi OS (Legacy) with desktop** based on **Debian 11**

### CLI Tools

```bash
sudo apt update
sudo apt install -y git feh vlc mpg321 unzip
```

### NVM

```bash
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
source ~/.bashrc
```

### Node.js

```bash
nvm install lts/erbium
nvm use lts/erbium
nvm alias default lts/erbium
```

### Yarn

```bash
npm install --global yarn
```

### PM2

```bash
npm install -g pm2
```

Set PM2 start with system

```
pm2 startup
```

Install [pm2-logrotate](https://github.com/keymetrics/pm2-logrotate)

```
pm2 install pm2-logrotate
```

### Additional config

- Enable screen blanking
- Enable auto-hide for menubar


## Environment Check

Clone the repository and run the following command to check if everything is set up correctly.

```bash
git clone https://github.com/inf-projects/greenhome-sbc-deploy.git
```

## Deploy

Unzip build

```
unzip sbc-server_*.zip -d sbc-server
```
