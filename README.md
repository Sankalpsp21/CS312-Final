# Minecraft Server Deployment on AWS with Terraform

This project automates the deployment of a Minecraft Java Edition server on an AWS EC2 instance using Terraform.

## Background

We will provision the necessary AWS infrastructure (EC2 instance, security group, key pair) and configure the instance to automatically download, install, and run a Minecraft server as a systemd service. This ensures the server starts on boot and can be managed using standard system commands. This approach avoids manual configuration through the AWS console or direct SSH access for setup, adhering to Infrastructure as Code (IaC) principles.

## Requirements

### Prerequisites:
* An AWS account.
* [Terraform](https://developer.hashicorp.com/terraform/downloads) (version x.y.z or higher) installed locally.
* [AWS CLI](https://aws.amazon.com/cli/) installed and configured.
* A Git client installed.
* An SSH key pair. If you don't have one, you can generate it using `ssh-keygen -t rsa -b 2048 -f ~/.ssh/minecraft_key -C "minecraft-key"`. This will create `minecraft_key` (private) and `minecraft_key.pub` (public) in your `~/.ssh/` directory. The `main.tf` file expects these at `~/.ssh/minecraft_key.pub` and `~/.ssh/minecraft_key`.
* (Optional but recommended for testing connection) `nmap` tool: `sudo apt install nmap` or `brew install nmap`.
* Minecraft Java Edition client.

### AWS Credentials:
Ensure your AWS CLI is configured with credentials that have permissions to create the required resources (EC2, VPC, IAM if extended). You can typically configure this by running `aws configure`. Terraform will use these credentials.
Alternatively, ensure your `~/.aws/credentials` file is set up, for example:
```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
aws_session_token = YOUR_SESSION_TOKEN # If using temporary credentials