#!/bin/sh
# usage: pi-docker-install.sh [slim|fat] [path/to/auth.json]
# Without an auth.json path, the key is taken from $OPENROUTER_API_KEY or prompted for.
case "$SHELL" in
  */zsh) INSTALL_LOCATION="$HOME/.zshrc" ;;
  *) INSTALL_LOCATION="$HOME/.bashrc" ;;
esac

VARIANT="${1:-slim}"
AUTH_SRC="$2"
DEFAULT_MODEL="deepseek/deepseek-v4.1-flash"

case "$VARIANT" in
  slim) DOCKERFILE_NAME="node-slim.Dockerfile" ;;
  fat) DOCKERFILE_NAME="git-gh-curl-unzip-go-bun-node.Dockerfile" ;;
  *)
    echo "Unknown variant '$VARIANT'. Use 'slim' or 'fat'." >&2
    exit 1
    ;;
esac

if [ -n "$AUTH_SRC" ] && [ ! -f "$AUTH_SRC" ]; then
  echo "auth.json not found: $AUTH_SRC" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$SCRIPT_DIR/$DOCKERFILE_NAME" ]; then
  echo "$DOCKERFILE_NAME not found next to this script ($SCRIPT_DIR)" >&2
  exit 1
fi

# create the home directory for pi-docker if it doesn't exist
mkdir -p ~/.pi-docker/.pi/agent
cp "$SCRIPT_DIR/$DOCKERFILE_NAME" ~/.pi-docker/Dockerfile
AGENT_DIR="$HOME/.pi-docker/.pi/agent"

# auth.json: user-provided file wins; otherwise keep an existing one; otherwise build one from an OpenRouter key
if [ -n "$AUTH_SRC" ]; then
  cp "$AUTH_SRC" "$AGENT_DIR/auth.json"
elif [ ! -f "$AGENT_DIR/auth.json" ]; then
  KEY="$OPENROUTER_API_KEY"
  if [ -z "$KEY" ]; then
    printf "OpenRouter API key: "
    stty -echo 2>/dev/null; read -r KEY; stty echo 2>/dev/null; echo
  fi
  if [ -z "$KEY" ]; then
    echo "No API key given. Set OPENROUTER_API_KEY or pass an auth.json path." >&2
    exit 1
  fi
  printf '{\n  "openrouter": { "type": "api_key", "key": "%s" }\n}\n' "$KEY" > "$AGENT_DIR/auth.json"
fi
chmod 600 "$AGENT_DIR/auth.json"

# models.json registers the models per provider; settings.json picks the default.
# both are rewritten on every install so a stale copy can't override DEFAULT_MODEL.
printf '{\n  "providers": {\n    "openrouter": {\n      "baseUrl": "https://openrouter.ai/api/v1",\n      "models": [\n        { "id": "%s" }\n      ]\n    }\n  }\n}\n' "$DEFAULT_MODEL" > "$AGENT_DIR/models.json"
printf '{\n  "defaultProvider": "openrouter",\n  "defaultModel": "%s"\n}\n' "$DEFAULT_MODEL" > "$AGENT_DIR/settings.json"

cd ~/.pi-docker
# the container user is uid 1001; make the mounted home writable for it
chmod -R a+rwX ~/.pi-docker 2>/dev/null
chmod 600 "$AGENT_DIR/auth.json"

# build docker image
docker build . -t pi-docker --no-cache || exit 1

# the docker run command itself lives here, not in the rc file, so the alias stays a one-liner
cat > run.sh <<'RUNEOF'
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
  -v "$HOME/.pi-docker:/home/agentuser" \
  -v "$(pwd)":/workspace/$DIRNAME \
  -w /workspace/$DIRNAME \
  pi-docker:latest
RUNEOF
chmod +x run.sh

touch "$INSTALL_LOCATION"

# single alias line: drop any previous one, then append the current one. `pi-docker sh` opens a shell instead.
sed -i.bak '/^alias pi-docker=/d' "$INSTALL_LOCATION" && rm -f "$INSTALL_LOCATION.bak"
echo "alias pi-docker=\"$HOME/.pi-docker/run.sh\"" >> "$INSTALL_LOCATION"

echo "\n\n run: \`pi-docker\` at your project directory to start pi in a docker container"
echo " run: \`pi-docker sh\` at your project directory to open a bash shell in the docker container instead"
echo " default model: openrouter/$DEFAULT_MODEL (change DEFAULT_MODEL in this script and re-run; configs are in $AGENT_DIR/{models,settings}.json)"

echo "\n $INSTALL_LOCATION was updated, but this script's shell can't apply that to your current terminal."
echo " run: \`source $INSTALL_LOCATION\` yourself (or open a new terminal) before using the alias"
