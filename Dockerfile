# Use an official Linux base image
FROM ubuntu:20.04

# Switch to root user for installation
USER root

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV POWERSHELL_INSTALL_VERSION=7

# Install dependencies and PowerShell Core
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    apt-transport-https \
    software-properties-common \
    && wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell \
    && rm -rf /var/lib/apt/lists/*

# Set PowerShell as the default shell
SHELL ["pwsh", "-Command"]

# Install VMware PowerCLI inside PowerShell
RUN pwsh -c "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name VMware.PowerCLI -Scope AllUsers -Force -AllowClobber"

# Create working directory for scripts
WORKDIR /usr/src/app/

# Copy PowerShell scripts into the container
COPY Change-RAM.ps1 /usr/src/app/
COPY Start-VMs.ps1 /usr/src/app/
COPY Shutdown-VMs.ps1 /usr/src/app/
COPY Deploy-GNS3.ps1 /usr/src/app/

# Switch back to PowerShell user
USER pwsh

# Default command to enter PowerShell
CMD ["pwsh"]
