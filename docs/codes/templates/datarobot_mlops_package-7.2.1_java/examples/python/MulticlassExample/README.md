# MulticlassExample

The example shows how to use the MLOps library with a simple scikit-learn model.

## Pre-requisites

1. Before running the Python examples, install the MLOps Python library
   and the Python connected library.

   `pip install lib/datarobot_mlops-*-py2.py3-none-any.whl`
   
   `pip install lib/datarobot_mlops_connected_client-*-py2.py3-none-any.whl`

2. The example code uses various python packages that must be installed.
If you are using Conda environment, install any dependencies with conda tools.
`pip install -r requirements.txt`

## Run the Example

1. First create the model package and initialize the deployment by running:
   `create_deployment.sh`
   
2. Then generate predictions, report statistics and actuals to MLOps by running:
   `run_example.sh`
   
3. You can verify the predictions were uploaded using the verify script:
   `verify_example.sh`
   
4. If you'd like to replace the model package, run:
   `replace_model_package.sh`
   
5. When you are done, you can delete the deployment:
   `cleanup.sh`
