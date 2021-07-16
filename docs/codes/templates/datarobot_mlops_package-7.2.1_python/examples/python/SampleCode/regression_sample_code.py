import time
import random
import pandas as pd

from datarobot.mlops.mlops import MLOps

"""
This sample code is intended to demonstrate how the mlops library is called in the documentation.
It does not have real data (or even a real model) and should not be run against a real MLOps
service.
"""


def _make_fake_feature_df(num_samples):

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


def _make_fake_sample_predictions_list(num_samples):
    return [random.random() for i in range(num_samples)]


def main():
    num_samples = 10

    # MLOPS: initialize mlops library
    # If deployment ID is not set, it will be read from MLOPS_DEPLOYMENT_ID environment variable.
    # If model ID is not set, it will be ready from MLOPS_MODEL_ID environment variable.
    mlops = MLOps().init()

    features_df = _make_fake_feature_df(num_samples)

    start_time = time.time()
    predictions_array = _make_fake_sample_predictions_list(num_samples)
    end_time = time.time()

    # MLOPS: report the number of predictions in the request and the execution time.
    mlops.report_deployment_stats(len(predictions_array), (end_time - start_time) * 1000)

    # MLOPS: report the prediction results.
    mlops.report_predictions_data(features_df=features_df, predictions=predictions_array)

    # MLOPS: release MLOps resources when finished.
    mlops.shutdown()


if __name__ == "__main__":
    main()
