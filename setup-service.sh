#!/bin/bash

# Define variables based on your current environment
SERVICE_FILE="/etc/systemd/system/pikrellcam.service"
PKC_DIR=$(pwd)
PKC_USER=$USER

echo "--- Configuring PiKrellCam Systemd Service ---"

# 1. Remove the old rc.local entries if they exist
if grep -q "pikrellcam" /etc/rc.local; then
    echo "Cleaning up /etc/rc.local..."
    sudo sed -i "/pikrellcam/d" /etc/rc.local
fi

# 2. Generate the systemd service file
echo "Generating $SERVICE_FILE..."

sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=PiKrellCam Camera Service
After=network.target

[Service]
Environment=RUNNING_UNDER_SYSTEMD=1
Environment="HOME=$PKC_DIR"
Environment="USER=$PKC_USER"
User=$PKC_USER
WorkingDirectory=$PKC_DIR
ExecStart=$PKC_DIR/pikrellcam
Restart=always
RestartSec=10
# Increase this if your SD card is very slow to release file locks
TimeoutStopSec=15

[Install]
WantedBy=multi-user.target
EOF"

# 3. Reload systemd and enable the service
echo "Loading and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable pikrellcam.service

# 4. Final instructions
echo "------------------------------------------------"
echo "Done! PiKrellCam is now managed by systemd."
echo "To start it now:   sudo systemctl start pikrellcam"
echo "To check status:   sudo systemctl status pikrellcam"
echo "To see logs:       journalctl -u pikrellcam -f"
echo "------------------------------------------------"
