# This example code shows how to use the MLOps library to report metrics from external models into
# DataRobot's model management service.

# The example is uses the local file system by default so that it can be verified locally.
# However, on a real Spark cluster, the channel configuration should be updated to use
# a channel appropriate for a distributed environment, such as RabbitMQ.
# Follow the instructions on the README file to configure the RabbitMQ channel and the agent before running this
# example.

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

DEPLOYMENT_NAME="MLOps Example Java SparkUtilsExample"

# By default, use the file system channel for easy single-machine testing
CHANNEL_CONFIG="spooler_type=filesystem;path=/tmp/ta"

# When running in a Spark cluster, use a distributed channel, such as RabbitMQ.
# This configuration uses the RabbitMQ channel. Make sure the Agent is configured the same way.
#CHANNEL_CONFIG = "spooler_type=rabbitmq;rabbitmq_queue_url=amqp://localhost;rabbitmq_queue_name=spark_example"

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
# Run the example

CODEGEN_JAR="--jars ../../models/CodeGenLendingClubRegressor.jar"
CODEGEN_MODEL_ID="5d4872f6962d7473b5a4d96b"

MODEL_FILE="../../models/CodeGenLendingClubRegressor.jar"
DATA_FILE="../../data/mlops-example-short-lending-club-regression.csv"
SPARK_OPTS="--num-executors 1 --driver-memory 512m --executor-memory 512m --executor-cores 1"
PROGRAM_CLASS="--class com.datarobot.dr_mlops_spark.Main"
PROGRAM_JAR="./target/mlops-spark-utils-example-*-uber.jar"
SPARK_CMD="${SPARK_BIN}/spark-submit ${CODEGEN_JAR} ${PROGRAM_CLASS} ${SPARK_OPTS} ${PROGRAM_JAR}"

CMD="${SPARK_CMD} ${DATA_FILE} ${CODEGEN_MODEL_ID} ${MLOPS_DEPLOYMENT_ID} ${MLOPS_MODEL_ID} ${CHANNEL_CONFIG} "
echo ${CMD}
${CMD}

# If the agent is running (and you have set the deployment ID as indicated above), you will see the statistics
# in the DataRobot UI under the Deployments tab.
echo "Run complete. If the agent is running, check the UI for metrics."
exit 0
