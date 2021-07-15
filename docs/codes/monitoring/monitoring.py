"""
Usage:
     DataRobot's Monitoring Agent is an advanced feature that enables monitoring for models deployed
     outside of DataRobot. Follow these steps to use this feature.
    1. Download and extract DataRobot's Monitoring Agent tar file. This is available through the
       DataRobot MLOps UI via User icon -> "Developer Tools" -> "External Monitoring Agent".
    2. Open your preferred browser. In toolbar, click "File" -> "Open File".
       Then choose this file <your unpacked directory>/docs/html/quickstart.html.
    3. Follow the "Quick Start" instructions to set up Monitoring Agent.
    4. This example uses DataRobot's MLOps Python library which you can install with:
       pip install <unpacked DataRobot's Monitoring Agent tar file>/lib/datarobot_mlops-*-py2.py3-none-any.whl
    5. The MLOps library requires the following parameters to be provided:
       deployment ID, model ID, and spooler type [FILESYSTEM, SQS, RABBITMQ, PUBSUB, STDOUT, NONE].
       The spooler type selected may require additional configuration. For example,
       if the spooler type is FILESYSTEM, the filesystem directory will have to be configured.
       The spooler directory path must match the Monitoring Agent path configured by the administrator.
       For more details and advanced usage, see the examples and documentation included with the agent tar file.
       These parameters can be configured with the MLOps library APIs or with environment variables.
       For example:
       # export MLOPS_DEPLOYMENT_ID=60f0443ed7733e8161155078
       # export MLOPS_MODEL_ID=60f03f8e0a3504f0d3764a06
       # export MLOPS_SPOOLER_TYPE=FILESYSTEM
       # export MLOPS_FILESYSTEM_DIRECTORY=/tmp/ta
 
       Notes:
              - parameter configuration via environment variables takes precedence over the API.
              - for testing purposes, you can start with STDOUT output type,
                which doesn't require providing any of the spooler-related parameters. The reporting results
                are sent to stdout and not forwarded to the Monitoring Agent or DataRobot MLOps.
              - complete examples are included in the agent tar file in the `examples` directory.
    6. Run current snippet:
       python datarobot-report-stats.py
"""
 
import sys
import time
import random
import pandas as pd
 
from datarobot.mlops.mlops import MLOps
from datarobot.mlops.common.enums import OutputType
 
DEPLOYMENT_ID = '60f0443ed7733e8161155078'
MODEL_ID = '60f03f8e0a3504f0d3764a06'
# Spool directory path must match the Monitoring Agent path configured by admin.
SPOOL_DIR = "/tmp/ta"
 
"""
This sample code demonstrates usage of the MLOps library.
It does not have real data (or even a real model) and should not be run against a real MLOps
service.
"""
 
 
class FakeModel(object):
    """
    Note that this FakeModel is not real.
    Update it with your own model.
    Fill in the predictions and the feature details.
    """
    def predict(self, num_samples):
        """
        This function returns a list of predictions.
 
        Fill in the prediction data.
        """
        return [random.random() for i in range(num_samples)]
 
    def feature_list(self, num_samples):
        """
        This function returns feature data in a dataframe.
        Typically, the scoring data will be read in a dataframe from the CSV file
 
        Fill in the feature data.
        """
        f1 = [random.random() for i in range(num_samples)]
        f2 = [random.random() for i in range(num_samples)]
        f3 = [random.random() for i in range(num_samples)]
 
        # create a dictionary of feature name to array of feature values
        feature_data = {
            "feature1": f1,
            "feature2": f2,
            "feature3": f3
        }
 
        return pd.DataFrame.from_dict(feature_data)
 
 
def main(deployment_id, model_id, spool_dir):
    """
    This is a regression algorithm example.
    User can call the DataRobot MLOps library functions to report statistics.
    """
    # MLOPS: initialize the MLOps instance
    mlops = MLOps() \
        .set_deployment_id(deployment_id) \
        .set_model_id(model_id) \
        .set_filesystem_spooler(spool_dir) \
        .init()
 
    num_samples = 10
    # Create fake model instance
    fake_model = FakeModel()
    features_df = fake_model.feature_list(num_samples)
 
    # Get predictions
    start_time = time.time()
    predictions = fake_model.predict(num_samples)
    num_predictions = len(predictions)
    end_time = time.time()
 
    # MLOPS: report the number of predictions in the request and the execution time.
    mlops.report_deployment_stats(num_predictions, end_time - start_time)
 
    
    # MLOPS: report the predictions data: features, predictions
    mlops.report_predictions_data(features_df=features_df, predictions=predictions)
    
 
    # MLOPS: release MLOps resources when finished.
    mlops.shutdown()
 
 
if __name__ == "__main__":
    sys.exit(main(DEPLOYMENT_ID, MODEL_ID, SPOOL_DIR))
 