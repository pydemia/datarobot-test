## DataRobot MLOps Management-Agent Docker
This directory contains a script(run.sh) which can be used to build, start, stop and remove DataRobot MLOps Management-Agent Docker Images. 

## Quick Start
### Run DataRobot MLOps Management-Agent with default configuration.

```
$ ./run.sh run
```

## Scripts/Tools
DataRobot MLOps Management-Agent Images can be managed either using the Bash script(run.sh) or Makefile.

### Bash Script Available Commands
```
$ ./run.sh
-----------------------------------------------------------------------
-                      Available Commands                             -
-----------------------------------------------------------------------

	 > usage - Display run.sh Available Commands"
	 > help - Display MLOps Management-Agent help
	 > build - To build the MLOps Management-Agent Docker image
	 > start - To run MLOps Management-Agent container
	 > run - Build MLOps Management-Agent image and start container with defaults
	 > stop - To stop MLOps Management-Agent container
	 > config - To print MLOps Management-Agent config(mlops.bosun.conf.yaml)"
	 > remove - To remove the previous MLOps Management-Agent container
	 > generate - To Generate MLOps Management-Agent configuration file.

-----------------------------------------------------------------------
````

### Makefile Available Commands
```
$  make
-----------------------------------------------------------------------
-                      Available Commands                             -
-----------------------------------------------------------------------

	 > usage - Display run.sh Available Commands"
	 > help - Display MLOps Management-Agent help
	 > build - To build the MLOps Management-Agent Docker image
	 > start - To run MLOps Management-Agent container
	 > run - Build MLOps Management-Agent image and start container with defaults
	 > stop - To stop MLOps Management-Agent container
	 > config - To print MLOps Management-Agent config(mlops.bosun.conf.yaml)"
	 > remove - To remove the previous MLOps Management-Agent container
	 > generate - To Generate MLOps Management-Agent configuration file.

-----------------------------------------------------------------------
````

## Native Docker examples

Run management agent with configuration mounted from default directory:
```
$ docker run \
	-v /path/to/mlops.bosun.conf.yaml:/opt/datarobot/mlops/bosun/conf/mlops.bosun.conf.yaml \
	datarobot-mlops-bosun
```
Run management agent with configuration mounted from custom location:
```
$ docker run \
	-v /path/to/mlops.bosun.conf.yaml:/var/tmp \
	-e BOSUN_CONF_LOC=/var/tmp \
	datarobot-mlops-bosun
```
Run with mlops-bosun log directed to stdout:
```
$ docker run \
	-v /path/to/mlops.bosun.conf.yaml:/var/tmp \
	-e BOSUN_LOG_PROPERTIES=stdout.mlops.log4j2.properties \
	datarobot-mlops-bosun
```
