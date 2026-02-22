# TRAMA — Instalação Interativa (Raspberry Pi)

Versão para Raspberry Pi da identidade generativa TRAMA — Jornadas de Design, IADE.

Fios horizontais e verticais que se cruzam, ondulam e **reagem ao movimento** captado pela webcam.

## Hardware

- Raspberry Pi 3/4/5
- Webcam USB
- TV/Monitor via HDMI
- Alimentação USB

## Como funciona

1. A webcam capta o movimento das pessoas no corredor
2. O browser (Chromium) corre o motor generativo em fullscreen
3. Os fios da trama reagem aos pontos de movimento detectados
4. A saída é por HDMI para a TV

## Instalação

```bash
# Clonar repositório
git clone https://github.com/rbrazao/trama-interativa-raspberry.git
cd trama-interativa-raspberry

# Instalar
chmod +x install.sh
./install.sh

# Testar
./start.sh
```

## Auto-start (arrancar com o Pi)

```bash
sudo systemctl enable trama
sudo reboot
```

## Comandos úteis

```bash
# Parar
sudo systemctl stop trama

# Ver logs
journalctl -u trama -f

# Reiniciar
sudo systemctl restart trama

# Desativar auto-start
sudo systemctl disable trama
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

## Cores

| Cor | Hex |
|-----|-----|
| 🔴 Laranja/Vermelho | `#ff3c00` |
| 🔵 Ciano | `#00e5ff` |
| 🟢 Lima | `#c8ff00` |
| 🟣 Magenta | `#ff00aa` |
| 🟠 Laranja | `#ff8800` |
| 🟣 Roxo | `#7b61ff` |

## Baseado em

[TRAMA — Design System](https://github.com/rbrazao/trama) — Sistema de identidade generativa para as Jornadas de Design do IADE.
