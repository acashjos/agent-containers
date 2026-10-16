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

# the docker run command itself lives here, not in the rc file, so the alias stays a one-liner
cat > run.sh <<'EOF'
#!/bin/sh
ENTRYPOINT_FLAGS=""
if [ "$1" = "sh" ]; then
  ENTRYPOINT_FLAGS="--entrypoint /bin/bash"
fi

DIRNAME="$(basename "$(pwd)")"
SUFFIX="$(awk 'BEGIN{srand(); printf "%02d", int(rand()*100)}')"

MSYS_NO_PATHCONV=1 docker run -it --rm \
  $ENTRYPOINT_FLAGS \
  --name "$DIRNAME-$SUFFIX" \
  -v "$HOME/.claude-docker:/home/agentuser" \
  -v "$(pwd)":/workspace/$DIRNAME \
  -w /workspace/$DIRNAME \
  claude-docker:latest
EOF
chmod +x run.sh

touch "$INSTALL_LOCATION"

# migrate away from the old multi-line marker block from earlier versions of this script, if present
if grep -q "# >>> claude-docker >>>" "$INSTALL_LOCATION" 2>/dev/null; then
  sed -i.bak "/# >>> claude-docker >>>/,/# <<< claude-docker <<</d" "$INSTALL_LOCATION" && rm -f "$INSTALL_LOCATION.bak"
fi

# single alias line: drop any previous one, then append the current one. `claude-docker sh` opens a shell instead.
sed -i.bak '/^alias claude-docker=/d' "$INSTALL_LOCATION" && rm -f "$INSTALL_LOCATION.bak"
echo "alias claude-docker=\"$HOME/.claude-docker/run.sh\"" >> "$INSTALL_LOCATION"

echo "\n\n run: \`claude-docker\` at your project directory to start claude in a docker container"
echo " run: \`claude-docker sh\` at your project directory to open a bash shell in the docker container instead"
echo "At first run, please use \`\\login\` command to complete the setup"

echo "\n $INSTALL_LOCATION was updated, but this script's shell can't apply that to your current terminal."
echo " run: \`source $INSTALL_LOCATION\` yourself (or open a new terminal) before using the alias"
