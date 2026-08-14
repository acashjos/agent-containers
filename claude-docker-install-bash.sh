##!/bin/bash
INSTALL_LOCATION="$HOME/.bashrc"

# For Development
# INSTALL_LOCATION="$(pwd)/.testrcfile"
# touch $INSTALL_LOCATION


# create the home directory for claude-docker if it doesn't exist
mkdir -p ~/.claude-docker
cd ~/.claude-docker

cat > Dockerfile << EOF
FROM node:22-slim
RUN apt-get update && apt-get install -y git curl gh && rm -rf /var/lib/apt/lists/*
RUN apt install golang-go
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

EOF


# build docker image
docker build . -t claude-docker --no-cache

cat >> $INSTALL_LOCATION <<EOF
alias claude-docker-sh="docker run -it \
--entrypoint /bin/bash \
-v "\$HOME/.claude-docker:/home/claudeuser" \
-v "\$(pwd)":/workspace \
claude-docker:latest" 
EOF

# claude-docker
cat >> $INSTALL_LOCATION <<EOF
alias claude-docker="docker run -it \
-v "\$HOME/.claude-docker:/home/claudeuser" \
-v "\$(pwd)":/workspace \
claude-docker:latest"
EOF

echo "\n\n run: \`claude-docker-sh\` at your project directory to open bash shell in the docker container"
echo " run: \`claude-docker\` at your project directory to start claude in a docker container"
echo "At first run, please use \`\\login\` command to complete the setup"

echo "\n sourcing $INSTALL_LOCATION to apply the changes"
source $INSTALL_LOCATION 

# alias claude-docker="docker run -it \
# -v "$HOME/.claude-docker:/home/claudeuser" \
# -v "$(pwd)":/workspace \
# claude-docker:latest"

# alias claude-docker-sh="docker run -it \
# --entrypoint /bin/bash \
# -v "$HOME/.claude-docker:/home/claudeuser" \
# -v "$(pwd)":/workspace \
# claude-docker:latest"