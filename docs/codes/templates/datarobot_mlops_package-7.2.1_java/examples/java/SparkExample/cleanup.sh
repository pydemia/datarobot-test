# Delete the deployment from DataRobot MLOps.
# Cleanup any temporary files.

##--------------------------------------------------------
# Verify environment

if [[ -z ${MLOPS_SERVICE_URL} ]]; then
    echo "MLOPS_SERVICE_URL needs to be set."
    exit 1
fi

if [[ -z ${MLOPS_API_TOKEN} ]]; then
    echo "MLOPS_API_TOKEN needs to be set."
    exit 1
fi

##--------------------------------------------------------
# Specific configuration for this example

# Name for the deployment
DEPLOYMENT_NAME="MLOps Example Java SparkExample"


##--------------------------------------------------------
# Delete the deployment

# Get the deployment ID
deployment_id=$( mlops-cli deployment list --search "$DEPLOYMENT_NAME" --terse | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

# Delete the deployment from DataRobot MLOps
if [ ! -z $deployment_id ]; then
  echo "Deleting deployment with ID $deployment_id."
  mlops-cli deployment delete --deployment-id $deployment_id
  if [ $? -ne 0 ]; then
    echo "Failed to delete the deployment."
    exit 1
  fi
fi

exit 0

