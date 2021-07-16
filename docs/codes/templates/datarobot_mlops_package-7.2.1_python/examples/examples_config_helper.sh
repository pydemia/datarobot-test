# examples helper
# reads MLOPS service url and user api token from agent config file

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MLOPS_AGENT_CONF="$DIR/../conf/mlops.agent.conf.yaml"

MLOPS_CONF_KEY="mlopsUrl:"
MLOPS_SERVICE_URL=$(grep ^$MLOPS_CONF_KEY $MLOPS_AGENT_CONF)
# remove conf key from the string
MLOPS_SERVICE_URL=${MLOPS_SERVICE_URL//$MLOPS_CONF_KEY/}
# remove spaces and quotes from the string
MLOPS_SERVICE_URL="$(echo -e "${MLOPS_SERVICE_URL}" | tr -d '[:space:]"')"

TOKEN_CONF_KEY="apiToken:"
MLOPS_API_TOKEN=$(grep ^$TOKEN_CONF_KEY $MLOPS_AGENT_CONF)

# remove conf key from the string
MLOPS_API_TOKEN=${MLOPS_API_TOKEN//$TOKEN_CONF_KEY/}
# remove spaces and quotes from the string
MLOPS_API_TOKEN="$(echo -e "${MLOPS_API_TOKEN}" | tr -d '[:space:]"')"


MODEL_CONFIG_DIR="$DIR/model_config"
DATA_DIR="$DIR/data"
TOOLS_DIR="$DIR/../tools"
