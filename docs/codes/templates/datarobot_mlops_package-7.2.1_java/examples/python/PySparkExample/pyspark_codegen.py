"""
An example program to demonstrate MLOps integration with PySpark.
"""
from __future__ import print_function

import os
import sys

from pyspark.sql import SparkSession
from pyspark.sql import DataFrame

from py4j.java_gateway import java_import
import time

if __name__ == "__main__":

    if len(sys.argv) != 2:
        print("Usage: pyspark_codegen <file>", file=sys.stderr)
        sys.exit(-1)
    inputFile = sys.argv[1]
    deployment_id = os.getenv("MLOPS_DEPLOYMENT_ID")
    model_id = os.getenv("MLOPS_MODEL_ID")

    spark = SparkSession\
        .builder\
        .appName("PySpark CodeGen with Monitoring")\
        .getOrCreate()

    input_df = spark.read \
        .options(header="true", inferschema="true") \
        .csv(inputFile)

    java_import(spark._jvm, "com.datarobot.prediction.Predictors")
    java_import(spark._jvm, "com.datarobot.prediction.spark.CodegenModel")
    java_import(spark._jvm, "com.datarobot.prediction.spark.Predictors")

    codeGenModel = spark._jvm.com.datarobot.prediction.spark.Predictors.getPredictor(model_id)
    start_time = time.time()
    predictions_df = codeGenModel.transform(input_df._jdf)
    end_time = time.time()
    prediction_ms = (end_time - start_time) * 1000
    output = DataFrame(predictions_df, spark)
    # output.show(n=10)

    java_import(spark._jvm, "com.datarobot.mlops.spark.MLOpsSparkUtils")
    spark._jvm.com.datarobot.mlops.spark.MLOpsSparkUtils.reportPredictions(
        predictions_df,  # scoring feature data and predictions
        deployment_id,
        model_id,
        None,  # spooler configuration will be read from the environment variables
        float(prediction_ms),  # actual scoring time
        ["PREDICTION"],  # name of columns in the prediction_df that contain the predictions. Since
                         # this is a regression model, there is only 1. Classification models have
                         # a predicted probability for each class.
        "id"  # name of column in the predictions_df that contains association ids
    )

    print("******** Total predictions: {}".format(output.count()))

    spark.stop()
