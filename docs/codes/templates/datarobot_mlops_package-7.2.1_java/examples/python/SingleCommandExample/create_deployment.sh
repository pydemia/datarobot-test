# Creates a model package from the configuration and creates an external deployment for it.

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
PE_CONFIG_DIR="${EXAMPLES_DIR}/prediction_environment_config"


##--------------------------------------------------------
# Specific configuration for this example

TRAINING_DATA="mlops-example-surgical-dataset"
TRAINING_DATA_FILE="${DATA_DIR}/${TRAINING_DATA}.csv"

MODEL_PACKAGE_NAME="MLOps Example Surgical Model"
MODEL_CONFIG_FILE="${MODEL_CONFIG_DIR}/surgical_binary_classification.json"

# Prediction environment configuration
PE_NAME="MLOps Example PE"
PE_CONFIG_FILE="${PE_CONFIG_DIR}/test_pe.json"

# Name for the deployment
DEPLOYMENT_NAME="MLOps Example Python SingleCommandExample"


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
# Create the prediction environment

# Check whether this prediction environment was previously created.
pe_id=$( mlops-cli prediction-environment list --search "$PE_NAME" --terse | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

# No previously created prediction environment. Create a new one.
if [ -z "$pe_id" ]; then
  echo "Creating prediction environment..."
  pe_id=$( mlops-cli prediction-environment create --json-config $PE_CONFIG_FILE --terse )
  if [ $? -ne 0 ]; then
    echo "Failed to create prediction environment. Exiting."
    exit 1
  fi
fi

if [ -z "$pe_id" ]; then
  echo "Failed to get prediction environment ID. Exiting."
  exit 1
fi
echo "Prediction environment ID is $pe_id."


##----------------------------------------------------
# Create the deployment

# Check whether this deployment was previously created.
deployment_id=$( mlops-cli deployment list --search "$DEPLOYMENT_NAME" --terse | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

# No previously created deployment. Create a new one.
if [ -z "$deployment_id" ]; then
  echo "Deploying the model package to the prediction environment. This may take some time..."
  deployment_id=$( mlops-cli model deploy --model-package-id $model_package_id --prediction-environment-id $pe_id --deployment-label "$DEPLOYMENT_NAME" --terse )
  if [ $? -ne 0 ]; then
    echo "Failed to deploy model package before timeout. Exiting."
    exit 1
  fi
fi

if [ -z "$deployment_id" ]; then
  echo "Failed to get deployment ID. Exiting."
  exit 1
fi
echo "Deployment ID is $deployment_id."
echo "Successfully created and deployed the model package."
exit 0
