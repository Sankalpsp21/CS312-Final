# Automated Minecraft Server Deployment on AWS with Terraform

This project provides a comprehensive guide and set of scripts to automate the deployment of a Minecraft Java Edition server on an AWS EC2 instance using Terraform. It emphasizes Infrastructure as Code (IaC) principles, enabling consistent, repeatable, and version-controlled deployments.

## Table of Contents

1.  [Overview](#overview)
2.  [Pipeline Stages](#pipeline-stages)
3.  [Prerequisites](#prerequisites)
    * [Tooling and Versions](#tooling-and-versions)
    * [AWS Configuration](#aws-configuration)
    * [SSH Key Pair](#ssh-key-pair)
5.  [Deployment Tutorial](#deployment-tutorial)
    * [Step 1: Clone Repository](#step-1-clone-repository)
    * [Step 2: Environment Setup Verification](#step-2-environment-setup-verification)
    * [Step 3: Configure SSH Keys](#step-3-configure-ssh-keys)
    * [Step 4: Initialize Terraform](#step-4-initialize-terraform)
    * [Step 5: Validate and Plan Deployment](#step-5-validate-and-plan-deployment)
    * [Step 6: Apply Terraform Configuration](#step-6-apply-terraform-configuration)

## Overview

This solution automates the provisioning of necessary AWS infrastructure (EC2 instance, Security Group, Key Pair) and the subsequent configuration of the instance. The configuration includes installing Java, downloading the official Minecraft server JAR, and setting up a `systemd` service. This service ensures the Minecraft server starts automatically on boot and can be managed using standard system commands, facilitating a hands-off setup post-deployment.

The key benefits of this approach are:
* **Automation:** Reduces manual effort and potential for human error.
* **Consistency:** Ensures identical server environments every time.
* **Version Control:** Infrastructure and configuration are versioned in Git.
* **Scalability (Conceptual):** While this setup is for a single server, the principles can be extended.

This project specifically avoids using the AWS Management Console for setup and does not rely on the EC2 `user_data` field for bootstrapping, instead utilizing Terraform provisioners for configuration.

## Pipeline Stages

The deployment process follows these distinct stages:

1.  **Local Preparation:**
    * Installation and configuration of required tools (Terraform, AWS CLI).
    * Acquisition or generation of an SSH key pair.
    * Configuration of AWS credentials.

2.  **Infrastructure Definition (Terraform `main.tf`):**
    * The `main.tf` file defines all AWS resources:
        * EC2 Key Pair (`aws_key_pair`) using your public SSH key.
        * Security Group (`aws_security_group`) to allow inbound traffic on SSH (port 22) and Minecraft (port 25565), and all outbound traffic.
        * EC2 Instance (`aws_instance`) using an Amazon Linux 2023 AMI.
    * An AMI data source (`data "aws_ami"`) is used to dynamically fetch the latest Amazon Linux 2023 AMI ID for the specified region.

3.  **Infrastructure Provisioning (`terraform apply`):**
    * Terraform communicates with your AWS account.
    * It creates or updates resources according to the definitions in `main.tf`.

4.  **Instance Configuration (Terraform Provisioners):**
    * Once the EC2 instance is running, Terraform connects to it via SSH (using the provided private key).
    * The `file` provisioner uploads the `scripts/install-minecraft.sh` script to the EC2 instance.
    * The `remote-exec` provisioner executes this script with `sudo` privileges on the instance.
    * The `install-minecraft.sh` script performs:
        * System package updates.
        * Installation of Amazon Corretto 21 (Java JDK).
        * Creation of a dedicated directory and user context for Minecraft.
        * Download of the latest stable Minecraft server JAR (URL specified in the script).
        * Automatic acceptance of the Minecraft EULA.
        * Setup of a `systemd` service (`minecraft.service`) to manage the Minecraft server process, enabling auto-start on boot and easy start/stop/status checks.
        * Enabling and starting the `minecraft` service.

5.  **Output & Verification:**
    * Terraform outputs the public IP address of the newly created Minecraft server.
    * The user can then verify port accessibility using `nmap` and connect to the server using their Minecraft Java Edition client.

6.  **Decommissioning (`terraform destroy`):**
    * Terraform removes all resources it created, preventing ongoing charges.

## Prerequisites

### Tooling and Versions

Ensure the following tools are installed on your local machine or the VM you'll be using to run Terraform:

* **Terraform:** Version `1.0.0` or newer.
    * Installation: [developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads)
    * Verify: `terraform version`
* **AWS Command Line Interface (AWS CLI):** Version `2.0` or newer.
    * Installation: [aws.amazon.com/cli/](https://aws.amazon.com/cli/)
    * Verify: `aws --version`
* **Git:** For cloning the repository.
    * Installation: [git-scm.com/downloads](https://git-scm.com/downloads)
    * Verify: `git --version`
* **SSH Client:** Required by Terraform to connect to the EC2 instance for provisioning.
    * Linux/macOS: Typically pre-installed (OpenSSH).
    * Windows: Modern Windows 10/11 include OpenSSH. Alternatively, Git Bash includes an SSH client.
* **(Optional) `nmap`:** For network verification.
    * Installation:
        * Linux (Debian/Ubuntu): `sudo apt update && sudo apt install nmap`
        * macOS (Homebrew): `brew install nmap`
        * Windows: Download from [nmap.org/download.html](https://nmap.org/download.html)
    * Verify: `nmap --version`
* **Minecraft Java Edition Client:** To connect to the server.

### AWS Configuration

* **AWS Account:** You need an active AWS account with permissions to create EC2 instances, Security Groups, and Key Pairs.
* **AWS CLI Configuration:** Configure your AWS CLI with credentials. Run `aws configure` and provide your Access Key ID, Secret Access Key, default region (e.g., `us-west-2` as used in this project), and default output format (e.g., `json`).
    ```bash
    aws configure
    AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
    AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
    Default region name [None]: us-west-2
    Default output format [None]: json
    ```
    **Security Best Practice:** Use IAM credentials with the least privilege necessary. Avoid using root account credentials. For enhanced security, consider using temporary credentials or IAM roles if running Terraform from an automated environment. **Never commit your AWS secret keys to Git.**

### SSH Key Pair

Terraform will create an `aws_key_pair` resource using your public SSH key. The corresponding private key is needed for Terraform's provisioners to SSH into the EC2 instance.

1.  **Check for existing keys:** Look for files like `id_rsa`/`id_rsa.pub` or `minecraft_key`/`minecraft_key.pub` in `~/.ssh/` (Linux/macOS) or `C:\Users\YourUsername\.ssh\` (Windows).
2.  **Generate a new key pair if needed:**
    * **Linux/macOS or Windows (OpenSSH/Git Bash):**
        ```bash
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/minecraft_key -C "minecraft-key-aws"
        ```
        This command creates `minecraft_key` (private key) and `minecraft_key.pub` (public key). Do not set a passphrase if Terraform will use it non-interactively, or use `ssh-agent`.
    * The `main.tf` file is configured to look for the public key at `~/.ssh/minecraft_key.pub` and the private key at `~/.ssh/minecraft_key`. Adjust paths in `main.tf` if yours are different.
3.  **Set Permissions for Private Key (Crucial):**
    * **Linux/macOS or Windows (Git Bash/WSL):**
        ```bash
        chmod 400 ~/.ssh/minecraft_key
        ```
    * **Windows (Native):** Ensure the private key file permissions are restricted so only your user account can read it (via File Properties -> Security).

## Deployment Tutorial

These steps guide you through deploying the Minecraft server from your local machine or a VM.

### Step 1: Clone Repository

If you haven't already, clone this repository (or create the files locally based on this guide):
```bash
# Example: git clone [https://github.com/yourusername/minecraft-terraform-aws.git](https://github.com/yourusername/minecraft-terraform-aws.git)
# cd minecraft-terraform-aws
```
### Step 2: Environment Setup Verification
Ensure all tools listed under Prerequisites are installed and correctly configured (especially terraform and aws configure).

### Step 3: Configure SSH Keys
Verify that your SSH public key (~/.ssh/minecraft_key.pub) and private key (~/.ssh/minecraft_key) exist and that the private key has secure permissions (chmod 400). The paths in main.tf must match your key locations.

aws_key_pair.minecraft_key.public_key: file("~/.ssh/minecraft_key.pub")
aws_instance.minecraft.connection.private_key: file("~/.ssh/minecraft_key")
Adjust these paths in main.tf if your keys are named or located differently.

### Step 4: Initialize Terraform
Navigate to the root directory of the project (where main.tf is located) and run:

```bash
terraform init
```
This command initializes your Terraform working directory by downloading the necessary provider plugins (e.g., for AWS).

### Step 5: Validate and Plan Deployment
(Optional) Validate Terraform Configuration:
Check for syntax errors in your Terraform files:

```bash
terraform validate
```

Review Deployment Plan:
See what resources Terraform will create, modify, or destroy before actually making changes:

```bash
terraform plan
```
Review the output carefully.

### Step 6: Apply Terraform Configuration
Execute the deployment:

```bash
terraform apply
```
Terraform will show you the execution plan again and prompt for confirmation. Type yes and press Enter.
