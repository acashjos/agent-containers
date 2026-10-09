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

MARKER_START="# >>> claude-docker >>>"
MARKER_END="# <<< claude-docker <<<"

touch "$INSTALL_LOCATION"

# strip any block from a previous run so re-running (or switching variants) updates in place instead of duplicating
if grep -q "$MARKER_START" "$INSTALL_LOCATION" 2>/dev/null; then
  sed -i.bak "/$MARKER_START/,/$MARKER_END/d" "$INSTALL_LOCATION" && rm -f "$INSTALL_LOCATION.bak"
fi

cat >> $INSTALL_LOCATION <<EOF
$MARKER_START
alias claude-docker-sh="docker run -it \
--entrypoint /bin/bash \
--name "\$(basename "\$(pwd)")" \
-v "\$HOME/.claude-docker:/home/claudeuser" \
-v "\$(pwd)":/workspace \
claude-docker:latest"
alias claude-docker="docker run -it \
--name "\$(basename "\$(pwd)")" \
-v "\$HOME/.claude-docker:/home/claudeuser" \
-v "\$(pwd)":/workspace \
claude-docker:latest"
$MARKER_END
EOF

echo "\n\n run: \`claude-docker-sh\` at your project directory to open bash shell in the docker container"
echo " run: \`claude-docker\` at your project directory to start claude in a docker container"
echo "At first run, please use \`\\login\` command to complete the setup"

echo "\n sourcing $INSTALL_LOCATION to apply the changes"
. $INSTALL_LOCATION
