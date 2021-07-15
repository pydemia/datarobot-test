/**
 *  Usage:
 *  DataRobot's Monitoring Agent is an advanced feature that enables monitoring for models deployed
 *  outside of DataRobot. Follow these steps to use this feature.
 *  1. Download and extract DataRobot's Monitoring Agent tar file. This is available through the
 *     DataRobot MLOps UI via User icon -> "Developer Tools" -> "External Monitoring Agent".
 *  2. Open your preferred browser. In toolbar, click "File" -> "Open File".
 *     Then choose this file <your unpacked directory>/docs/html/quickstart.html.
 *  3. Follow the "Quick Start" instructions to set up the Monitoring Agent.
 *  4. Install the datarobot-mlops jar file into the local mvn repository.
 *     Go to <your unpacked directory>/examples/java directory, run:
 *     ./install_jar_into_maven.sh
 *  5. Include datarobot-mlops maven dependency in your pom.xml
 *     <dependency>
 *         <groupId>com.datarobot</groupId>
 *         <artifactId>datarobot-mlops</artifactId>
 *         <version>[6.2,)</version>
 *     </dependency>
 *  6. Compile your java code:
 *     mvn package
 *  7. The MLOps library requires the following parameters to be provided:
 *     deployment ID, model ID, and spooler type [FILESYSTEM, SQS, RABBITMQ, PUBSUB, STDOUT, NONE].
 *     The spooler type selected may require additional configuration. For example,
 *     if the spooler type is FILESYSTEM, the filesystem directory will have to be configured.
 *     The spooler directory path must match the Monitoring Agent path configured by the administrator.
 *     For more details and advanced usage, see the examples and documentation included with the agent tar file.
 *     These parameters can be configured with the MLOps library APIs or with environment variables.
 *     For example:
 *     # export MLOPS_DEPLOYMENT_ID=60f0443ed7733e8161155078
 *     # export MLOPS_MODEL_ID=60f03f8e0a3504f0d3764a06
 *     # export MLOPS_SPOOLER_TYPE=OUTPUT_DIR
 *     # export MLOPS_FILESYSTEM_DIRECTORY=/tmp/ta
 *  8. Execute the java example:
 *     java -jar <jar_file_created_in_step_6> <datarobot_model_jar_file> <dataset_in_csv_format>
 *
 *     Notes:
 *            - parameter configuration via environment variables takes precedence over the API.
 *            - for testing purposes, you can start with STDOUT spooler type,
 *              which doesn't require providing any of the spooler-related parameters. The reporting results
 *              are sent to stdout and not forwarded to the Monitoring Agent or DataRobot MLOps.
 *            - depending on how your Java package is defined, provide a package directive for this file, e.g:
 *              package com.datarobot.mlops.examples;
 *            - complete examples are included in the agent tar file in the `examples` directory.
 */
 
import com.datarobot.mlops.MLOps;
import com.datarobot.mlops.common.exceptions.DRCommonException;
import com.datarobot.prediction.IPredictorInfo;
import com.datarobot.prediction.IRegressionPredictor;
import com.datarobot.prediction.Predictors;
import com.opencsv.CSVReader;
import com.opencsv.CSVReaderBuilder;
 
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.net.URL;
import java.net.URLClassLoader;
 
public class MLOpsCodeGenRegressionExample {
    private String modelFilePath;
    private String csvFilePath;
    private String[] sampleHeaders;
    private IRegressionPredictor predictor;
 
    MLOpsCodeGenRegressionExample(String modelFilePath, String csvFilePath) {
        this.modelFilePath = modelFilePath;
        this.csvFilePath = csvFilePath;
    }
 
    public List<Map<String, Object>> readAllDataAtOnce(String file) throws IOException {
        List<String[]> allData = null;
        try {
            // Create an object of file reader
            // class with CSV file as a parameter.
            FileReader filereader = new FileReader(file);
 
            // create csvReader object
            CSVReader csvReader = new CSVReaderBuilder(filereader)
                    .build();
            allData = csvReader.readAll();
        } catch (IOException e) {
            System.err.println("Failed to read data file - " + file);
            throw e;
        }
 
        List<Map<String, Object>> listOfSamples = new ArrayList<>();
        this.sampleHeaders = allData.get(0);
 
        for (String[] row : allData.subList(1, allData.size())) {
            Map<String, Object> sample = new HashMap<>();
            for (int i = 0; i < this.sampleHeaders.length; ++i) {
                sample.put(this.sampleHeaders[i], row[i]);
            }
            listOfSamples.add(sample);
        }
        return listOfSamples;
    }
 
    /**
     * Load the CodeGen model from the model jar file
     */
    void loadModel() throws IOException, DRCommonException {
        try {
            File filePath = new File(modelFilePath);
            URL[] urls = new URL[]{new URL("file://" + filePath.getCanonicalPath())};
            URLClassLoader urlClassLoader = new URLClassLoader(urls);
            IPredictorInfo predictorInfo = Predictors.getPredictor(urlClassLoader);
 
            if (!(predictorInfo instanceof IRegressionPredictor)) {
                throw new DRCommonException("Provided model is not a Java CodeGen regression model");
            }
 
            this.predictor = (IRegressionPredictor) predictorInfo;
 
        } catch (IOException e) {
            System.err.println("Failed to load model. " + e.getMessage());
            throw e;
        }
    }
 
    /**
     * Call the CodeGen model to make predictions on the samples
     * @param samples
     * @return
     */
    List<Double> makePredictions(List<Map<String, Object>> samples) {
        List<Double> predictions = new ArrayList<>();
 
        for (Map<String, Object> sample : samples) {
            // return map of class label to its probability
            Double score = predictor.score(sample);
 
            predictions.add(score);
        }
 
        return predictions;
    }
 
 
    HashMap<String, List<Object>> getFeaturesFromSamples(List<Map<String, Object>> samples) {
        HashMap<String, List<Object>> featureData = new HashMap<>();
 
        for (Map<String, Object> sample : samples) {
            for (Map.Entry<String, Object> entry : sample.entrySet()) {
                List<Object> featureValues = featureData.get(entry.getKey());
                if (featureValues == null) {
                    featureValues = new ArrayList<>();
                    featureData.put(entry.getKey(), featureValues);
                }
                featureValues.add(entry.getValue());
            }
        }
 
        return featureData;
    }
 
    /**
     * Sample code demonstrating how to use MLOps library to record metrics on classification predictions.
     * All code specific to MLOps library are commented with "MLOPS"
     */
    public void run() {
        // MLOPS: declaration
        MLOps mlops = null;
        try {
            loadModel();
 
            List<Map<String, Object>> samples = readAllDataAtOnce(this.csvFilePath);
 
            HashMap<String, List<Object>> featureData = getFeaturesFromSamples(samples);
 
            // MLOPS: initialize mlops instance
            mlops = MLOps.getInstance()
                    .setDeploymentId("60f0443ed7733e8161155078")
                    .setModelId("60f03f8e0a3504f0d3764a06")
                    .setFilesystemSpooler("/tmp/ta")
                    .init();
 
            // Call the model to generate predictions.
            // For this example, we simply fake the predictions.
            long startTime = System.currentTimeMillis();
            List<Double> predictions = makePredictions(samples);
            long endTime = System.currentTimeMillis();
 
            // MLOPS: report predictions data: features, predictions, the 'null' arguments below
            // are for 'associationIds' (required for calculating accuracy - not included in this
            // snippet) and 'classNames' (no classes for regression deployment)
            mlops.reportPredictionsData(featureData, (List<?>)predictions, null, null);
 
            // MLOPS: report number of samples and time to produce predictions.
            mlops.reportDeploymentStats(samples.size(), endTime - startTime);
 
        } catch (Exception e) {
            System.err.println("Failed to report statistics, check the error below");
            e.printStackTrace();
            System.exit(-1);
        } finally {
            // MLOPS: shutdown
            if (mlops != null) {
                mlops.shutdown();
            }
        }
    }
 
    public static void main(String args[]) {
        String modelFilePath;
        String csvFilePath;
 
        try {
            modelFilePath = args[0];
            csvFilePath = args[1];
        } catch (Exception e) {
            String thisProgram = new java.io.File(MLOpsCodeGenRegressionExample.class.getProtectionDomain()
                    .getCodeSource()
                    .getLocation()
                    .getPath())
                    .getName();
            System.err.println("Usage: java -jar " + thisProgram + " <codeGenModelFilePath>" + " <csvFilePath>");
            System.exit(1);
            return;
        }
 
        MLOpsCodeGenRegressionExample codeGenExample = new MLOpsCodeGenRegressionExample(modelFilePath, csvFilePath);
        codeGenExample.run();
    }
}
 