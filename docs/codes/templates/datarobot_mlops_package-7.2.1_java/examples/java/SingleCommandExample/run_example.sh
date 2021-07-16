# This example code shows how to use the MLOps library to report metrics from external models into
# DataRobot's model management service.

##--------------------------------------------------------
# Verify environment

if [[ -z ${MLOPS_API_TOKEN} ]]; then
    echo "MLOPS_API_TOKEN must be set. Set this in config.sh."
    exit 1
fi

if [[ -z ${MLOPS_SERVICE_URL} ]]; then
    echo "MLOPS_SERVICE_URL must be set. Set this in config.sh."
    exit 1
fi

# To run, first set your java home. For example:
if [[ -z ${JAVA_HOME} ]]; then
    if command -v /usr/libexec/java_home >/dev/null 2>&1 ; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 11)
    else
        echo "JAVA_HOME needs to be set to run example."
        exit 1
    fi
fi


##--------------------------------------------------------
# General configuration for all examples

ACTUALS_FILE="actuals.csv"

# By default, examples use the filesystem spooler. Ensure that the configured directory exists.
export MLOPS_SPOOLER_TYPE=FILESYSTEM
export MLOPS_FILESYSTEM_DIRECTORY=/tmp/ta
export MLOPS_SPOOLER_DATA_FORMAT=JSON


##--------------------------------------------------------
# Specific configuration for this example

# Name for the deployment
DEPLOYMENT_NAME="MLOps Example Java SingleCommandExample"


##--------------------------------------------------------
# Get the deployment ID and model package ID

# Get the deployment ID
deployment_id=$( mlops-cli deployment list --search "$DEPLOYMENT_NAME" --terse | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

if [ -z "$deployment_id" ]; then
  echo "Run ./create_deployment.sh to create the deployment before running this script."
  exit 1
fi
export MLOPS_DEPLOYMENT_ID=$deployment_id

model_id=$( mlops-cli deployment get-model --deployment-id $deployment_id )

export MLOPS_MODEL_ID=$model_id


##--------------------------------------------------------
# Run the example

INPUT_FILE="../../data/mlops-example-surgical-dataset.csv"
ARGS="--mlops-url ${MLOPS_SERVICE_URL} --token ${MLOPS_API_TOKEN} --features-csv ${INPUT_FILE}"

# If you want to use a CodeGen model, uncomment and fill in these lines.
#CODEGEN_FILE=<path to CodeGen file>
#ARGS="${ARGS} --model-jar ${CODEGEN_FILE}"

echo ""
JAVA_CMD="java -jar target/mlops-singlecommand-example-*.jar"
# Then execute the JAR file.
CMD="${JAVA_CMD} ${ARGS}"
echo ${CMD}
echo "Running the example..."
${CMD}

echo "Run complete. Check UI for metrics."
exit 0
