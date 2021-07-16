## DataRobot MLOps Monitoring-Agent Docker
This directory contains a script(run.sh) which can be used to build, start, stop and remove DataRobot MLOps Monitoring-Agent Docker Images. 

## Quick Start
### Run DataRobot MLOps Monitoring-Agent with default configuration.

```
$ ./run.sh run
```

## Scripts/Tools
DataRobot MLOps Monitoring-Agent Images can be managed either using the Bash script(run.sh) or Makefile.

### Bash Script Available Commands
```
$ ./run.sh
-----------------------------------------------------------------------
-                      Available Commands                             -
-----------------------------------------------------------------------

	 > usage - Display run.sh Available Commands"
	 > help - Display MLOps Monitoring-Agent help
	 > build - To build the MLOps Monitoring-Agent Docker image
	 > start - To run MLOps Monitoring-Agent container
	 > run - Build MLOps Monitoring-Agent image and start container with defaults
	 > stop - To stop MLOps Monitoring-Agent container
	 > config - To print MLOps Monitoring-Agent config(mlops.agent.conf.yaml)"
	 > remove - To remove the previous MLOps Monitoring-Agent container
	 > generate - To Generate MLOps Monitoring-Agent configuration file.

-----------------------------------------------------------------------
````

### Makefile Available Commands
```
$  make
-----------------------------------------------------------------------
-                      Available Commands                             -
-----------------------------------------------------------------------

	 > usage - Display run.sh Available Commands"
	 > help - Display MLOps Monitoring-Agent help
	 > build - To build the MLOps Monitoring-Agent Docker image
	 > start - To run MLOps Monitoring-Agent container
	 > run - Build MLOps Monitoring-Agent image and start container with defaults
	 > stop - To stop MLOps Monitoring-Agent container
	 > config - To print MLOps Monitoring-Agent config(mlops.agent.conf.yaml)"
	 > remove - To remove the previous MLOps Monitoring-Agent container
	 > generate - To Generate MLOps Monitoring-Agent configuration file.

-----------------------------------------------------------------------
````

## Native Docker examples

Run monitoring agent with configuration mounted from default directory:
```
$ docker run \
	-v /path/to/mlops.agent.conf.yaml:/opt/datarobot/mlops/agent/conf/mlops.agent.conf.yaml \
	datarobot-mlops-agent
```
Run monitoring agent with configuration mounted from custom location:
```
$ docker run \
	-v /path/to/mlops.agent.conf.yaml:/var/tmp \
	-e AGENT_CONF_LOC=/var/tmp \
	datarobot-mlops-agent
```
Run with mlops-agent log directed to stdout:
```
$ docker run \
	-v /path/to/mlops.agent.conf.yaml:/var/tmp \
	-e AGENT_LOG_PROPERTIES=stdout.mlops.log4j2.properties \
	datarobot-mlops-agent
```
