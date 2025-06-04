provider "aws" {
  region = "us-west-2" # As per your initial setup
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"] # Example filter for AL2023
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_key_pair" "minecraft_key" {
  key_name   = "minecraft-key"
  public_key = file("~/.ssh/minecraft_key.pub")
}

resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-sg"
  description = "Allow SSH and Minecraft"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to your IP if possible: e.g., ["YOUR_IP/32"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Minecraft port open to anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "minecraft" {
  ami                    = data.aws_ami.amazon_linux_2023.id # Use the data source
  instance_type          = "t2.micro" # Sufficient for a small server
  key_name               = aws_key_pair.minecraft_key.key_name
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]

  # Connection block for provisioners
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/minecraft_key")
    host        = self.public_ip
  }

  # Provisioner to upload the install script
  provisioner "file" {
    source      = "scripts/install-minecraft.sh" # Path to script locally
    destination = "/tmp/install-minecraft.sh"    # Path on the remote instance
  }

  # Provisioner to execute the script
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-minecraft.sh",
      "sudo /tmp/install-minecraft.sh" # Run the script with sudo
    ]
  }

  tags = {
    Name = "MinecraftServer-Terraform"
  }
}

# Output the public IP address of the Minecraft server
output "minecraft_server_ip" {
  value       = aws_instance.minecraft.public_ip
  description = "Public IP address of the Minecraft server."
}