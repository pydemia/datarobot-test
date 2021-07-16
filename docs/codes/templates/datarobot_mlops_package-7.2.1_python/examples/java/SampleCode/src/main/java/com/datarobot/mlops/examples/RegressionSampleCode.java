
package com.datarobot.mlops.examples;

import com.datarobot.mlops.MLOps;
import com.datarobot.mlops.common.exceptions.DRCommonException;
import com.datarobot.mlops.common.enums.SpoolerType;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

public class RegressionSampleCode {
    static private Random rand;
    private String deploymentId;
    private String modelId;

    RegressionSampleCode(String deploymentId, String modelId) {
        this.deploymentId = deploymentId;
        this.modelId = modelId;
        rand = new Random();
    }

    Map<String, List<Object>> makeFakeFeatureData(int numSamples) {

        Map<String, List<Object>> featureData = new HashMap<>();

        List<Object> feature1Values = new ArrayList<>();
        // feature1 is a double
        for (int i = 0; i < numSamples; i++) {
            feature1Values.add(rand.nextDouble());
        }
        featureData.put("feature1_name", feature1Values);

        // feature2 is a string
        List<Object> feature2Values = new ArrayList<>();
        for (int i = 0; i < numSamples; i++) {
            feature2Values.add("some_text" + i);
        }
        featureData.put("feature2_name", feature2Values);

        return featureData;
    }

    public List<Double> makeFakeRegressionPredictionsList(int numSamples) {
        List<Double> predictions = new ArrayList<>(numSamples);
        for (int i = 0; i < numSamples; i++) {
            predictions.add(rand.nextDouble());
        }

        return predictions;
    }

    /**
     * Sample code demonstrating how to use MLOps library to record metrics on regression predictions.
     * All code specific to MLOps library are commented with "MLOPS"
     */
    public void run(int numSamples) {

        // MLOPS: declaration
        MLOps mlops = null;
        try {

            // MLOPS: initialize mlops instance.
            // If the deployment ID is not specified, the environment variable MLOPS_DEPLOYMENT_ID is used.
            // If the model ID is not specified, the environment variable MLOPS_MODEL_ID is used.
            // If the output type is not specified, the environment variable MLOPS_SPOOLER_TYPE is used.
            mlops = MLOps.getInstance()
                    .setDeploymentId(deploymentId)
                    .setModelId(modelId)
                    .setStdoutSpooler()
                    .init();

            // Create a set of feature values for each sample
            // For this example, we simply generate the feature values.
            Map<String, List<Object>> featureData = makeFakeFeatureData(numSamples);

            // Call the model to generate predictions.
            // For this example, we simply fake the generating a random number of predictions.
            long startTime = System.currentTimeMillis();
            List<Double> predictions = makeFakeRegressionPredictionsList(numSamples);
            long endTime = System.currentTimeMillis();

            // MLOPS: report the feature data and predictions together to mlops
            mlops.reportPredictionsData(featureData, predictions);

            // MLOPS: report number of samples and time to produce predictions
            mlops.reportDeploymentStats(numSamples, endTime - startTime);


        } catch (DRCommonException e) {
            System.out.println(e.getMessage());
        } finally {
            // MLOPS: shutdown
            if (mlops != null) {
                mlops.shutdown();
            }
        }
    }

    public static void main(String args[]) {
        int numSamples = 10;
        String deploymentId = "sample_deployment_id";
        String modelId = "sample_model_id";
        RegressionSampleCode regressionExample = new RegressionSampleCode(deploymentId, modelId);
        regressionExample.run(numSamples);
    }
}



