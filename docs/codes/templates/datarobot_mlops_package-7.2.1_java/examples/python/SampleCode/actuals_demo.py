import time
import random
import argparse
import csv
import pytz
import datetime

from datarobot.mlops.mlops import MLOps
from datarobot.mlops.constants import Constants

"""
Sample code demonstrate the generation of association ids for regression predictions.  These
association ids can then be used to report the actuals, so that the model accuracy can be
calculated at the server end
"""

DEFAULT_ACTUALS_CSV_FILE = "/tmp/ta_actuals.csv"
DEPLOYMENT_TYPE_REGRESSION = "Regression"
DEPLOYMENT_TYPE_BINARY = "Binary"


def _make_random_regression_predictions(num_samples):
    return [random.randrange(1, 25) for i in range(num_samples)]


def _make_random_binary_predictions(num_samples):
    predictions = []
    for i in range(num_samples):
        pred = random.random()
        predictions.append([pred, 1 - pred])

    return predictions


def _make_random_predictions(num_samples, deployment_type):
    if deployment_type == DEPLOYMENT_TYPE_REGRESSION:
        return _make_random_regression_predictions(num_samples)
    elif deployment_type == DEPLOYMENT_TYPE_BINARY:
        return _make_random_binary_predictions(num_samples)
    else:
        raise Exception("Invalid deployment type: '{}'".format(deployment_type))


def _get_random_actual_value(deployment_type):
    if deployment_type == DEPLOYMENT_TYPE_REGRESSION:
        return random.randrange(1, 25)
    elif deployment_type == DEPLOYMENT_TYPE_BINARY:
        if random.random() < 0.5:
            return "False"
        else:
            return "True"
    else:
        raise Exception("Invalid deployment type: '{}'".format(deployment_type))


def _generate_unique_association_ids(num_samples):
    ts = time.time()
    return ["x_{}_{}".format(ts, i) for i in range(num_samples)]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv-filename", dest="csv_filename", required=False,
                        default=DEFAULT_ACTUALS_CSV_FILE,
                        help="Name of CSV file where to save association ids.  "
                             "Default: '{}'".format(DEFAULT_ACTUALS_CSV_FILE))
    parser.add_argument("--deployment-type", dest="deployment_type", required=True,
                        help="Type of deployment to generate predictions for: 'Binary' or "
                             "'Regression'")

    # For accuracy calculation, we need at least 100 predictions
    parser.add_argument("--num-samples", dest="num_samples", required=False, default=100,
                        help="Number of predictions to make, default 100")

    args = parser.parse_args()
    num_samples = int(args.num_samples)
    # MLOPS: initialize mlops library
    # If deployment ID is not set, it will be read from MLOPS_DEPLOYMENT_ID environment variable.
    # If model ID is not set, it will be ready from MLOPS_MODEL_ID environment variable.
    mlops = MLOps().init()

    start_time = time.time()
    predictions_array = _make_random_predictions(num_samples, args.deployment_type)
    association_ids = _generate_unique_association_ids(num_samples)
    end_time = time.time()

    # MLOPS: report the number of predictions in the request and the execution time.
    mlops.report_deployment_stats(len(predictions_array), int((end_time - start_time) * 1000))

    class_names = None
    if args.deployment_type == "Binary":
        class_names = ["False", "True"]

    # MLOPS: report the prediction data.
    mlops.report_predictions_data(
        predictions=predictions_array, association_ids=association_ids, class_names=class_names
    )

    # MLOPS: release MLOps resources when finished.
    mlops.shutdown()

    # Generate a placeholder CSV file with the association ids, so that user can then fill
    # the actual values and use it to submit actuals
    #
    # For the purpose of the demo, this code generates random regression value to store in
    # the csv file
    with open(args.csv_filename, mode="w") as actuals_csv_file:
        writer = csv.writer(actuals_csv_file, delimiter=",")
        writer.writerow(
            [
                Constants.ACTUALS_ASSOCIATION_ID_KEY,
                Constants.ACTUALS_WAS_ACTED_ON_KEY,
                Constants.ACTUALS_VALUE_KEY,
                Constants.ACTUALS_TIMESTAMP_KEY
            ]
        )
        tz = pytz.timezone("America/Los_Angeles")
        for association_id in association_ids:
            actual_timestamp = datetime.datetime.now().replace(tzinfo=tz).isoformat()
            writer.writerow([association_id, False, _get_random_actual_value(args.deployment_type),
                             actual_timestamp])

    print("Stored all association ids in CSV file: '{}'".format(args.csv_filename))
    print("Once actuals are ready, you can edit the csv file and put actual values in it.")
    print("You can then use the utility './tools/upload_actuals.py' to upload the actuals "
          "to DR server to calculate accuracy")


if __name__ == "__main__":
    main()
