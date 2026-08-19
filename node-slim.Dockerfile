FROM node:22-slim
RUN apt-get update && apt-get install -y git curl gh && rm -rf /var/lib/apt/lists/*
RUN apt update && apt install -y golang-go
RUN npm install -g @anthropic-ai/claude-code
RUN groupadd --gid 1001 claudeuser && useradd --uid 1001 --gid 1001 --create-home --home-dir /home/claudeuser --shell /bin/bash claudeuser
ENV HOME=/home/claudeuser
WORKDIR /workspace
RUN chown -R claudeuser:claudeuser /workspace /home/claudeuser
VOLUME ["/home/claudeuser"]
USER claudeuser
# rtk installation script
RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh && \
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
ENTRYPOINT ["claude", "--dangerously-skip-permissions"]