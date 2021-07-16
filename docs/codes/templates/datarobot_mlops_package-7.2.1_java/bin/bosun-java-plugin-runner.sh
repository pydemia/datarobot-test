#!/usr/bin/env bash

if [[ -d ${JAVA_HOME} ]]; then
   JAVA_CMD=${JAVA_HOME}/bin/java
else
   JAVA_CMD=java
fi


JAVA_VER=$(${JAVA_CMD} -version 2>&1 >/dev/null | egrep "\S+\s+version" | awk '{print $3}' | tr -d '"')

if [[ -z "$BOSUN_JAR_PATH" ]]; then
   BOSUN_JAR_PATH=$(ls "$TOP_DIR"/lib/mlops-bosun-plugin-runner-*.jar)
fi

# Can be used to inject extra jars to the class path.
# Like: slf4j-simple-1.7.30.jar to provide a logging backend.
if [[ -n  $EXTRA_CLASS_PATH ]] ; then
  BOSUN_JAR_PATH=$BOSUN_JAR_PATH:$EXTRA_CLASS_PATH
fi

if [[ -z "$BOSUN_LOG_PROPERTIES" ]]; then
   BOSUN_LOG_PROPERTIES="$TOP_DIR"/conf/mlops.bosun.log4j2.properties
elif ! [[ -r "$BOSUN_LOG_PROPERTIES" && -f "$BOSUN_LOG_PROPERTIES" ]]; then
   BOSUN_LOG_PROPERTIES="$TOP_DIR"/conf/mlops.bosun.log4j2.properties
fi


echo "Java cmd:       $JAVA_CMD"
echo "Java version:   $JAVA_VER"
echo "Bosun jar:      $BOSUN_JAR_PATH"
echo "Log properties: $BOSUN_LOG_PROPERTIES"

${JAVA_CMD} ${BOSUN_JVM_OPT} \
     -Dlog4j.configurationFile=file:"${BOSUN_LOG_PROPERTIES}" \
     -cp "${BOSUN_JAR_PATH}" com.datarobot.mlops.bosun.pluginRunner.PluginRunner "$@"


