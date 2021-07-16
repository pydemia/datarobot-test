# MLOps Tracking Agent

## [7.2]
* Upgrade from Java8 to Java11
* Migrate examples to use mlops-cli

## [7.1]
* Management Agent beta release
* Support for kafka channel
* mlops-cli functionality improvments
* Change file spooler format to json
* Add debugging to agent startup
* Support disconnected operation in CodeGen integration
* Add support for json format of file system spooler
* mlops-cli support for reading json file system spooler data and uploading to DataRobot MLOps
* mlops-cli support for prediction environments
* mlops reporting and connected libraries split into separate wheels
* UI added to agent

## [7.0] 
* Support for multi-class models (beta)
* Updated Python Spark example to use Spark utils lib and CodeGen model
* Added more logging and debugging statements
* Updated logic to stop agent when run internally from the Python MLOps lib
* Update mlops-cli tool with more functionality
* Handle Decimal type when reporting feature data
* Minor fixes and usability issues fixed in examples
* Bug fixes for the agent Docker
* Release Note: py4j version issue.
  * Description: Installing any Python application (e.g., pyspark) that requires py4j==0.10.9 may affect the functionality
    of MLOps library and DataRobot User Models (DRUM) in terms of starting the py4j gateway server.
  * Workaround: Uninstall the older version of py4j and re-install a newer version. 
      `pip uninstall py4j==0.10.9`
      `pip install py4j>=0.10.9.1`


## [6.3] - 2020-11-13
* Added multi-model support for mlops reporting library for Python and Java.

* Added mlops-cli client to the mlops Python library
   * Once the mlops-py whl file is installed, you have access to `mlops-cli`
   * Documented with `mlops-cli --help`
   * Allows reporting of csv datasets directly to DataRobot MLOps bypassing agent
   * Provides uploading of actuals
   * Provides basic performance testing
* Added verifySSL parameter to Agent configuration
   * Allows skipping SSL certificate verification
   * Supported by python client in wheel
* Support for running the Agent in a Docker is included. See documentation in tools/agent_docker.
* Fixed race conditions in asynchronous reporting in mlops reporting library for Python and Java. Changed the default to be synchronous.
* Changed implementation of reportClassificationPredictionsSc and reportRegressionPredictionSc to use
  reportPredictionsData
* Known Issues
  * Python using SQS spooler does not reconnect if it becomes disconnected from SQS
  * The portable prediction server (PPS) does not work with the PubSub spooler.
  * PPS using RabbitMQ spooler issues error messages during initial start up.

## [6.2] - 2020-08-14
* Update spool setting interfaces in MLOps libs
* Add Spark util interface
* Add the ability to report actuals through the agent and mlops-java
* Update names of environment variables
* Add PubSub spooler type

## [6.1] - 2020-05-18
* MLOps Java library - reportPredictionsDataList interface added.

## [6.0] - 2020-02-26
* API reportPredictionsData() was added
* APIs reportClassificationPredictions()/reportRegressionPredictions()/reportFeatureData() has been depricated
* new SQS channel has been added

## [5.3] - 2019-11-27

### Changed
* This is an early release of the MLOps agent and, as such, interfaces are subject to change.
* For this release, the MLOps agent runs on Linux.
