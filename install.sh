#!/bin/bash
# ═══════════════════════════════════════════
# TRAMA — Instalação para Raspberry Pi
# Versão browser (Chromium kiosk mode)
# Compatível com Pi OS Lite (sem desktop)
# ═══════════════════════════════════════════

echo "═══════════════════════════════════════════"
echo "  TRAMA — Setup Raspberry Pi"
echo "═══════════════════════════════════════════"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# [1/6] Instalar X server mínimo + Chromium
echo "[1/6] A instalar pacotes (X server, Chromium, etc.)..."
sudo apt-get update -y
sudo apt-get install -y \
  xserver-xorg x11-xserver-utils xinit openbox \
  chromium-browser unclutter v4l-utils

# [2/6] Desativar screensaver / blank screen
echo "[2/6] A desativar screensaver..."
sudo raspi-config nonint do_blanking 1 2>/dev/null || true

# [3/6] Aumentar GPU memory
echo "[3/6] A configurar GPU memory..."
CONFIG_FILE="/boot/firmware/config.txt"
[ ! -f "$CONFIG_FILE" ] && CONFIG_FILE="/boot/config.txt"
if ! grep -q 'gpu_mem=128' "$CONFIG_FILE" 2>/dev/null; then
  echo 'gpu_mem=128' | sudo tee -a "$CONFIG_FILE"
fi

# [4/6] Configurar auto-login no tty1
echo "[4/6] A configurar auto-login..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << 'LOGINEOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
LOGINEOF

# [5/6] Configurar openbox autostart (lança Chromium kiosk)
echo "[5/6] A configurar openbox + Chromium kiosk..."
mkdir -p /home/pi/.config/openbox
cat > /home/pi/.config/openbox/autostart << OBEOF
# TRAMA — Openbox Autostart
xset s off &
xset -dpms &
xset s noblank &
unclutter -idle 0.5 -root &

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
  --disable-gpu \\
  --num-raster-threads=2 \\
  "file://${SCRIPT_DIR}/index.html" &
OBEOF

# [6/6] Configurar .bash_profile para iniciar X automaticamente
echo "[6/6] A configurar auto-start do X..."
cat > /home/pi/.bash_profile << 'BPEOF'
# TRAMA — Auto-start X no login (só no tty1, não no SSH)
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec startx /usr/bin/openbox-session -- :0 vt1 2>/dev/null
fi
BPEOF

# Criar script de arranque manual (para testes via SSH)
cat > "$SCRIPT_DIR/start.sh" << STARTEOF
#!/bin/bash
# TRAMA — Arranque manual (para testes via SSH)
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
export DISPLAY=:0

pkill -f chromium 2>/dev/null || true
sleep 1

if ! xdpyinfo -display :0 &>/dev/null; then
  echo "X não está a correr. A iniciar..."
  startx /usr/bin/openbox-session -- :0 vt1 &
  sleep 3
fi

chromium-browser \\
  --kiosk --noerrdialogs --disable-infobars \\
  --disable-session-crashed-bubble --disable-restore-session-state \\
  --disable-features=TranslateUI --check-for-update-interval=31536000 \\
  --autoplay-policy=no-user-gesture-required \\
  --use-fake-ui-for-media-stream --enable-features=WebRTC \\
  --allow-file-access-from-files --disable-gpu --num-raster-threads=2 \\
  "file://\${SCRIPT_DIR}/index.html" &

echo "TRAMA iniciado!"
STARTEOF
chmod +x "$SCRIPT_DIR/start.sh"

# Adicionar user pi ao grupo video (webcam)
sudo usermod -aG video pi

echo ""
echo "═══════════════════════════════════════════"
echo "  Instalação completa!"
echo ""
echo "  Reiniciar:   sudo reboot"
echo "  (O TRAMA arranca automaticamente)"
echo ""
echo "  Testar SSH:  ./start.sh"
echo "  Parar:       pkill -f chromium"
echo ""
echo "  Cadeia: boot → auto-login → X → openbox"
echo "          → Chromium kiosk → TRAMA"
echo ""
echo "  NOTA: A webcam precisa de estar ligada."
echo "  O --use-fake-ui-for-media-stream"
echo "  aceita automaticamente o acesso à câmara."
echo "═══════════════════════════════════════════"
