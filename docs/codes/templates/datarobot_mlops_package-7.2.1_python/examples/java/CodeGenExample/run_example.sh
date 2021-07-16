# This example code shows how to use the MLOps library to report metrics from external models into
# DataRobot's model management service.

# First set your deployment ID and model ID. These can be obtained by running the script
# create_deployment.sh

##--------------------------------------------------------
# Verify environment

if [[ -z ${MLOPS_SERVICE_URL} ]]; then
    echo "MLOPS_SERVICE_URL needs to be set."
    exit 1
fi

if [[ -z ${MLOPS_API_TOKEN} ]]; then
    echo "MLOPS_API_TOKEN needs to be set."
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
DEPLOYMENT_NAME="MLOps Example Java CodeGenExample"

MODEL_FILE="../../models/CodeGenLendingClubRegressor.jar"
DATA_FILE="../../data/mlops-example-lending-club-regression.csv"


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

# Then execute the JAR file.
echo ""
echo "Running CodeGen regression example..."
java -jar target/mlops-codegen-example-*.jar ${MODEL_FILE} ${DATA_FILE} ${ACTUALS_FILE}

echo "Reporting predictions to DataRobot MLOps"
mlops-cli predictions report --from-spool

echo "Reporting actuals to DataRobot MLOps"
mlops-cli actuals report --input $ACTUALS_FILE --actual-value-col actualValue --assoc-id-col associationId

echo "Run complete. Check UI for metrics."
exit 0

