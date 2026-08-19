FROM node:22-slim
RUN apt-get update && apt-get install -y git curl gh unzip && rm -rf /var/lib/apt/lists/*
RUN apt update && apt install -y golang-go 
RUN npm install -g @anthropic-ai/claude-code
RUN groupadd --gid 1001 claudeuser && useradd --uid 1001 --gid 1001 --create-home --home-dir /home/claudeuser --shell /bin/bash claudeuser
ENV HOME=/home/claudeuser
ENV PATH="${HOME}/.bun/bin:${HOME}/.local/bin:${PATH}"
WORKDIR /workspace
RUN chown -R claudeuser:claudeuser /workspace /home/claudeuser
VOLUME ["/home/claudeuser"]
USER claudeuser
RUN curl -fsSL https://bun.com/install | bash && bun --version
# rtk installation script
RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
ENTRYPOINT ["claude", "--channels", "plugin:telegram@claude-plugins-official", "--dangerously-skip-permissions"]

