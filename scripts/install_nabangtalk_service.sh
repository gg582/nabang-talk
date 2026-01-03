#!/usr/bin/env bash
set -euo pipefail

APP_DIR=${APP_DIR:-/opt/nabangtalk}
SERVICE_PATH=/etc/systemd/system/nabangtalk.service

if [[ $(id -u) -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

if ! command -v node >/dev/null; then
  echo "Node.js is required. Please install Node.js 18+."
  exit 1
fi

mkdir -p "$APP_DIR"
rsync -a --delete --exclude node_modules --exclude dist ./ "$APP_DIR"

cd "$APP_DIR"

npm install
npm run build

install -m 755 scripts/nabangtalk-start.sh /usr/local/bin/nabangtalk-start

cat > "$SERVICE_PATH" <<'SERVICE'
[Unit]
Description=NabangTalk web client
After=network.target

[Service]
Type=simple
Environment=APP_DIR=/opt/nabangtalk
Environment=TCP_ADDR=127.0.0.1:34567
Environment=WS_ADDR=0.0.0.0:5174
Environment=WEB_PORT=5173
WorkingDirectory=/opt/nabangtalk
ExecStart=/usr/local/bin/nabangtalk-start
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now nabangtalk.service

echo "Installed and started nabangtalk.service"
