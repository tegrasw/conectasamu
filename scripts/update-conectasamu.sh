#!/bin/bash

REPO="tegrasw/conectasamu-installer"
PACKAGE_NAME="conectasamu"
FILENAME="conectasamu.deb"
TMP_DIR="/tmp/conectasamu-update"
NOTIFY_USER_FILE="/etc/conectasamu-updater/user"

function error_exit {
    echo "❌ Erro: $1"
    exit 1
}

# Verificações básicas
command -v jq >/dev/null || error_exit "Instale o 'jq'"
command -v curl >/dev/null || error_exit "Instale o 'curl'"
command -v dpkg-deb >/dev/null || error_exit "Instale o 'dpkg-deb'"

mkdir -p "$TMP_DIR"

# Buscar última versão
RELEASE_DATA=$(curl -s "https://api.github.com/repos/$REPO/releases/latest") || error_exit "Erro ao acessar GitHub"
LATEST_TAG=$(echo "$RELEASE_DATA" | jq -r ".tag_name" | sed 's/^v//')
DOWNLOAD_URL=$(echo "$RELEASE_DATA" | jq -r ".assets[] | select(.name==\"$FILENAME\") | .browser_download_url")
[ -z "$DOWNLOAD_URL" ] && error_exit "Release não contém o arquivo $FILENAME"

# Ver versão atual
INSTALLED_VERSION=$(dpkg-query -W -f='${Version}' "$PACKAGE_NAME" 2>/dev/null || echo "nenhuma")

if [ "$INSTALLED_VERSION" == "$LATEST_TAG" ]; then
    echo "✅ Já está na versão $LATEST_TAG"
    exit 0
elif [ "$INSTALLED_VERSION" == "nenhuma" ]; then
    echo "📦 Instalando $PACKAGE_NAME pela primeira vez..."
else
    echo "⬆️ Atualizando de $INSTALLED_VERSION para $LATEST_TAG..."
fi

# Baixar
DEB_PATH="$TMP_DIR/$FILENAME"
curl -L -o "$DEB_PATH" "$DOWNLOAD_URL" || error_exit "Erro no download"

# Verificar arquitetura
PKG_ARCH=$(dpkg-deb --field "$DEB_PATH" Architecture)
SYS_ARCH=$(dpkg --print-architecture)
if [ "$PKG_ARCH" != "$SYS_ARCH" ]; then
    error_exit "Arquitetura incompatível: pacote é '$PKG_ARCH', sistema é '$SYS_ARCH'"
fi

# Instalar
if ! sudo dpkg -i "$DEB_PATH"; then
    sudo apt-get install -f -y || error_exit "Falha ao corrigir dependências"
fi

# Verificação final
POST_VERSION=$(dpkg-query -W -f='${Version}' "$PACKAGE_NAME" 2>/dev/null || echo "nenhuma")
if [ "$POST_VERSION" != "$LATEST_TAG" ]; then
    error_exit "Instalação falhou. Versão instalada: $POST_VERSION"
fi

# Notificação apenas se houve mudança
if [ "$INSTALLED_VERSION" != "$POST_VERSION" ] && [ -f "$NOTIFY_USER_FILE" ]; then
  NOTIFY_USER=$(cat "$NOTIFY_USER_FILE")
  USER_ID=$(id -u "$NOTIFY_USER")
  export DISPLAY=:0
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"
  notify-send "ConectaSAMU atualizado" "Quando possível, feche e reabra o aplicativo."
fi

echo "✅ Atualização concluída para versão $POST_VERSION"
