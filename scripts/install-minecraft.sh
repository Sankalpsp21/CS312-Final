#!/bin/bash

cd /home/ec2-user
sudo yum update -y
sudo amazon-linux-extras enable corretto21
sudo yum install java-21-amazon-corretto -y

# Create Minecraft directory
mkdir minecraft
cd minecraft

# Download server
curl -O https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar

# Accept EULA
echo "eula=true" > eula.txt

# Create service file
sudo tee /etc/systemd/system/minecraft.service > /dev/null <<EOF
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/minecraft
ExecStart=/usr/bin/java -Xmx1024M -Xms1024M -jar server.jar nogui
ExecStop=/bin/kill -s TERM \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable minecraft
sudo systemctl start minecraft
