#!/bin/bash

# Manual provisioning script for the Open WebUI instance.
# Run as root, passing the Terraform-generated credentials as env vars:
#
#   OPEN_WEBUI_PASSWD="$(terraform output -raw password)" \
#   bash provision_manual.sh

set -e
export DEBIAN_FRONTEND=noninteractive

WEBUI_USER="${OPEN_WEBUI_USER:-admin@demo.gs}"
WEBUI_PASSWD="${OPEN_WEBUI_PASSWD:?Error: OPEN_WEBUI_PASSWD must be set}"

apt-get update
apt-get install -y sqlite3 apache2-utils

mkdir -p /etc/open-webui.d/

HASHED_PASSWD=$(htpasswd -bnBC 10 "" "$WEBUI_PASSWD" | tr -d ':\n')

# Pull and start Open WebUI once so it initialises the database
docker pull ghcr.io/open-webui/open-webui:ollama

docker run -d --rm --gpus all \
  -p 80:8080 \
  -v /etc/open-webui.d:/app/backend/data \
  --name openwebui_init \
  ghcr.io/open-webui/open-webui:ollama

echo "Waiting for Open WebUI to initialise..."
timeout 300 bash -c 'until [[ "$(curl -s -o /dev/null -w "%{http_code}" localhost)" == "200" ]]; do sleep 5; done'
echo "Open WebUI is up — seeding admin user"

docker stop openwebui_init

# Seed the admin user into the database
cat << EOF > /etc/open-webui.d/webui.sql
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
INSERT INTO auth VALUES('488af2d3-dd38-4310-a549-6d8ad11ae69e','${WEBUI_USER}','${HASHED_PASSWD}',1);
INSERT INTO user(id,name,email,role,profile_image_url,created_at,updated_at,last_active_at,username)
  VALUES('488af2d3-dd38-4310-a549-6d8ad11ae69e','Admin User','${WEBUI_USER}','admin','',1719901984,1719901984,1719901984,'${WEBUI_USER}');
COMMIT;
EOF

sqlite3 /etc/open-webui.d/webui.db < /etc/open-webui.d/webui.sql
rm -f /etc/open-webui.d/webui.sql
echo "Admin user seeded"

# Pre-pull qwen3-coder:30b into the ollama named volume
# ollama pull is a client command — start the server first, then pull against it
echo "Pulling qwen3-coder:30b — this will take several minutes"
docker run -d --name ollama_temp --gpus all \
  -v ollama:/root/.ollama \
  ollama/ollama serve
sleep 10
docker exec ollama_temp ollama pull qwen3-coder:30b-q3_k_m
docker stop ollama_temp && docker rm ollama_temp
echo "Model pull complete"

# Install the systemd service (single-quoted EOF = no variable expansion)
cat << 'EOF' > /etc/systemd/system/openwebui.service
[Unit]
Description=Open WebUI
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Type=simple
Restart=always
ExecStartPre=-/usr/bin/docker stop openwebui
ExecStartPre=-/usr/bin/docker rm openwebui
ExecStart=/usr/bin/docker run --gpus all \
  -p 80:8080 \
  -e RAG_EMBEDDING_MODEL_AUTO_UPDATE=true \
  -v ollama:/root/.ollama \
  -v /etc/open-webui.d:/app/backend/data \
  --name openwebui \
  ghcr.io/open-webui/open-webui:ollama

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openwebui.service
systemctl start openwebui.service
echo "Done — Open WebUI is running"
