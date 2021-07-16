# This script will install the datarobot-mlops jar file into the local mvn repository

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

JAR_FILE=$(ls $DIR/../../lib/datarobot-mlops-*.jar)
JAR_FILE_BASENAME=$(basename $JAR_FILE)

# delete longest match of pattern from the beginning
VERS=${JAR_FILE_BASENAME##*-}
# delete shortest match of pattern from the end
JAR_VERSION=${VERS%.jar}

AGENT_JAR=$(ls $DIR/../../lib/mlops-agent-*jar)
AGENT_JAR_BASENAME=$(basename $AGENT_JAR)
VERS=${AGENT_JAR_BASENAME##*-}
AGENT_VERSION=${VERS%.jar}

mvn install:install-file \
   -Dfile=$JAR_FILE \
   -DgroupId=com.datarobot \
   -DartifactId=datarobot-mlops \
   -Dversion=$JAR_VERSION \
   -Dpackaging=jar \
   -DgeneratePom=true

mvn install:install-file \
   -Dfile=$AGENT_JAR \
   -DgroupId=com.datarobot \
   -DartifactId=mlops-agent \
   -Dversion=$AGENT_VERSION \
   -Dpackaging=jar \
   -DgeneratePom=true
