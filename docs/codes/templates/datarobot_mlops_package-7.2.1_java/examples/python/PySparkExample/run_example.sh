# This example code shows how to use the MLOps library to report metrics from external models into
# DataRobot's model management service.

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

# Make sure Spark is configured
if [[ -z ${SPARK_BIN} ]]; then
    echo "SPARK_BIN needs to be set to the directory containing spark-submit."
    echo "For example, /opt/spark-2.4.5-bin-hadoop2.7/bin"
    exit 1
fi


##--------------------------------------------------------
# Specific configuration for this example

# By default, examples use the filesystem spooler. Ensure that the configured directory exists.
# NOTE: To run on a real Spark cluster, replace the filesystem spooler with one that will work in the cluster environment.
# More details can be found in the "Spooler Configuration" section of the documentation included with the agent tar file.
export MLOPS_SPOOLER_TYPE=FILESYSTEM
export MLOPS_FILESYSTEM_DIRECTORY=/tmp/ta
CHANNEL_CONFIG="--conf spark.executorEnv.MLOPS_SPOOLER_TYPE=${MLOPS_SPOOLER_TYPE} --conf spark.executorEnv.MLOPS_FILESYSTEM_DIRECTORY=${MLOPS_FILESYSTEM_DIRECTORY}"

# Name for the deployment
DEPLOYMENT_NAME="MLOps Example Python PySparkExample"


##--------------------------------------------------------
# Set the deployment ID and model package ID

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
# The predictions loader requires that the model jar use the model ID as the file name.
# Run the example

if [ ! -f "${MLOPS_MODEL_ID}.jar" ]; then
    cp ../../models/CodeGenLendingClubRegressor.jar ./"${MLOPS_MODEL_ID}.jar"
fi

DATA_FILE="../../data/mlops-example-lending-club-regression.csv"

SPARK_OPTS="--num-executors 1 --driver-memory 512m --executor-memory 512m --executor-cores 4"
MLOPS_CONFIG="--conf spark.executorEnv.MLOPS_MODEL_ID=${MLOPS_MODEL_ID} --conf spark.executorEnv.MLOPS_DEPLOYMENT_ID=${MLOPS_DEPLOYMENT_ID}"

JARS="--jars ${PWD}/${MLOPS_MODEL_ID}.jar,${PWD}/../../../lib/datarobot-mlops-7.2.1.jar"

# packages are downloaded from their maven repository locations
PACKAGES="--packages com.datarobot:scoring-code-spark-api_2.4.3:0.0.19"

PROGRAM="pyspark_codegen.py"
SPARK_CMD="${SPARK_BIN}/spark-submit ${SPARK_OPTS} ${MLOPS_CONFIG} ${CHANNEL_CONFIG} ${JARS} ${PACKAGES} ${PROGRAM}"

CMD="${SPARK_CMD} ${DATA_FILE}"
echo "${CMD}"
${CMD}

# If the agent is running (and you have set the deployment ID as indicated above), you will see the statistics
# in the DataRobot UI under the Deployments tab.
echo "Run complete. If the agent is running, check the UI for metrics."
exit 0
