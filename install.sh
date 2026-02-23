#!/bin/bash
# ═══════════════════════════════════════════
# TRAMA — Instalação para Raspberry Pi
# Pi OS Desktop (Bookworm) + user rbpy
# ═══════════════════════════════════════════

set -e

echo "═══════════════════════════════════════════"
echo "  TRAMA — Setup Raspberry Pi (Desktop)"
echo "═══════════════════════════════════════════"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USER_HOME="/home/rbpy"

# [1/7] Instalar pacotes necessários
echo "[1/7] A instalar pacotes..."
sudo apt-get update -qq
sudo apt-get install -y unclutter v4l-utils python3

# [2/7] Desativar screensaver / blank screen
echo "[2/7] A desativar screensaver e blank screen..."
sudo raspi-config nonint do_blanking 1 2>/dev/null || true

# Desativar screensaver do LXDE
mkdir -p "${USER_HOME}/.config/lxsession/LXDE-pi"
cat > "${USER_HOME}/.config/lxsession/LXDE-pi/autostart" << 'LXEOF'
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xset s off
@xset -dpms
@xset s noblank
@unclutter -idle 0.5 -root
@bash /home/rbpy/trama/start.sh
LXEOF

# [3/7] Aumentar GPU memory
echo "[3/7] A configurar GPU memory..."
CONFIG_FILE="/boot/firmware/config.txt"
[ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="/boot/config.txt"
if ! grep -q 'gpu_mem=128' "$CONFIG_FILE" 2>/dev/null; then
  echo 'gpu_mem=128' | sudo tee -a "$CONFIG_FILE"
fi

# [4/7] Configurar auto-login (Pi OS Desktop já faz auto-login, mas garantir)
echo "[4/7] A verificar auto-login..."
sudo raspi-config nonint do_boot_behaviour B4 2>/dev/null || true

# [5/7] Criar server.py (HTTP com MIME types corretos para WASM)
echo "[5/7] A criar server HTTP..."
cat > "${SCRIPT_DIR}/server.py" << 'SERVEREOF'
#!/usr/bin/env python3
"""TRAMA HTTP Server - serves files with correct MIME types for WASM"""
import http.server
import socketserver
import os
import signal
import sys

PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class WASMHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        '.wasm': 'application/wasm',
        '.js': 'application/javascript',
        '.mjs': 'application/javascript',
        '.json': 'application/json',
        '.data': 'application/octet-stream',
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def log_message(self, format, *args):
        pass  # Silent

def signal_handler(sig, frame):
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

with socketserver.TCPServer(("", PORT), WASMHandler) as httpd:
    httpd.allow_reuse_address = True
    print(f"TRAMA server: http://localhost:{PORT}")
    httpd.serve_forever()
SERVEREOF
chmod +x "${SCRIPT_DIR}/server.py"

# [6/7] Criar script de arranque (server + Chromium kiosk)
echo "[6/7] A criar script de arranque..."
cat > "${SCRIPT_DIR}/start.sh" << 'STARTEOF'
#!/bin/bash
# TRAMA — Arranque (server HTTP + Chromium kiosk)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export DISPLAY=:0

# Matar processos anteriores
pkill -f "python3.*server.py" 2>/dev/null || true
pkill -f "chromium.*trama" 2>/dev/null || true
sleep 1

# Iniciar server HTTP
python3 "${SCRIPT_DIR}/server.py" &
SERVER_PID=$!
sleep 2

# Verificar se server está a correr
if ! kill -0 $SERVER_PID 2>/dev/null; then
  echo "ERRO: Server HTTP não arrancou!"
  exit 1
fi

# Iniciar Chromium kiosk
chromium-browser \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-restore-session-state \
  --disable-features=TranslateUI \
  --check-for-update-interval=31536000 \
  --autoplay-policy=no-user-gesture-required \
  --use-fake-ui-for-media-stream \
  --enable-features=WebRTC \
  --disable-gpu \
  --num-raster-threads=2 \
  --disable-software-rasterizer \
  --disable-dev-shm-usage \
  --no-sandbox \
  "http://localhost:8080/index.html" &

echo "TRAMA iniciado! (server PID: $SERVER_PID)"
STARTEOF
chmod +x "${SCRIPT_DIR}/start.sh"

# Script para parar
cat > "${SCRIPT_DIR}/stop.sh" << 'STOPEOF'
#!/bin/bash
# TRAMA — Parar
pkill -f "python3.*server.py" 2>/dev/null || true
pkill -f "chromium.*kiosk" 2>/dev/null || true
echo "TRAMA parado."
STOPEOF
chmod +x "${SCRIPT_DIR}/stop.sh"

# [7/8] Criar atalho no Desktop
echo "[7/8] A criar atalho no Desktop..."
mkdir -p "${USER_HOME}/Desktop"
cat > "${USER_HOME}/Desktop/TRAMA.desktop" << 'DESKEOF'
[Desktop Entry]
Type=Application
Name=TRAMA
Comment=TRAMA Interactive Installation
Exec=/home/rbpy/trama/start.sh
Icon=applications-multimedia
Terminal=false
Categories=AudioVideo;
DESKEOF
chmod +x "${USER_HOME}/Desktop/TRAMA.desktop"

# Atalho para parar
cat > "${USER_HOME}/Desktop/TRAMA-Stop.desktop" << 'DESKEOF2'
[Desktop Entry]
Type=Application
Name=TRAMA Stop
Comment=Parar TRAMA
Exec=/home/rbpy/trama/stop.sh
Icon=process-stop
Terminal=false
Categories=AudioVideo;
DESKEOF2
chmod +x "${USER_HOME}/Desktop/TRAMA-Stop.desktop"

# [8/8] Adicionar user ao grupo video (webcam)
echo "[8/8] A adicionar user ao grupo video..."
sudo usermod -aG video rbpy

echo ""
echo "═══════════════════════════════════════════"
echo "  Instalação completa!"
echo ""
echo "  Reiniciar:   sudo reboot"
echo "  (O TRAMA arranca automaticamente com o desktop)"
echo ""
echo "  Testar SSH:  ~/trama/start.sh"
echo "  Parar SSH:   ~/trama/stop.sh"
echo ""
echo "  Cadeia: boot → auto-login LXDE → desktop"
echo "          → server HTTP (8080) → Chromium kiosk"
echo "          → TRAMA (camera auto)"
echo ""
echo "  NOTA: Webcam em /dev/video0"
echo "  --use-fake-ui-for-media-stream aceita câmara"
echo "═══════════════════════════════════════════"
