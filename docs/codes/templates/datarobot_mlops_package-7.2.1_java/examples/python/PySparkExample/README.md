# PySpark Example

This example demonstrates using MLOps library integration with PySpark. 

## Pre-requisites

1. Configure and start the MLOps agent. See instructions in
`file://<agent_tar_dir>/docs/html/quickstart.html`

2. Before running the Python examples, install the MLOps Python library.
`pip install lib/datarobot_mlops-*-py2.py3-none-any.whl`

3. The example code uses various python packages that must be installed.
If you are using Conda environment, install any dependencies with conda tools.
`pip install -r requirements.txt`

4. Since this example uses MLOpsSparkUtils, install the datarobot-mlops jar into
your local mvn repository before testing the examples by running:
`cd examples/java; install_jar_into_maven.sh`

5. Install Spark locally.
- Download Spark 3.1.1 built for Hadoop 2.7 onto your local machine: http://spark.apache.org/downloads.html
- Unarchive the tarball: `tar xvf ~/Downloads/spark-2.4.5-bin-hadoop2.7.tgz`
- In the created `spark-3.1.1` directory, start you spark cluster:
  - `sbin/start-master.sh -i localhost`
  - `sbin/start-slave.sh -i localhost -c 8 -m 2G spark://localhost:7077`
- Ensure your installation is successful: `bin/spark-submit --class org.apache.spark.examples.SparkPi --master spark://localhost:7077 --num-executors 1 --driver-memory 512m --executor-memory 512m --executor-cores 1 examples/jars/spark-examples_2.12-3.1.1.jar 10`

## Run the Example

1. First create the model package and initialize the deployment by running:
   `create_deployment.sh`

2. Then generate predictions and report statistics to MLOps by running:
   `run_example.sh`
   
3. You can verify the predictions were uploaded using the verify script:
   `verify.sh`
   
4. When you are done, you can delete the deployment:
   `cleanup.sh`