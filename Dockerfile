FROM mcr.microsoft.com/powershell:6.1.0-ubuntu-18.04
WORKDIR /app
COPY . .
RUN apt-get update \
    && apt-get install -y wget apt-transport-https \
    && wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && add-apt-repository universe \
    && apt-get update
&& sudo apt-get install dotnet-sdk-2.2
RUN pwsh -c Install-Module Pester -Scope CurrentUser -Force
ENTRYPOINT [ "pwsh", "-c" ]