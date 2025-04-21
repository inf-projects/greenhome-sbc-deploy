# Essential Tools Setup

## CLI Tools

```bash
sudo apt update
sudo apt install -y git feh vlc mpg321
```

## NVM

```bash
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
source ~/.bashrc
```

## Node.js

```bash
nvm install lts/erbium
nvm use lts/erbium
nvm alias default lts/erbium
```

## Yarn

```bash
npm install --global yarn
```

## PM2

```bash
yarn global add pm2
pm2 startup
```

