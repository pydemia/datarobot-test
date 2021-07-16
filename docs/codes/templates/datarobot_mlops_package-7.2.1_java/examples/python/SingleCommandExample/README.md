# Single-command Example
This example shows how the MLOps library can be used to initialize and run 
the agent.

For this example, the agent service should not be running. The example itself will start and stop the agent during its run.

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
   `verify.sh`
   
4. When you are done, you can delete the deployment:
   `cleanup.sh`
