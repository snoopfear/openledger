#!/bin/bash

# Проверяем, запущен ли скрипт от имени root
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт с правами root (sudo)"
  exit 1
fi

echo "Удаляем старые версии Docker..."
sudo apt remove -y docker docker-engine docker.io containerd runc

echo "Устанавливаем зависимости для Docker..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

echo "Добавляем GPG-ключ Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "Добавляем репозиторий Docker..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Обновляем пакеты и устанавливаем Docker..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

echo "Проверяем версию Docker..."
sudo docker --version

echo "Устанавливаем зависимости для OpenLedger..."
sudo apt update
sudo apt install -y libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libsecret-1-0 unzip screen desktop-file-utils

echo "Скачиваем и устанавливаем OpenLedger..."
wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip -O openledger-node.zip
unzip openledger-node.zip
sudo dpkg -i openledger-node-1.0.0.deb
sudo apt-get install -f -y

echo "Устанавливаем дополнительные зависимости..."
sudo apt-get install -y libgbm1 libasound2

echo "Создаем systemd сервис для OpenLedger..."
cat <<EOF | sudo tee /etc/systemd/system/openledger-node.service
[Unit]
Description=OpenLedger Node
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/openledger-node
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Перезапускаем systemd и включаем сервис..."
sudo systemctl daemon-reload
sudo systemctl enable openledger-node.service
sudo systemctl start openledger-node.service

echo "Выводим логи сервиса OpenLedger..."
sudo journalctl -u openledger-node.service -f
