FROM node:22-slim
RUN apt-get update && apt-get install -y git curl gh && rm -rf /var/lib/apt/lists/*
RUN apt update && apt install -y golang-go
RUN npm install -g @earendil-works/pi-coding-agent
RUN pi install npm:pi-hermes-memory
RUN groupadd --gid 1001 agentuser && useradd --uid 1001 --gid 1001 --create-home --home-dir /home/agentuser --shell /bin/bash agentuser
ENV HOME=/home/agentuser
WORKDIR /workspace
RUN chown -R agentuser:agentuser /workspace /home/agentuser
VOLUME ["/home/agentuser"]
USER agentuser
# rtk installation script
# RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh && \
#   echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
ENTRYPOINT ["pi"]