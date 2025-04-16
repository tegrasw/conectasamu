#!/bin/bash

set -e

# Caminhos dos arquivos
INSTALL_PATH="/usr/local/bin/update-conectasamu.sh"
CONFIG_DIR="/etc/conectasamu-updater"
SYSTEMD_DIR="/etc/systemd/system"

# Parar e desativar o serviço
echo "Parando e desativando o serviço de atualização..."
sudo systemctl stop conectasamu-updater.service
sudo systemctl disable conectasamu-updater.service

# Remover arquivos do systemd
echo "Removendo arquivos do systemd..."
sudo rm -f "$SYSTEMD_DIR/conectasamu-updater.service"
sudo rm -f "$SYSTEMD_DIR/conectasamu-updater.timer"

# Remover script de atualização
echo "Removendo script de atualização..."
sudo rm -f "$INSTALL_PATH"

# Remover diretório de configuração
echo "Removendo diretório de configuração..."
sudo rm -rf "$CONFIG_DIR"

# Recarregar systemd
echo "Recarregando systemd..."
sudo systemctl daemon-reload

echo "Desinstalação concluída com sucesso!" 
