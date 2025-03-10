# Use Microsoft PowerShell as the base image
FROM mcr.microsoft.com/powershell:latest

# Switch to root user for package installations
USER root

# Install necessary packages for PowerCLI
RUN apt-get update \
    && apt-get install -y \
        wget \
        libgssapi-krb5-2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install VMware PowerCLI from the PowerShell Gallery
RUN pwsh -c "Install-Module -Name VMware.PowerCLI -Scope AllUsers -Force -AllowClobber"

# Set working directory for scripts
WORKDIR /usr/src/app/

# Copy only the Deploy-GNS3 script into the container
COPY Deploy-GNS3.ps1 /usr/src/app/

# Switch back to PowerShell user
USER pwsh

# Set PowerShell as the default shell
CMD ["pwsh"]

