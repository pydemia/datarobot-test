# This script will cleanup state left in DataRobot MLOps after running the examples.
# Note that the cleanup scripts for specific examples must be run first.

#
NAME="MLOps Example"

##----------------------------------------------------
# Delete the prediction environment

pe_id=$( mlops-cli prediction-environment list --search "$NAME" --terse | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

if [ -z "$pe_id" ]; then
  echo "No prediction environment id found."
else
  echo "Deleting prediction environment with ID $pe_id."
  mlops-cli prediction-environment delete --prediction-environment-id $pe_id
  if [ $? -ne 0 ]; then
    echo "Failed to delete the prediction environment."
  fi
fi


##----------------------------------------------------
# Delete the model packages

model_package_ids=$( mlops-cli model list --search "$NAME" --terse | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

if [ -z "$model_package_ids" ]; then
  echo "No model package id found."
else
  model_package_list=$(echo $model_package_ids | tr "," "\n")
  for model_package_id in $model_package_list; do
    echo "Deleting model package with id $model_package_id."
    mlops-cli model delete --model-package-id $model_package_id
    if [ $? -ne 0 ]; then
      echo "Failed to delete the model package $model_package_id"
    fi
  done
fi


##----------------------------------------------------
# Delete the training/holdout datasets

dataset_ids=$( mlops-cli dataset list --search "mlops-example" --terse | sed 's/\[//' | sed 's/\]//' | sed 's/\"//g' )

if [ -z "$dataset_ids" ]; then
  echo "No datasets found."
else
  dataset_id_list=$(echo $dataset_ids | tr "," "\n")
  for dataset_id in $dataset_id_list; do
    echo "Deleting dataset with id $dataset_id."
    mlops-cli dataset delete --dataset-id $dataset_id
    if [ $? -ne 0 ]; then
      echo "Failed to delete dataset $dataset_id"
    fi
  done
fi
