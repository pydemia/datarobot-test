import argparse
from argparse import RawTextHelpFormatter
import json
import os
import requests

from datarobot.mlops.connected.client import MLOpsClient
from datarobot.mlops.common.exception import DRConnectedException

FEATURE_DRIFT_ERROR_MESSAGE = "Training dataset upload failed.\n" \
                              "You won't see Feature Drift reports in UI.\n"


def upload_training_data(mlops_connected_client, train_dataset):
    # MLOPS: Upload the training data for this deployment
    # train_dataset must be the name of a CSV file
    train_dataset = os.path.abspath(train_dataset)

    if not os.path.exists(train_dataset):
        print("\nUnable to find training_data file: {}".format(train_dataset))
        return False

    print("Uploading training data - {}. This may take some time..."
          .format(train_dataset))
    try:
        dataset_id = mlops_connected_client.upload_dataset(train_dataset)
        print("Training dataset uploaded. Catalog ID {}.".format(dataset_id))
        return dataset_id
    except Exception as e:
        print(FEATURE_DRIFT_ERROR_MESSAGE)
        print("Error: {}".format(e))
        return False


def delete(mlops_client, deployment_id, dataset_id):
    if deployment_id:
        mlops_client.delete_deployment(deployment_id)
        print("Deleted deployment {}".format(deployment_id))
    if dataset_id:
        mlops_client.soft_delete_dataset(dataset_id)
        print("Deleted dataset {}".format(dataset_id))


def _delete_request(has_error, url, headers):
    try:
        response = requests.delete(url, headers=headers)
        if not response.ok:
            has_error = True
    except Exception as e:
        print("Error: {}".format(e))
        has_error = True

    return has_error


def _print_deployment_conf_info(deployment_id, model_id):
    print("\n======== DEPLOYMENT CONFIGURATION SUMMARY ========")
    print("export MLOPS_DEPLOYMENT_ID={}; export MLOPS_MODEL_ID={}\n"
          .format(deployment_id, model_id))


def _read_model_config(model_config_file):
    try:
        # read model config
        model_config_path = os.path.abspath(model_config_file)

        if os.path.exists(model_config_path):
            with open(model_config_path, "r") as f:
                model_info = json.loads(f.read())
            return model_info
        else:
            print("Missing required file {}.".format(model_config_path))
            exit(-1)

    except DRConnectedException as e:
        print("\nModel package creation failed: {}".format(e))
        exit(-1)


def _create_model_package(mlops_connected_client, model_info, model_id=None):
    if model_id is not None:
        model_info["modelId"] = model_id

    model_pkg_id = mlops_connected_client.create_model_package(model_info)
    model_pkg = mlops_connected_client.get_model_package(model_pkg_id)
    return model_pkg


def __parse_args():
    parser = argparse.ArgumentParser(formatter_class=RawTextHelpFormatter,
                                     epilog=("""Examples:
       # Create a model package from the configuration file and deploy it
      deploy --model-config=CONFIG.JSON [--training-data=PATH.CSV]
       --label='My Deployment'

      # Create a model package from the configuration file and use it to replace the model in
      # the specified deployment
      replace --model-config=CONF.JSON [--training-data=PATH.CSV] --deployment=ID

      # Delete the dataset and/or deployment
      delete [--dataset_id=DATASET_ID] [--deployment-id=DEPLOYMENT_ID]"
      """))

    parser.add_argument(dest="command", default="deploy", help="Command to execute.",
                        choices=["get", "create", "deploy", "replace", "delete"])
    parser.add_argument("--url", dest="url", required=False, help="MLOps Service URL")
    parser.add_argument("--token", dest="token", required=False, help="MLOps Service access token")
    parser.add_argument("--verify-ssl", dest="verify", required=False,
                        default=True, help="Verify SSL certificate")

    parser.add_argument("--model-config", dest="model_config_file", required=False,
                        help="file with JSON configuration of model")
    parser.add_argument("--training-data", dest="training_data", required=False,
                        help="Training dataset used for model.")
    parser.add_argument("--dataset-id", dest="dataset_id", required=False,
                        help="Dataset catalog ID used for model.")
    parser.add_argument("--model-package-id", dest="model_package_id", required=False,
                        help="When using get command, returns info for this model package.")
    parser.add_argument("--model-id", dest="model_id", required=False,
                        help="When using CodeGen models, the CodeGen model ID.")

    parser.add_argument("--label", dest="label", required=False, default="TestDeployment",
                        help="When first deploying, label for the deployment.")
    parser.add_argument("--deployment-id", dest="deployment_id", required=False,
                        help="When replacing the model, the deployment for model replacement.")
    parser.add_argument("--reason", dest="reason", required=False,
                        help="When replacing the model, reason for replacement.",
                        choices=["ACCURACY", "DATA_DRIFT", "ERRORS", "SCHEDULED_REFRESH",
                                 "SCORING_SPEED", "OTHER"], default="OTHER")
    parser.add_argument("--target-drift", dest="enable_target_drift", action="store_true",
                        help="Enable target drift tracking for the deployment (default enabled).")
    parser.add_argument("--no-target-drift", dest="enable_target_drift", action="store_false",
                        help="Disable target drift tracking for the deployment.")
    parser.set_defaults(enable_target_drift=True)
    args = parser.parse_args()

    if args.url is None:
        key = "MLOPS_SERVICE_URL"
        url = os.getenv(key)
        if url is None:
            print("Must provide parameter --url or set environment var {}".format(key))
            exit(-1)
        args.url = url

    if args.token is None:
        key = "MLOPS_TOKEN"
        token = os.getenv(key)
        if token is None:
            print("Must provide parameter --token or set environment var {}".format(key))
            exit(-1)
        args.token = token

    if args.command == "delete":
        if args.deployment_id is None and args.dataset_id is None:
            print("Must provide parameter deployment_id and/or dataset_id with command {}"
                  .format(args.command))
            exit(-1)

    elif args.command == "get":
        if args.model_package_id is None and args.deployment_id is None:
            print("Must provide parameter model_package_id and/or deployment_id with command {}"
                  .format(args.command))
            exit(-1)
    else:
        if args.model_config_file is None:
            print("Must provide parameter model-config-file with command {}".format(args.command))
            exit(-1)

    if args.command == "replace":
        if args.deployment_id is None:
            print("Must provide parameter deployment-id with command {}".format(args.command))
            exit(-1)

    return args


def main():
    options = __parse_args()

    # create connected client
    verify = True
    if options.verify == "False":
        verify = False
    mlops_connected_client = MLOpsClient(options.url, options.token, verify=verify)

    if options.command == "delete":
        delete(mlops_connected_client, deployment_id=options.deployment_id,
               dataset_id=options.dataset_id)
        exit(0)

    if options.command == "get":
        if options.model_package_id is not None:
            info = mlops_connected_client.get_model_package(options.model_package_id)
            print(info)
        if options.deployment_id is not None:
            info = mlops_connected_client.get_deployment(options.deployment_id)
            print(info)
        exit(0)

    # read basic model configuration
    model_info = _read_model_config(options.model_config_file)

    # if specified, add training_data to model configuration
    if options.training_data:
        dataset_id = upload_training_data(mlops_connected_client, options.training_data)

        if not dataset_id:
            exit(-1)

        datasets = {"trainingDataCatalogId": dataset_id}
        model_info["datasets"] = datasets

    elif options.dataset_id is None:
        print("\nWARNING: Training dataset was not specified. "
              "Feature drift will not be enabled.")

    try:
        # Create a model package
        if options.dataset_id is not None:
            datasets = {"trainingDataCatalogId": options.dataset_id}
            model_info["datasets"] = datasets

        model_pkg = _create_model_package(mlops_connected_client, model_info, options.model_id)
        model_id = model_pkg["modelId"]

        if options.command == "create":
            print("Created model package ID {}".format(model_id))
            exit(0)

        # if specified, deploy or replace the model
        deployment_id = None
        if options.command == "deploy":
            # Deploy the model package
            deployment_id = mlops_connected_client.deploy_model_package(model_pkg["id"],
                                                                        options.label)
        elif options.command == "replace":
            deployment_id = options.deployment_id

            mlops_connected_client.replace_model_package(deployment_id, model_pkg["id"],
                                                         options.reason)
            print("Deployment {} now has model {}".format(deployment_id, model_pkg["modelId"]))

        if deployment_id is not None:
            enable_feature_drift = options.training_data is not None
            enable_target_drift = options.enable_target_drift
            mlops_connected_client.update_deployment_settings(deployment_id,
                                                              target_drift=enable_target_drift,
                                                              feature_drift=enable_feature_drift)
            _ = mlops_connected_client.get_deployment_settings(deployment_id)
            _print_deployment_conf_info(deployment_id, model_id)

        exit(0)

    except DRConnectedException as e:
        print("\nModel deployment failed: {}".format(e))
        exit(-1)


if __name__ == "__main__":
    main()
