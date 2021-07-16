import logging
import time
import os
import numpy as np
import pandas as pd
import argparse
import math

from datarobot.mlops.mlops import MLOps
from sklearn.ensemble import RandomForestClassifier

log_level = os.environ.get("MLOPS_LIB_LOGLEVEL", "INFO").upper()
logging.basicConfig(level=log_level)
logger = logging.getLogger(__name__)


def main():
    """
    Binary classification algorithm.
    """

    parser = argparse.ArgumentParser()
    parser.add_argument("--url", dest="mlops_url", required=True, default="http://localhost:80/",
                        help="DataRobot MLOps URL to send statistics to")
    parser.add_argument("--token", dest="user_token", required=True, default=None,
                        help="Authorization token for the user")
    args = parser.parse_args()

    if not args.user_token:
        raise Exception("User token is required to run the demo")

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    dataset_filename = os.path.join(cur_dir, "../../data/mlops-example-surgical-dataset.csv")

    df = pd.read_csv(dataset_filename)

    columns = list(df.columns)
    arr = df.to_numpy()

    # read the training dataset
    split_ratio = 0.8
    prediction_threshold = 0.5

    np.random.shuffle(arr)

    train_data_len = int(arr.shape[0] * split_ratio)

    train_data = arr[:train_data_len, :-1]
    label = arr[:train_data_len, -1]
    test_data = arr[train_data_len:, :-1]
    test_df = df[train_data_len:]

    # train the model
    clf = RandomForestClassifier(n_estimators=10, max_depth=2, random_state=0)
    clf.fit(train_data, label)

    # MLOPS: initialize mlops library
    mlops = MLOps(). \
        set_async_reporting(False). \
        agent(mlops_service_url=args.mlops_url,
              mlops_api_token=args.user_token).\
        init()

    # make predictions
    start_time = time.time()
    predictions_array = clf.predict_proba(test_data)
    end_time = time.time()

    # MLOPS: report deployment metrics: number of predictions and execution time
    mlops.report_deployment_stats(predictions_array.shape[0], math.ceil(end_time - start_time))

    target_column_name = columns[len(columns) - 1]
    target_values = []

    # Based on prediction value and the threshold assign correct label to each prediction
    reporting_predictions = []
    for index, value in enumerate(predictions_array.tolist()):
        if len(value) == 1:
            # Random forest classifier from scikit-learn can return a single probability value
            # instead of 2 values.  We need to infer the other one before reporting predictions,
            # because, 'report_predictions_data' expects probability for each class.
            value.append(1 - value[0])
        reporting_predictions.append(value)
        if value[0] < prediction_threshold:
            target_values.append("0.0")
        else:
            target_values.append("1.0")

    feature_df = test_df.copy()
    feature_df[target_column_name] = target_values

    # MLOPS: report test features and predictions and association_ids
    mlops.report_predictions_data(
        features_df=test_df,
        predictions=reporting_predictions,
    )

    # query for the stats on the record
    # shutdown/clean-up agent
    mlops.shutdown()


if __name__ == "__main__":
    main()
