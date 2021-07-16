# Creates a model package and replaces it the deployment's existing package.


if [[ -z ${MLOPS_SERVICE_URL} ]]; then
    echo "MLOPS_SERVICE_URL needs to be set."
    exit 1
fi

if [[ -z ${MLOPS_API_TOKEN} ]]; then
    echo "MLOPS_API_TOKEN needs to be set."
    exit 1
fi

##--------------------------------------------------------
# General configuration for all examples

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EXAMPLES_DIR="${DIR}/../.."
MODEL_CONFIG_DIR="${EXAMPLES_DIR}/model_config"
DATA_DIR="${EXAMPLES_DIR}/data"


##--------------------------------------------------------
# Specific configuration for this example

# Multiclass support is currently behind an MLOps feature flag
export MLOPS_IS_MULTICLASS_ENABLED=true

TRAINING_DATA="mlops-example-iris-samples"
TRAINING_DATA_FILE="${DATA_DIR}/${TRAINING_DATA}.csv"

MODEL_PACKAGE_NAME="MLOps Example Replacement Iris classifier"
MODEL_CONFIG_FILE="${MODEL_CONFIG_DIR}/iris_multi_classification_updated.json"

# Name for the deployment
DEPLOYMENT_NAME="MLOps Example Python MultiClassExample"


##--------------------------------------------------------
# Get the deployment ID

# Get the deployment ID
deployment_id=$( mlops-cli deployment list --search "$DEPLOYMENT_NAME" --terse | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

if [ -z "$deployment_id" ]; then
  echo "Run ./create_deployment.sh to create the deployment before running this script."
  exit 1
fi
echo Deployment ID is $deployment_id.

##----------------------------------------------------
# Load the training dataset

# Check whether this dataset was previously uploaded.
cmd="mlops-cli dataset list --search $TRAINING_DATA --terse"
# echo $cmd
training_set_id=$( $cmd | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

# This dataset was not previously uploaded, so do that now.
if [ -z "$training_set_id" ]; then
  echo "Uploading training dataset $TRAINING_DATA This may take some time..."
  cmd="mlops-cli dataset upload --input $TRAINING_DATA_FILE --timeout 600 --terse"
  # echo $cmd
  training_set_id=$( $cmd )
  if [ $? -ne 0 ]; then
    echo "Failed to load dataset before timeout. Exiting."
    exit 1
  fi
  echo "Upload complete."
fi

if [ -z "$training_set_id" ]; then
  echo "Failed to get dataset ID. Exiting."
  exit 1
fi
echo "Training dataset ID is $training_set_id."


##----------------------------------------------------
# Create the model package

# Check whether this model package was previously created.
model_package_id=$( mlops-cli model list --search "$MODEL_PACKAGE_NAME" --terse | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

# No previously created model package. Create a new one.
if [ -z "$model_package_id" ]; then
  echo "Creating model package..."
  model_package_id=$( mlops-cli model create --json-config $MODEL_CONFIG_FILE --training-dataset-id $training_set_id --terse)
  if [ $? -ne 0 ]; then
    echo "Failed to create model package. Exiting."
    exit 1
  fi
fi

if [ -z "$model_package_id" ]; then
  echo "Failed to get model package ID. Exiting."
  exit 1
fi
echo "Model package ID is $model_package_id."


##----------------------------------------------------
# Replace the model package

previous_model_id=$( mlops-cli deployment get-model --deployment-id $deployment_id )
echo Previous model ID is $previous_model_id.

echo Replacing model package. This may take some time...
mlops-cli model replace --deployment-id $deployment_id --model-package-id $model_package_id
if [ $? != 0 ]; then
  echo Model replacement failed. This can happen if the model was already replaced previously.
  exit 1
fi

new_model_id=$( mlops-cli deployment get-model --deployment-id $deployment_id )
echo New model ID is $new_model_id.

if [ "$previous_model_id" == "$new_model_id" ]; then
  echo Model replacement failed.
  exit 1
fi

echo Successfully replaced model. New model id is $new_model_id.

##----------------------------------------------------

