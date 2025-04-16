#!/bin/bash

set -e

SCRIPT_URL="https://raw.githubusercontent.com/tegrasw/conectasamu-installer/main/scripts/update-conectasamu.sh"
INSTALL_PATH="/usr/local/bin/update-conectasamu.sh"
SYSTEMD_DIR="/etc/systemd/system"
USER=$(logname)  # detecta usuário logado

# Dependências
sudo apt-get update
sudo apt-get install -y curl jq dpkg notify-osd

# Instalar script de atualização
sudo curl -sL "$SCRIPT_URL" -o "$INSTALL_PATH"
sudo chmod +x "$INSTALL_PATH"

# Salvar nome do usuário para notificação
sudo mkdir -p /etc/conectasamu-updater
echo "$USER" | sudo tee /etc/conectasamu-updater/user >/dev/null

# Criar systemd service
sudo tee "$SYSTEMD_DIR/conectasamu-updater.service" >/dev/null <<EOF
[Unit]
Description=Atualizador automático do ConectaSAMU
After=network.target

[Service]
ExecStart=$INSTALL_PATH
EOF

# Criar timer
sudo tee "$SYSTEMD_DIR/conectasamu-updater.timer" >/dev/null <<EOF
[Unit]
Description=Verifica atualizações do ConectaSAMU 2x ao dia

[Timer]
OnCalendar=08:00,20:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Ativar
sudo systemctl daemon-reexec
sudo systemctl enable --now conectasamu-updater.timer

# Executar uma vez imediatamente
"$INSTALL_PATH"
