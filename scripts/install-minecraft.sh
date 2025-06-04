#!/bin/bash
set -euxo pipefail # Exit on error, print commands

echo "Starting Minecraft Server installation script..."

# System update and Java installation
echo "Updating system and installing Java (Amazon Corretto 21)..."
sudo yum update -y
sudo yum install java-21-amazon-corretto-devel -y # Using -devel for JDK

# Verify Java installation
java -version
echo "Java installation complete."

# Define Minecraft directory and user
MINECRAFT_USER="ec2-user"
MINECRAFT_DIR="/home/${MINECRAFT_USER}/minecraft"
MINECRAFT_JAR_URL="https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar" # From your original post
MINECRAFT_JAR_NAME="server.jar"

# Create Minecraft directory and set permissions
echo "Creating Minecraft directory: ${MINECRAFT_DIR}"
sudo mkdir -p "${MINECRAFT_DIR}"
sudo chown -R "${MINECRAFT_USER}:${MINECRAFT_USER}" "${MINECRAFT_DIR}"

# Download Minecraft server JAR
echo "Downloading Minecraft server JAR..."
# Run curl as the minecraft user or ensure permissions are set correctly after download by root
sudo -u "${MINECRAFT_USER}" curl -o "${MINECRAFT_DIR}/${MINECRAFT_JAR_NAME}" "${MINECRAFT_JAR_URL}"

# Create EULA file
echo "Accepting EULA..."
echo "eula=true" | sudo -u "${MINECRAFT_USER}" tee "${MINECRAFT_DIR}/eula.txt" > /dev/null

# Optional: Initial server.properties configuration (if needed before first run)
# Example: Ensure server port (though it defaults to 25565)
# echo "server-port=25565" | sudo -u "${MINECRAFT_USER}" tee -a "${MINECRAFT_DIR}/server.properties" > /dev/null

# Create systemd service file
echo "Creating systemd service file for Minecraft..."
sudo tee /etc/systemd/system/minecraft.service > /dev/null <<EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=${MINECRAFT_USER}
WorkingDirectory=${MINECRAFT_DIR}
ExecStart=/usr/bin/java -Xmx1024M -Xms1024M -jar ${MINECRAFT_JAR_NAME} nogui
Restart=always
# TimeoutStopSec defines how long systemd waits for the service to stop. Default is 90s.
# Minecraft server should handle SIGTERM gracefully. If it needs more time or specific stop command:
# ExecStop=/path/to/minecraft_stop_script.sh
# For basic SIGTERM handling by Minecraft, this is usually sufficient.

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the Minecraft service
echo "Reloading systemd daemon and starting Minecraft service..."
sudo systemctl daemon-reload
sudo systemctl enable minecraft.service
sudo systemctl start minecraft.service

# Check service status (output will be in Terraform logs)
echo "Checking Minecraft service status:"
sudo systemctl status minecraft.service --no-pager || echo "Service status check failed or service not fully up yet."

echo "Minecraft Server installation script finished."