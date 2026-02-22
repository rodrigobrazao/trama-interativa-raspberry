#!/bin/bash
# ═══════════════════════════════════════════
# TRAMA — Instalação para Raspberry Pi
# Versão browser (Chromium kiosk mode)
# ═══════════════════════════════════════════

echo "═══════════════════════════════════════════"
echo "  TRAMA — Setup Raspberry Pi"
echo "═══════════════════════════════════════════"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Instalar Chromium se necessário
echo "[1/4] A verificar Chromium..."
sudo apt-get update -y
sudo apt-get install -y chromium-browser unclutter

# Desativar screensaver
echo "[2/4] A desativar screensaver..."
sudo apt-get install -y xdotool xscreensaver 2>/dev/null || true
# Desabilitar blank screen
sudo raspi-config nonint do_blanking 1 2>/dev/null || true

# Criar script de arranque
echo "[3/4] A criar script de arranque..."
cat > "$SCRIPT_DIR/start.sh" << STARTEOF
#!/bin/bash
# TRAMA — Arranque automático
sleep 5

# Desativar screensaver e cursor
export DISPLAY=:0
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true
unclutter -idle 0.5 -root &

# Fechar Chromium se estiver aberto
pkill -f chromium 2>/dev/null || true
sleep 1

# Abrir Chromium em modo kiosk (fullscreen, sem barra)
chromium-browser \\
  --kiosk \\
  --noerrdialogs \\
  --disable-infobars \\
  --disable-session-crashed-bubble \\
  --disable-restore-session-state \\
  --disable-features=TranslateUI \\
  --check-for-update-interval=31536000 \\
  --autoplay-policy=no-user-gesture-required \\
  --use-fake-ui-for-media-stream \\
  --enable-features=WebRTC \\
  --allow-file-access-from-files \\
  "file://$SCRIPT_DIR/index.html" &
STARTEOF
chmod +x "$SCRIPT_DIR/start.sh"

# Criar serviço systemd
echo "[4/4] A criar serviço systemd..."
sudo tee /etc/systemd/system/trama.service > /dev/null << SERVICEEOF
[Unit]
Description=TRAMA Instalação Interativa
After=graphical.target
Wants=graphical.target

[Service]
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
WorkingDirectory=$SCRIPT_DIR
ExecStart=/bin/bash $SCRIPT_DIR/start.sh
ExecStop=/usr/bin/pkill -f chromium
Restart=always
RestartSec=10
User=pi

[Install]
WantedBy=graphical.target
SERVICEEOF

echo ""
echo "═══════════════════════════════════════════"
echo "  Instalação completa!"
echo ""
echo "  Testar:      ./start.sh"
echo "  Auto-start:  sudo systemctl enable trama"
echo "  Parar:       sudo systemctl stop trama"
echo "  Desativar:   sudo systemctl disable trama"
echo ""
echo "  NOTA: A webcam precisa de permissão."
echo "  O --use-fake-ui-for-media-stream"
echo "  aceita automaticamente o acesso à câmara."
echo "═══════════════════════════════════════════"
