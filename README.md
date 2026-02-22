# TRAMA — Instalação Interativa (Raspberry Pi)

Versão para Raspberry Pi da identidade generativa TRAMA — Jornadas de Design, IADE.

Fios horizontais e verticais que se cruzam, ondulam e **reagem ao movimento** captado pela webcam.

## Hardware

- Raspberry Pi 3/4/5 (testado com Pi 3)
- Webcam USB (ex: Trust Full HD)
- TV/Monitor via HDMI
- Alimentação USB
- Cartão SD com Raspberry Pi OS Lite (Bookworm)

## Como funciona

1. A webcam capta o movimento das pessoas no corredor
2. O browser (Chromium) corre o motor generativo em fullscreen
3. Os fios da trama reagem aos pontos de movimento detectados
4. A saída é por HDMI para a TV a 1080p

## Instalação

```bash
# Clonar repositório
git clone https://github.com/rodrigobrazao/trama-interativa-raspberry.git
cd trama-interativa-raspberry

# Instalar (inclui X server, Chromium, auto-login)
chmod +x install.sh
./install.sh

# Reiniciar (arranca automaticamente)
sudo reboot
```

## Arranque automático

Após `install.sh`, o TRAMA arranca automaticamente ao ligar o Pi:

```
boot → auto-login tty1 → X (openbox) → Chromium kiosk → TRAMA
```

Não é necessário nenhum comando adicional.

## Comandos úteis

```bash
# Testar via SSH (se X já estiver a correr)
./start.sh

# Parar Chromium
pkill -f chromium

# Reiniciar o Pi
sudo reboot

# Ver processos
ps aux | grep -E 'chromium|openbox|Xorg'

# Ver temperatura
vcgencmd measure_temp

# Ver memória
free -h
```

## Manutenção remota

O Pi pode estar num corredor da universidade. Usar SSH ou Tailscale:

```bash
# Via rede local
ssh pi@<IP_DO_PI>

# Via Tailscale (qualquer rede)
ssh pi@<TAILSCALE_IP>
```

## Configuração

Editar as variáveis `CONFIG` no `index.html`:

| Parâmetro | Default | Descrição |
|-----------|---------|-----------|
| `seed` | 42 | Seed generativa (muda o padrão) |
| `interactionRadius` | 180 | Raio de influência do movimento |
| `motionThreshold` | 30 | Sensibilidade ao movimento (menor = mais sensível) |
| `maxPoints` | 5 | Máximo de pontos de interação simultâneos |
| `smoothing` | 0.3 | Suavização do movimento (0-1) |
| `mirror` | true | Espelhar imagem da câmara |
| `threadStep` | 3 | Espaçamento entre fios (maior = mais leve) |

## Cores

| Cor | Hex |
|-----|-----|
| Laranja/Vermelho | `#ff3c00` |
| Ciano | `#00e5ff` |
| Lima | `#c8ff00` |
| Magenta | `#ff00aa` |
| Laranja | `#ff8800` |
| Roxo | `#7b61ff` |

## Baseado em

[TRAMA — Design System](https://github.com/rbrazao/trama) — Sistema de identidade generativa para as Jornadas de Design do IADE.
