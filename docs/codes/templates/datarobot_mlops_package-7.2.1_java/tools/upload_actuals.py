import argparse
import csv

from datarobot.mlops.connected.client import MLOpsClient
from datarobot.mlops.constants import Constants

"""
Sample code demonstrate the upload of the actual values to DR server to calculate the accuracy.

In an ideal case, association ids for the actuals are stored in the database as transaction id or
request id.  For the purposes of the demo, we accept a prefix of the association id and use it to
generate the association ids same as those generated while making predictions
"""

DEFAULT_ACTUALS_CSV_FILE = "/tmp/ta_actuals.csv"


def _get_correct_actual_value(deployment_type, value):
    if deployment_type == "Regression":
        return float(value)
    return str(value)


def _get_correct_flag_value(value_str):
    if value_str == "True":
        return True
    return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", dest="url", required=True, help="MLOps Service URL")
    parser.add_argument("--token", dest="token", required=True, help="MLOps Service access token")
    parser.add_argument("--csv-filename", dest="csv_filename", required=False,
                        default=DEFAULT_ACTUALS_CSV_FILE,
                        help="Name of CSV file to read actuals from.  "
                             "Default: '{}'".format(DEFAULT_ACTUALS_CSV_FILE))
    parser.add_argument("--deployment-id", dest="deployment_id", required=True,
                        help="ID of the deployment for which to submit actuals")

    args = parser.parse_args()

    mlops_connected_client = MLOpsClient(args.url, args.token)
    deployment_type = mlops_connected_client.get_deployment_type(args.deployment_id)

    actuals = []
    with open(args.csv_filename, mode="r") as actuals_csv_file:
        reader = csv.DictReader(actuals_csv_file)
        for row in reader:
            actual = {}
            for key, value in row.items():
                if key == Constants.ACTUALS_WAS_ACTED_ON_KEY:
                    value = _get_correct_flag_value(value)
                if key == Constants.ACTUALS_VALUE_KEY:
                    value = _get_correct_actual_value(deployment_type, value)
                actual[key] = value
            actuals.append(actual)

            if len(actuals) == 10000:
                mlops_connected_client.submit_actuals(args.deployment_id, actuals)
                actuals = []

    mlops_connected_client.submit_actuals(args.deployment_id, actuals)


if __name__ == "__main__":
    main()
