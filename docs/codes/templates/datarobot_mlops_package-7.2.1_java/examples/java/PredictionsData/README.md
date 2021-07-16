# PredictionsData

This example code shows how to use the MLOps library to report predictions data to DataRobot MLOps.

Running the example will generate a file of prediction outcomes, which can be uploaded to view accuracy
of the predictions versus the outcomes in DataRobot MLOps.

## Pre-requisites

1. This example uses mlops-cli to upload statistics to DataRobot MLOps rather than the agent.
   Ensure the Python connected library is installed.
   
   `pip install lib/datarobot_mlops_connected_client-*-py2.py3-none-any.whl`

2. If you are using mvn, install the datarobot-mlops jar into
your local mvn repository before testing the examples by running:
   `install_jar_into_maven.sh`

3. Use `make` to create the needed java jar files.

4. Set your JAVA_HOME environment variable, for example:
export JAVA_HOME=`/usr/libexec/java_home -v 11`

## Run the Example

1. First create the model package and initialize the deployment by running:
   `create_deployment.sh`
   
2. Then generate predictions, report statistics and actuals to MLOps by running:
   `run_example.sh`
   
3. You can verify the predictions were uploaded using the verify script:
   `verify_example.sh`
   
4. When you are done, you can delete the deployment:
   `cleanup.sh`
