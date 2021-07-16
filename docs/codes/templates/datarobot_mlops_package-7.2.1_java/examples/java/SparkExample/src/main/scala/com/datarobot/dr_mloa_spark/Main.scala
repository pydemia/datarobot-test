package com.datarobot.dr_mloa_spark

import com.datarobot.mlops.MLOps
import com.datarobot.prediction.{IPredictorInfo, IRegressionPredictor, Predictor}

import java.util

import org.apache.spark.TaskContext
import org.apache.spark.sql.{Encoder, Encoders, SparkSession}
import org.apache.spark.util.TaskCompletionListener

import scala.collection.JavaConversions._
import scala.util.Random

object Main {

  def getModel(modelId: String) : IPredictorInfo = {
    val modelClass = Class.forName("com.datarobot.prediction.dr" + modelId + ".DRModel")
    val modelInstance = modelClass.newInstance()

    val wrapperClass = Class.forName("com.datarobot.prediction.RegressionPredictorImpl")
    val regressionConstructor = wrapperClass.getDeclaredConstructor(classOf[Predictor])
    regressionConstructor.setAccessible(true)
    return regressionConstructor.newInstance(modelInstance.asInstanceOf[Predictor]).asInstanceOf[IPredictorInfo]
  }

  def usage(args : Array[String]): (String,Option[String]) = {
    if (args.size < 1) {
      val sparkSubmit = "spark-submit"
      var codeGenJar = " [--jars <CodeGenModel>.jar]"
      val thisClass = " --class com.datarobot.dr_mloa_spark.Main"
      var sparkOptions = " <spark-options>"
      val thisJar = " ./target/dr-mloa-spark-1.0-SNAPSHOT-uber.jar"
      var inputFile = " <input.csv>"
      var codeGenModelId = " [<codeGenModelId>]"
      System.err.println("\nUSAGE: " + sparkSubmit + codeGenJar + thisClass + sparkOptions + thisJar + inputFile
        + codeGenModelId)
      sparkOptions = " --num-executors 1 --driver-memory 512m --executor-memory 512m --executor-cores 1"
      codeGenJar = " --jars CodeGenLendingClubRegressor.jar"
      inputFile = " lending-club-regression-10.csv"
      codeGenModelId = " 5d4872f6962d7473b5a4d96b"
      System.err.println("\nEXAMPLE: " + sparkSubmit + codeGenJar + thisClass + sparkOptions + thisJar + inputFile
        + codeGenModelId + "\n\n")
      System.exit(1)
    }
    if (args.size < 2) {
      System.err.println("\n\nNOTICE: no modelId was provided. Using random numbers for scoring.\n\n")
      return (args(0), None)
    }
    return (args(0), Option(args(1)))
  }

  def main(args: Array[String]): Unit = {
    val processedArgs = usage(args)
    val inputFilePath = processedArgs._1
    val modelId = processedArgs._2
    val regressionPredictor = modelId match {
      case None => None
      case Some(mid) => {
        val pred = getModel(mid).asInstanceOf[IRegressionPredictor]
        val features = pred.getFeatures
        System.err.println("Model features: " + features)
        Some(pred)
      }
    }

    val ss = SparkSession.builder().getOrCreate()
    // Spark runs 1 task for each data partition
    // Typically you want 2-4 partitions per CPU in your cluster
    // Default file block size is 128MB. You cannot have fewer partitions than blocks.
    val scoredFrame = ss.read.option("header", "true").csv(inputFilePath)
    val featureSchema = scoredFrame.schema
    val fieldPositions = featureSchema.indices
    val fieldNames = featureSchema.fieldNames

    def outputEncoder: Encoder[Double] = Encoders.scalaDouble

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

      // MLOPS: Initialize MLOps once per thread/worker
      val mlops = MLOps.getInstance()
      mlops.setSyncReporting().init()

      // Add the shutdown hook since Spark may kill off a worker thread at any time.
      // The thread may hang the Spark job if shutdown is not called.
      // MLOPS: Ensure shutdown is called
      TaskContext.get().addTaskCompletionListener(new TaskCompletionListener() {
        override def onTaskCompletion(context: TaskContext): Unit = mlops.shutdown()
      })
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

        val startTime = System.currentTimeMillis
        val predictionRows = makeRegressionPredictions(regressionPredictor, codeGenFeatureRows)
        val endTime = System.currentTimeMillis

        System.err.println(s"partId=${TaskContext.getPartitionId()}, size=${forced.size}")

        // MLOPS: Report deployment stats
        mlops.reportDeploymentStats(predictionRows.size, endTime - startTime)
        val reportedFeatureRows: util.List[util.Map[String, java.lang.Object]] = codeGenFeatureRows.asInstanceOf[util.List[util.Map[String, java.lang.Object]]]

        // MLOPS: Report features and predictions
        mlops.reportPredictionsDataList(reportedFeatureRows, predictionRows)
        predictionRows
      }

    }(outputEncoder)
    // At some point there needs to be a forcing of the DataFrame to evaluate above transforms.
    System.err.println("---Number of predictions: " + reportedFrame.count())
  }
}
