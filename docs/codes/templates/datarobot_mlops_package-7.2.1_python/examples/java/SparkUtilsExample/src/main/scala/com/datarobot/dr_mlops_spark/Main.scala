package com.datarobot.dr_mlops_spark

import java.text.SimpleDateFormat

import com.datarobot.mlops.spark.MLOpsSparkUtils
import com.datarobot.mlops.MLOpsConstants
import com.datarobot.prediction.{IClassificationPredictor, IPredictorInfo, IRegressionPredictor, Predictor}
import java.util
import java.util.Date

import org.apache.spark.TaskContext
import org.apache.spark.sql.{DataFrame, Encoder, Encoders, Row, SparkSession}
import org.apache.spark.sql.functions._

import scala.collection.JavaConversions._
import scala.util.Random

object Main {

  def getModel(modelId: String): IPredictorInfo = {
    val modelClass = Class.forName("com.datarobot.prediction.dr" + modelId + ".DRModel")
    val modelInstance = modelClass.newInstance()

    val wrapperClass = Class.forName("com.datarobot.prediction.RegressionPredictorImpl")
    val regressionConstructor = wrapperClass.getDeclaredConstructor(classOf[Predictor])
    regressionConstructor.setAccessible(true)
    return regressionConstructor.newInstance(modelInstance.asInstanceOf[Predictor]).asInstanceOf[IPredictorInfo]
  }

  def usage(args: Array[String]): (String, String, String, String, String) = {
    if (args.length < 1) {
      val sparkSubmit = "spark-submit"
      var codeGenJar = " [--jars <CodeGenModel>.jar]"
      val thisClass = " --class com.datarobot.dr_mloa_spark.Main"
      var sparkOptions = " <spark-options>"
      val thisJar = " ./target/dr-mloa-spark-1.0-SNAPSHOT-uber.jar"
      var inputFile = " <input.csv>"
      var codeGenModelId = " [<codeGenModelId>]"
      var deploymentId = " <deploymentId>"
      var deploymentExternalModelId =  " <deploymentExternalModelId>"
      var channelConfig = " <channelConfig>"

      System.err.println("\nUSAGE: " + sparkSubmit + codeGenJar + thisClass + sparkOptions + thisJar + inputFile
        + codeGenModelId + deploymentId + deploymentExternalModelId + channelConfig)
      sparkOptions = " --num-executors 1 --driver-memory 512m --executor-memory 512m --executor-cores 1"
      codeGenJar = " --jars CodeGenLendingClubRegressor.jar"
      inputFile = " lending-club-regression-10.csv"
      codeGenModelId = " 5d4872f6962d7473b5a4d96b"
      deploymentId = " 22332333232"
      deploymentExternalModelId = " 33333333"
      channelConfig = " spooler_type=filesystem;path=/tmp/ta"
      System.err.println("\nEXAMPLE: " + sparkSubmit + codeGenJar + thisClass + sparkOptions + thisJar + inputFile
        + codeGenModelId + deploymentId + deploymentExternalModelId + channelConfig + "\n\n")
      System.exit(1)
    }
    (args(0), args(1), args(2), args(3), args(4))
  }

  def gen_regression_predictions(inputFilePath: String,
                                 modelId: String,
                                 predictionColName: String): (DataFrame, Double) = {

    val ss = SparkSession.builder().getOrCreate()
    // Spark runs 1 task for each data partition
    // Typically you want 2-4 partitions per CPU in your cluster
    // Default file block size is 128MB. You cannot have fewer partitions than blocks.
    val scoredFrame = ss.read.option("header", "true").csv(inputFilePath)
    val featureSchema = scoredFrame.schema
    val fieldPositions = featureSchema.indices
    val fieldNames = featureSchema.fieldNames

    val regressionPredictor = modelId match {
      case "random" => None
      case mid => {
        val pred = getModel(mid).asInstanceOf[IRegressionPredictor]
        val features = pred.getFeatures
        System.err.println("Model features: " + features)
        Some(pred)
      }
    }

    def outputEncoder: Encoder[Double] = Encoders.scalaDouble
    val startTime = System.currentTimeMillis

    // The code block defined here will be called on each thread of each worker
    val reportedFrame = scoredFrame.mapPartitions { it =>

      def makeRegressionPredictions(predictor: Option[IRegressionPredictor],
                                    featureMaps: util.ArrayList[util.HashMap[java.lang.String, java.lang.Object]])
      : util.ArrayList[Double] = {
        val predictions = new util.ArrayList[Double](featureMaps.size)
        for (featureMap <- featureMaps) {

          val score = predictor match {
            case None => Random.nextDouble()
            case Some(p) => p.score(featureMap)
          }
          predictions.add(score)
        }
        predictions
      }
      // it: Iterator[T]
      // it.grouped(...): Iterator[Seq[T]] --> Each thread will process its workload this may rows at a time.
      // it.flatMap(f: Seq[T] => Seq[T]): Iterator[T] --> processes one row at a time.
      it.grouped(500).flatMap { results => // each group of at most 500 Rows

        val forced = results.toVector

        val codeGenFeatureRows = new util.ArrayList[util.HashMap[java.lang.String, java.lang.Object]]
        for (result <- forced) {
          val codeGenFeatureData = new util.HashMap[String, AnyRef]
          for (pos <- fieldPositions; fieldName = fieldNames(pos)) {
            codeGenFeatureData.put(fieldName, result.get(pos).asInstanceOf[AnyRef])
          }
          val jfeatures = mapAsJavaMap(codeGenFeatureData).asInstanceOf[java.util.HashMap[java.lang.String, java.lang.Object]]
          codeGenFeatureRows.add(jfeatures)
        }
        val predictionRows = makeRegressionPredictions(regressionPredictor, codeGenFeatureRows)

        System.err.println(s"partId=${TaskContext.getPartitionId()}, size=${forced.size}")
        predictionRows
      }

    }(outputEncoder)
    val endTime = System.currentTimeMillis

    // At some point there needs to be a forcing of the DataFrame to evaluate above transforms.
    System.err.println("---Number of predictions: " + reportedFrame.count())
    (reportedFrame.toDF(predictionColName), endTime - startTime)
  }

  def genActualsDF(dataFrame: DataFrame) : DataFrame = {

    val timeStamp = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX").format(new Date())
    System.out.println(timeStamp);

    dataFrame.withColumn(MLOpsConstants.ACTUALS_WAS_ACTED_ON_KEY, lit(true))
      .withColumn(MLOpsConstants.ACTUALS_VALUE_KEY, lit(0.5))
      .withColumn(MLOpsConstants.ACTUALS_TIMESTAMP_KEY, lit(timeStamp))
  }


  def main(args: Array[String]): Unit = {
    val processedArgs = usage(args)
    val inputFilePath = processedArgs._1
    val codegenModelId = processedArgs._2
    val deploymentId = processedArgs._3
    val deploymentExternalModelId = processedArgs._4
    val channelConfig = processedArgs._5

    System.out.println("\n\n ------ Example Starting -------")
    System.out.println(s"InputFile:           $inputFilePath")
    System.out.println(s"codegneModelId:      $codegenModelId")
    System.out.println(s"DeploymetId:         $deploymentId")
    System.out.println(s"Deployment Model Id: $deploymentExternalModelId")
    System.out.println(s"Channel Config:      $channelConfig")
    val ss = SparkSession.builder().getOrCreate()
    // Spark runs 1 task for each data partition
    // Typically you want 2-4 partitions per CPU in your cluster
    // Default file block size is 128MB. You cannot have fewer partitions than blocks.
    var inputFrame = ss.read.option("header", "true").csv(inputFilePath)
    System.out.println("Number of lines in input file: " + inputFrame.count())

    val predictionColName = "predictions"
    val uniqueIDCol = MLOpsConstants.ACTUALS_ASSOCIATION_ID_KEY

    val predictionsResults = gen_regression_predictions(inputFilePath, codegenModelId, predictionColName)

    inputFrame = inputFrame.withColumn(uniqueIDCol, monotonically_increasing_id())

    val regressionPredictionFrame =  predictionsResults._1.withColumn(uniqueIDCol, monotonically_increasing_id())
    val dfRegression = inputFrame.as("df1").join(regressionPredictionFrame.as("df2"),
      inputFrame(uniqueIDCol) === regressionPredictionFrame(uniqueIDCol), "inner").drop(uniqueIDCol)

    // Adding a unique id column to indicate the association id of the prediction.
    val dfRegressionWithAssoc = dfRegression.withColumn(uniqueIDCol, monotonically_increasing_id())
    dfRegressionWithAssoc.show()

    // MLOPS
    val targetNameList = Array(predictionColName)
    System.out.println("\n\n\nCalling mlops\n\n\n\n")

    MLOpsSparkUtils.reportPredictions(
      dfRegressionWithAssoc,        // The dataframe with features and predictions
      deploymentId,                 // Deployment id to report to
      deploymentExternalModelId,    // The model id to use for reporting on the App side
      channelConfig,                // Channel config string
      predictionsResults._2,        // The time it took scoring the data
      targetNameList,               // The name of the target column (in our case a list of one item)
      uniqueIDCol                   // The name of the column which contain a unique id per prediction
    )

    val dfActuals = genActualsDF(dfRegressionWithAssoc)
    MLOpsSparkUtils.reportActuals(
      dfActuals,
      deploymentId,
      deploymentExternalModelId,
      channelConfig
    )

  }
}
