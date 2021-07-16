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

# To run, first set your java home. For example:
if [[ -z ${JAVA_HOME} ]]; then
    if command -v /usr/libexec/java_home >/dev/null 2>&1 ; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 11)
    else
        echo "JAVA_HOME needs to be set to run example."
        exit 1
    fi
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
export MLOPS_SPOOLER_DATA_FORMAT=JSON
CHANNEL_CONFIG="--conf spark.executorEnv.MLOPS_SPOOLER_TYPE=${MLOPS_SPOOLER_TYPE} --conf spark.executorEnv.MLOPS_FILESYSTEM_DIRECTORY=${MLOPS_FILESYSTEM_DIRECTORY}"

# Name for the deployment
DEPLOYMENT_NAME="MLOps Example Java SparkExample"


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

# If using CodeGen model, uncomment these.
CODEGEN_JAR="--jars ../../models/CodeGenLendingClubRegressor.jar"
MODEL_ID="5d4872f6962d7473b5a4d96b"

# Then execute the JAR file.
MODEL_FILE="../../models/CodeGenLendingClubRegressor.jar"
DATA_FILE="../../data/mlops-example-lending-club-regression.csv"
SPARK_OPTS="--num-executors 1 --driver-memory 512m --executor-memory 512m --executor-cores 1"
PROGRAM_CLASS="--class com.datarobot.dr_mloa_spark.Main"
PROGRAM_JAR="./target/mlops-spark-example-*-uber.jar"
SPARK_CMD="${SPARK_BIN}/spark-submit ${CODEGEN_JAR} ${PROGRAM_CLASS} ${SPARK_OPTS} ${PROGRAM_JAR}"

CMD="${SPARK_CMD} ${DATA_FILE} ${MODEL_ID}"
echo ${CMD}
${CMD}

# If the agent is running (and you have set the deployment ID as indicated above), you will see the statistics
# in the DataRobot UI under the Deployments tab.
echo "Run complete. If the agent is running, check the UI for metrics."
exit 0