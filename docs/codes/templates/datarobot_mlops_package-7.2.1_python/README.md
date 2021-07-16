# MLOps agent installation and usage

## Unpack the MLOps Tar File

```
> tar -xvf datarobot_mlops_package-*.tar.gz
```

## MLOps Tracking Agent

### Update the configuration file

```
> cd datarobot_mlops_package-*;
> <your-favorite-editor> ./conf/mlops.agent.conf.yaml
```

### Run the MLOps agent

#### Start the agent using the config file

```
> cd datarobot_mlops_package-*;
> ./bin/start-agent.sh
```

#### Alternatively, start the agent using environment variables

```
> export AGENT_CONFIG_YAML=<path/to/conf/mlops.agent.conf.yaml> ; \
         export AGENT_LOG_PROPERTIES=<path/to/conf/mlops.log4j2.properties>; \
         export AGENT_JVM_OPT=-Xmx4G \
         export AGENT_JAR_PATH=<path/to/bin/mlops-agent-ver.jar> \
         sh -x /bin/start-agent.sh

 # AGENT_CONFIG_YAML      environmment variable to override the default path to mlops.agent.conf.yaml
 # AGENT_LOG_PROPERTIES   environmment variable to override the default path to mlops.log4j2.properties
 # AGENT_JVM_OPT          environmment variable to override the default JVM option `-Xmx4G`
 # AGENT_JAR_PATH         environmment variable to override the default JAR file path to agent-<ver>.jar
```

### Check agent status

```
> ./bin/status-agent.sh
```

### Get agent status with real-time resource usage

```
> ./bin/status-agent.sh --verbose
```

### Shut down the agent

```
> ./bin/stop-agent.sh
```

---

## MLOps Management Agent

### Manage Kubernetes Infrastructure

If you are looking for information on the built-in Kubernetes support of the Management Agent, browse to the `tools/charts` directory for
information on how to [get started](./tools/charts/README.md) installing the management agent into your cluster and configuring it to deploy
models there.

### Update the configuration file

```
> cd datarobot_mlops_package-*;
> <your-favorite-editor> ./conf/mlops.bosun.conf.yaml
```

### Run the MLOps Bosun Service

#### Start the bosun using the config file


```
> cd datarobot_mlops_package-*;
> ./bin/start-bosun.sh
```

#### Alternatively, start the bosun using environment variables

```
> export BOSUN_CONFIG_YAML=<path/to/conf/mlops.bosun.conf.yaml> ; \
         export BOSUN_LOG_PROPERTIES=<path/to/conf/mlops.log4j2.properties>; \
         export BOSUN_JVM_OPT=-Xmx4G \
         export BOSUN_JAR_PATH=<path/to/bin/mlops-agent-ver.jar> \
         sh -x /bin/start-bosun.sh

 # BOSUN_CONFIG_YAML      environment variable to override the default path to mlops.bosun.conf.yaml
 # BOSUN_LOG_PROPERTIES   environment variable to override the default path to mlops.log4j2.properties
 # BOSUN_JVM_OPT          environment variable to override the default JVM option `-Xmx4G`
 # BOSUN_JAR_PATH         environment variable to override the default JAR file path to agent-<ver>.jar
```

### Check bosun status

```
> ./bin/status-bosun.sh
```

### Get bosun status with real-time resource usage

```
> ./bin/status-bosun.sh --verbose
```

### Shut down the bosun

```
> ./bin/stop-bosun.sh
```
