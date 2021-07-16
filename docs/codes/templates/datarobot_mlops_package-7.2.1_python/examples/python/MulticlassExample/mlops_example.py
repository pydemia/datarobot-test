import time
import os
import numpy as np
import pandas as pd
import math
import csv
import pytz
import datetime
import argparse

from datarobot.mlops.mlops import MLOps
from sklearn.ensemble import RandomForestClassifier
from datarobot.mlops.constants import Constants


def _generate_unique_association_ids(num_samples):
    """ Create a set of association ids like 'x_1609954515.727338_[0, 1, ...]' """
    ts = time.time()
    return ["x_{}_{}".format(ts, i) for i in range(num_samples)]


def generate_actuals(predictions, class_names):
    """
    Generate some actual values, as class labels, based on predictions.
    Every few predictions, tweak the actuals so accuracy is not 100%
    :param predictions: 2-D list of probabilities
    :param class_names: 1-D list of class names
    :return: list of actuals as class labels
    """
    actuals = []
    for i, pred in enumerate(predictions):
        if len(pred) != len(class_names):
            print("Skipping row {}, probabilities count={}, class names count={}".format(
                i, len(pred), len(class_names)
            ))
            continue
        winner = pred.index(max(pred))
        if i % 5 == 0:
            winner = (winner + 1) % len(class_names)
        actuals.append(class_names[winner])
    return actuals


def write_actuals_file(out_filename, actuals, association_ids):
    """
    Generate a CSV file with the association ids and labels for uploading.

    :param out_filename: name of csv file
    :param actuals: actual values as class labels
    :param association_ids: association id list used for predictions
    """
    with open(out_filename, mode="w") as actuals_csv_file:
        writer = csv.writer(actuals_csv_file, delimiter=",")
        writer.writerow(
            [
                Constants.ACTUALS_ASSOCIATION_ID_KEY,
                Constants.ACTUALS_VALUE_KEY,
                Constants.ACTUALS_TIMESTAMP_KEY
            ]
        )
        tz = pytz.timezone("America/Los_Angeles")
        for (association_id, label) in zip(association_ids, actuals):
            actual_timestamp = datetime.datetime.now().replace(tzinfo=tz).isoformat()
            writer.writerow([association_id, label, actual_timestamp])
    print("Actuals filename: {}".format(out_filename))


def main():
    """
    Multiclass classification algorithm.
    The agent must be running to process prediction results and statistics.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--actuals-filename", dest="actuals_filename",
                        required=False, default=None,
                        help="Name of CSV file where to save association ids with labels.")
    args = parser.parse_args()

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    dataset_filename = os.path.join(cur_dir, "../../data/mlops-example-iris-samples.csv")

    df = pd.read_csv(dataset_filename, index_col=0)

    arr = df.to_numpy()

    # partition the dataset into 80% training and 20% test
    # rightmost column is the target
    split_ratio = 0.8
    np.random.shuffle(arr)
    train_data_len = int(arr.shape[0] * split_ratio)
    train_data = arr[:train_data_len, :-1]
    label = arr[:train_data_len, -1]
    test_data = arr[train_data_len:, :-1]
    test_df = df[train_data_len:]

    # train the model
    clf = RandomForestClassifier(n_estimators=10, max_depth=2, random_state=0)
    clf.fit(train_data, label)
    class_names = clf.classes_.tolist()

    # MLOPS: initialize mlops library
    mlops = MLOps().set_async_reporting(False).init()

    # make predictions
    start_time = time.time()
    predictions_array = clf.predict_proba(test_data)
    end_time = time.time()
    association_ids = _generate_unique_association_ids(len(test_data))

    # MLOPS: report deployment metrics: number of predictions and execution time
    mlops.report_deployment_stats(predictions_array.shape[0], math.ceil(end_time - start_time))

    # build feature values dataframe
    feature_df = test_df.copy()
    feature_df.drop(df.columns[[-1]], axis=1, inplace=True)

    # Write csv file with labels and association ID, when output file is provided
    if args.actuals_filename is not None:
        actuals = generate_actuals(predictions_array.tolist(), class_names)
        write_actuals_file(args.actuals_filename, actuals, association_ids)

    # MLOPS: report test features, predictions, and class names
    mlops.report_predictions_data(
        features_df=feature_df,
        predictions=predictions_array.tolist(),
        class_names=class_names,
        association_ids=association_ids,
    )

    # MLOPS: release MLOps resources when finished.
    mlops.shutdown()


if __name__ == "__main__":
    main()
