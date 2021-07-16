# Spark Monitoring Example

A common use case for the MLOps Agent is to monitor scoring of Spark environments. In this case, the user is
performing scoring in Spark and would like to report the predictions and features to the MLOps system. Since Spark
is usually using a multi-node setup, using the spool file channel in MLOps would be hard to configure since
a shared consistent file system is not common in Spark installations.

The solution here would be to use a network-based channel like RabbitMQ or AWS SQS.
These channels can work with multiple writers and single (or multiple) readers.
In this section we will go over the steps to setup MLOps monitoring on a Spark system.

This example demonstrates using the MLOps Spark Util module.
This module provides a way to report scoring results done on
the Spark framework. Documentation of the MLOpsSparkUtils module is provided in the MLOps 
Java lib documentation. 

Note: this example can be found in the examples/java/SparkUtilsExample/ directory. 

The example's source code is performing 3 steps:
1. Given a scoring jar file, score data and get the results in a Dataframe.
2. Take the features Dataframe + the predictions results and merge them into a single Dataframe.
3. Call the MLOps.MLOpsSparkUtils.reportPredictions helper to report the predictions using the above Dataframe.

In general the  MLOps.MLOpsSparkUtils.reportPredictions can be used to report predictions done by any model as long
as the function is getting the data via a Dataframe.

This example is initially set up with the file system channel 
for quick no-configuration testing on a single machine.
To run on a cluster, you must update the example with a channel configuration that supports
distributed systems, such as RabbitMQ.
Below, we cover how to setup a RabbitMQ channel and update this example appropriately.

## Pre-requisites

1. If running on a cluster, set up a distributed channel, such as RabbitMQ. For example:
    - `docker run -d -p 15672:15672 -p 5672:5672 --name rabbit-test-for-medium rabbitmq:3-management`
    - This command will run also the management console for RabbitMQ. 
    - You can access it via your browser in http://localhost:15672 

2. In case you want to change the spooler type (communication channel between the Spark job and the MLOps Agent):
    - Edit the CHANNEL_CONFIG variable in the run_example.sh script.
   
3. Configure and start the MLOps agent. 
    - See instructions in file://<agent_tar_dir>/docs/html/quickstart.html
    - You need to setup the agent to talk with the RabbitMQ configured in the previous section.
    - The agent channel config should look like: 

        ```
        type: "RABBITMQ_SPOOL"
        details: {name: "rabbit", queueUrl: "amqp://localhost:5672", queueName: "spark_example" }
        ```

4. If you are using mvn, install the datarobot-mlops jar into
your local mvn repository before testing the examples by running:
`install_jar_into_maven.sh`. This script is located in the examples/java/ directory.

5. Use `make` to create the needed java jar files.

6. Set your JAVA_HOME environment variable, for example:
export JAVA_HOME=`/usr/libexec/java_home -v 11`

7. Install Spark locally.
    - Download Spark 2.4.5 built for Hadoop 2.7 onto your local machine: http://spark.apache.org/downloads.html
    - Unarchive the tarball: `tar xvf ~/Downloads/spark-2.4.5-bin-hadoop2.7.tgz`
    - In the created `spark-2.4.5` directory, start you spark cluster:
        - `sbin/start-master.sh -i localhost`
        - `sbin/start-slave.sh -i localhost -c 8 -m 2G spark://localhost:7077`
    - Ensure your installation is successful: 
 
        ```
        bin/spark-submit --class org.apache.spark.examples.SparkPi --master spark://localhost:7077 --num-executors 1 --driver-memory 512m --executor-memory 512m --executor-cores 1 examples/jars/spark-examples_2.11-2.4.5.jar 10
        ```

8. To use the provided scripts, install the MLOps Python connected library.

   `pip install lib/datarobot_mlops_connected_client-*-py2.py3-none-any.whl`


## Run the Example

1. First create the model package and initialize the deployment by running:
   `create_deployment.sh`

2. Then generate predictions, report statistics and actuals to MLOps by running:
   `run_example.sh`
   
3. You can verify the predictions were uploaded using the verify script:
   `verify_example.sh`
   
4. When you are done, you can delete the deployment:
   `cleanup.sh`

