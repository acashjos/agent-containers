#!/bin/sh
case "$SHELL" in
  */zsh) INSTALL_LOCATION="$HOME/.zshrc" ;;
  *) INSTALL_LOCATION="$HOME/.bashrc" ;;
esac

VARIANT="${1:-slim}"
case "$VARIANT" in
  slim) DOCKERFILE_NAME="node-slim.Dockerfile" ;;
  fat) DOCKERFILE_NAME="git-gh-curl-unzip-go-bun-node.Dockerfile" ;;
  *)
    echo "Unknown variant '$VARIANT'. Use 'slim' or 'fat'." >&2
    exit 1
    ;;
esac

# For Development
# INSTALL_LOCATION="$(pwd)/.testrcfile"
# touch $INSTALL_LOCATION


# create the home directory for claude-docker if it doesn't exist
mkdir -p ~/.claude-docker
cd ~/.claude-docker

DOCKERFILE_GIST="https://gist.githubusercontent.com/acashjos/93f47fce263dcaaa1cd5ba38b4459ffb/raw/$DOCKERFILE_NAME"
curl -sSL $DOCKERFILE_GIST > Dockerfile

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
. $INSTALL_LOCATION
