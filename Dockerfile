FROM public.ecr.aws/docker/library/python:3.11.14-slim-bookworm

# Set platform for ARM64 compatibility ...
ARG TARGETPLATFORM=linux/amd64

# Install system dependencies
COPY apt_packages.txt /tmp/apt_packages.txt
RUN apt-get update && \
    apt-get install -y $(grep -v '^#' /tmp/apt_packages.txt | grep -v '^$' | tr '\n' ' ') && \
    rm -rf /var/lib/apt/lists/* /tmp/apt_packages.txt

# Install GitHub CLI
RUN (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Install noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify \
    && ln -s /opt/novnc/vnc_lite.html /opt/novnc/index.html

# Install TTYD
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 && \
    mv ttyd.x86_64 /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

# Install Code Server
RUN curl -fsSL https://code-server.dev/install.sh | sh && mkdir -p /opt/code-server

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# Add link protection trusted domains to vscode
RUN jq '.linkProtectionTrustedDomains += ["https://myninja.ai", "https://betamyninja.ai", "https://gammamyninja.ai"]' /usr/lib/code-server/lib/vscode/product.json > temp.json && mv temp.json /usr/lib/code-server/lib/vscode/product.json

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# Install Playwright package first
RUN pip install playwright
# Then install dependencies and browsers
RUN playwright install-deps && \
    playwright install chromium

# Configure pipx for SWE-REX
RUN python3 -m pip install pipx && \
    python3 -m pipx ensurepath

# Set up working directory
WORKDIR /app
COPY . /app
COPY nginx.conf /etc/nginx/sites-available/default
# Set up supervisor configuration
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 7788 6080 5901 8000 8080 8888 3222 5000

# Set up user and their workspace
RUN groupadd -g 1000 user && \
    useradd -m -u 1000 -g user user && \
    mkdir -p /workspace && \
    chown -R user:user /workspace && \
    usermod -d /workspace user

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
