# Use PowerShell as the base image
FROM mcr.microsoft.com/powershell:latest

# Switch to root user for installations
USER root

# Install necessary Linux dependencies
RUN apt-get update \
    && apt-get install -y \
        wget \
        libgssapi-krb5-2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install VMware PowerCLI from PowerShell Gallery
RUN pwsh -c "Install-Module -Name VMware.PowerCLI -Scope AllUsers -Force -AllowClobber"

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
