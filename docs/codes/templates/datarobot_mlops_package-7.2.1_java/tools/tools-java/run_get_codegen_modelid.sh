# This example code shows how to run the java program that can extract the modelId from a CodeGen jar file.

if [ "$1" == "" ]; then
  echo "Usage: $0 <CodeGen jar file path>"
  exit 1
fi

MODEL_PATH=$1

# To run, first set your java home. For example:
export JAVA_HOME=`/usr/libexec/java_home -v 11`

# Then execute the JAR file.
java -jar target/mlops-tools-getmodelid-0.1.0.jar ${MODEL_PATH}
