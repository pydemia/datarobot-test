# This script is used to verify that statistics run in the example are successfully
# uploaded into DataRobot MLOps.

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
DEPLOYMENT_NAME="MLOps Example Java SparkUtilsExample"
EXPECTED_PREDICTIONS=2


##--------------------------------------------------------
# Get the deployment ID

deployment_id=$( mlops-cli deployment list --search "$DEPLOYMENT_NAME" --terse | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

if [ -z "$deployment_id" ]; then
  echo "Run ./create_deployment.sh to create the deployment before running this script."
  exit 1
fi

##--------------------------------------------------------
# Verify that DataRobot MLOps received the expected number of predictions

service_preds=$(mlops-cli service-stats get --deployment-id $deployment_id  | grep "totalPredictions" | sed 's/^.*: //' | sed 's/,//')
echo service_preds $service_preds
if [ "$service_preds" -lt "$EXPECTED_PREDICTIONS" ]; then
  echo "Service stats expected $EXPECTED_PREDICTIONS but received $service_preds."
  exit 1
fi


reported_preds=$(mlops-cli predictions get --deployment-id $deployment_id | grep "predictionsCount" | head -n 1 | sed 's/^.*: //' | sed 's/,//')
echo reported_preds $reported_preds
if [ "$reported_preds" -lt "$EXPECTED_PREDICTIONS" ]; then
  echo "Prediction stats expected $EXPECTED_PREDICTIONS but received $reported_preds."
  exit 1
fi

echo "Success: found expected metrics."
exit 0
