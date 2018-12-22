FROM mcr.microsoft.com/powershell:6.1.0-ubuntu-18.04
WORKDIR /app
COPY . .
RUN pwsh -c Install-Module Pester -Scope CurrentUser -Force
ENTRYPOINT [ "pwsh", "-c" ]