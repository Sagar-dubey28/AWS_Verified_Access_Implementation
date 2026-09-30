#!/bin/bash
set -euxo pipefail

exec > >(tee /var/log/verified-access-bootstrap.log | logger -t verified-access-bootstrap -s 2>/dev/console) 2>&1

dnf update -y
dnf install -y python3 python3-pip

mkdir -p /opt/verified-access-app
cat > /opt/verified-access-app/app.py <<'PY'
from flask import Flask, jsonify
import socket

app = Flask(__name__)

@app.get("/")
def home():
    return jsonify({
        "message": "AWS Verified Access protected Flask application",
        "status": "authenticated request reached the application",
        "hostname": socket.gethostname()
    })

@app.get("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
PY

python3 -m pip install --upgrade pip
python3 -m pip install flask

cat > /etc/systemd/system/verified-access-app.service <<'UNIT'
[Unit]
Description=Verified Access Flask Demo
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/verified-access-app
ExecStart=/usr/bin/python3 /opt/verified-access-app/app.py
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now verified-access-app.service
