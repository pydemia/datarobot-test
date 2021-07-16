import time
import os
import numpy as np
import pandas as pd
import csv
import pytz
import datetime
import argparse

from datarobot.mlops.mlops import MLOps
from datarobot.mlops.constants import Constants
from sklearn.ensemble import RandomForestClassifier


def _generate_unique_association_ids(num_samples):
    ts = time.time()
    return ["x_{}_{}".format(ts, i) for i in range(num_samples)]


def write_actuals_file(out_filename, test_data_labels, association_ids):
    """
     Generate a CSV file with the association ids and labels, this example
     uses a dataset that has labels already.
     In a real use case actuals (labels) will show after prediction is done.

    :param out_filename:      name of csv file
    :param test_data_labels:  actual values (labels)
    :param association_ids:   association id list used for predictions
    """
    with open(out_filename, mode="w") as actuals_csv_file:
        writer = csv.writer(actuals_csv_file, delimiter=",")
        writer.writerow(
            [
                Constants.ACTUALS_ASSOCIATION_ID_KEY,
                Constants.ACTUALS_VALUE_KEY,
                Constants.ACTUALS_WAS_ACTED_ON_KEY,
                Constants.ACTUALS_TIMESTAMP_KEY
            ]
        )
        tz = pytz.timezone("America/Los_Angeles")
        was_acted_on = False
        for (association_id, label) in zip(association_ids, test_data_labels):
            actual_timestamp = datetime.datetime.now().replace(tzinfo=tz).isoformat()
            was_acted_on = not was_acted_on
            writer.writerow([association_id, "1" if label else "0", was_acted_on, actual_timestamp])
    print("Actuals filename: {}".format(out_filename))


def main():
    """
    Binary classification algorithm.
    """

    parser = argparse.ArgumentParser()
    parser.add_argument("--actuals-filename", dest="actuals_filename",
                        required=False, default=None,
                        help="Name of CSV file where to save association ids with labels.")
    args = parser.parse_args()

    # read the training dataset
    split_ratio = 0.8
    prediction_threshold = 0.5

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    dataset_filename = os.path.join(cur_dir, "../../data/mlops-example-surgical-dataset.csv")

    df = pd.read_csv(dataset_filename)

    columns = list(df.columns)
    arr = df.to_numpy()

    np.random.shuffle(arr)

    train_data_len = int(arr.shape[0] * split_ratio)

    train_data = arr[:train_data_len, :-1]
    label = arr[:train_data_len, -1]
    test_data = arr[train_data_len:, :-1]
    test_df = df[train_data_len:]

    # train the model
    clf = RandomForestClassifier(n_estimators=10, max_depth=2, random_state=0)
    clf.fit(train_data, label)

    # MLOPS: initialize mlops
    m = MLOps().init()

    # make predictions
    start_time = time.time()
    predictions_array = clf.predict_proba(test_data)
    end_time = time.time()
    association_ids = _generate_unique_association_ids(len(test_data))

    # MLOPS: report deployment metrics: number of predictions and execution time
    m.report_deployment_stats(predictions_array.shape[0], (end_time - start_time) * 1000)

    target_column_name = columns[len(columns) - 1]
    target_values = []
    orig_labels = test_df[target_column_name].tolist()
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

    # Write csv file with labels and association Id, when output file is provided
    if args.actuals_filename is not None:
        write_actuals_file(args.actuals_filename, orig_labels, association_ids)

    # MLOPS: report test features and predictions and association_ids
    m.report_predictions_data(
        features_df=test_df,
        predictions=reporting_predictions,
        association_ids=association_ids
    )

    m.shutdown()


if __name__ == "__main__":
    main()
