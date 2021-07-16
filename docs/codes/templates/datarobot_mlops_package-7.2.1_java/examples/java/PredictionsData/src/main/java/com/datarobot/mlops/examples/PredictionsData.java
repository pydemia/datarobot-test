
package com.datarobot.mlops.examples;

import com.datarobot.mlops.MLOps;
import com.datarobot.mlops.common.exceptions.DRCommonException;
import org.apache.commons.cli.*;
import com.fasterxml.jackson.dataformat.csv.CsvMapper;
import com.fasterxml.jackson.dataformat.csv.CsvSchema;
import com.opencsv.CSVWriter;

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.text.SimpleDateFormat;
import java.util.*;

public class PredictionsData {
    private static Random rand;
    private static PredictionsDataDemoConfig config;

    private static final String DEPLOYMENT_ID = "deployment-id";
    private static final String MODEL_ID = "model-id";
    private static final String DEPLOYMENT_TYPE = "deployment-type";
    private static final String NUM_SAMPLES = "num-samples";
    private static final String FEATURES_CSV_FILE_NAME = "features-csv-file-name";
    private static final String ACTUALS_CSV_FILE_NAME = "actuals-csv-file-name";
    private static final int DEFAULT_NUM_SAMPLES = 100;

    public static List<Double> makeRandomRegressionPredictions(int numSamples) {
        List<Double> predictions = new ArrayList<Double>(numSamples);
        for (int i = 0; i < numSamples; i++) {
            predictions.add(rand.nextDouble());
        }

        return predictions;
    }

    private static List<String> generateAssociationIdsForPredictions(int numSamples) {
        List<String> associationIds = new ArrayList<String>(numSamples);
        long currentTimestamp = System.currentTimeMillis();
        String prefix = "x_" + currentTimestamp;
        for (int j = 0; j < numSamples; j++) {
            associationIds.add(prefix + "_" + j);
        }
        System.out.println("Association Ids generated with prefix: '" + prefix + "'" +
                " From '" + prefix + "_0' .... '" + prefix + "_" + (numSamples - 1) + "'");
        return associationIds;
    }

    public static List<List<Double>> makeRandomBinaryPredictions(int numSamples) {
        List<List<Double>> predictions = new ArrayList<List<Double>>(numSamples);
        for (int i = 0; i < numSamples; i++) {
            double prediction = rand.nextDouble();
            Double[] binaryPrediction = new Double[2];
            binaryPrediction[0] = prediction;
            binaryPrediction[1] = 1 - prediction;
            predictions.add(Arrays.asList(binaryPrediction));
        }
        return predictions;
    }

    public static Object makeRandomPredictions(int numSamples, String deploymentType) {
        if (deploymentType.contentEquals("Regression")) {
            return makeRandomRegressionPredictions(numSamples);
        }
        return makeRandomBinaryPredictions(numSamples);
    }

    public static String getRandomActualValue(String deploymentType) {
        if (deploymentType.contentEquals("Regression")) {
            return Double.toString(rand.nextDouble());
        } else if (deploymentType.contentEquals("Binary")) {
            if (rand.nextFloat() < 0.5) {
                return "0";
            } else {
                return "1";
            }
        }
        return "";
    }

    /**
     * Sample code demonstrating how to use MLOps library to record metrics on regression predictions.
     * All code specific to MLOps library are commented with "MLOPS"
     */
    public static void run() {
        // For this example, we simply fake the generating a random number of predictions.
        long startTime = System.currentTimeMillis();
        Object predictions = makeRandomPredictions(config.numSamples, config.deploymentType);
        List<String> associationIds = generateAssociationIdsForPredictions(config.numSamples);
        Map<String, List<Object>> featureData = readFeaturesCSV();
        writeActualsFile(associationIds);
        long endTime = System.currentTimeMillis();
        List<String> classNames = new ArrayList<>(Arrays.asList("0", "1"));

        // MLOPS: declaration
        MLOps mlops = null;
        try {

            // MLOPS: initialize mlops instance.
            // If the output type is not specified, the environment variable MLOPS_SPOOLER_TYPE is used.
            mlops = MLOps.getInstance()
                    .setDeploymentId(config.deploymentId)
                    .setModelId(config.modelId)
                    .init();

            // MLOPS: report stats to MLOps Service
            mlops.reportDeploymentStats(config.numSamples, endTime - startTime);
            // MLOPS: report the predictions to mlops
            mlops.reportPredictionsData(featureData, (List<?>)predictions, associationIds, classNames);

        } catch (DRCommonException e) {
            System.out.println(e.getMessage());
            System.exit(1);
        } finally {
            // MLOPS: shutdown
            if (mlops != null) {
                mlops.shutdown();
            }
        }
    }

    private static Map<String, List<Object>> readFeaturesCSV() {
        File csvFile = new File(config.csvFileName);
        if (!csvFile.exists()) {
            System.err.println("Features CSV file file '" + config.csvFileName + "' does not exist");
            System.exit(1);
        }
        // Read the Features CSV file into a feature_data map
        Map<String, List<Object>> featureData = new HashMap<>();
        try (FileReader csvReader = new FileReader(csvFile)) {
            int index = 0;
            Iterator<Map<String, Object>> iterator = new CsvMapper()
                    .readerFor(Map.class)
                    .with(CsvSchema.emptySchema().withHeader())
                    .readValues(csvReader);
            while (iterator.hasNext()) {
                Map<String, Object> keyVals = iterator.next();
                for (Map.Entry<String, Object> entry : keyVals.entrySet()) {
                    if (!featureData.containsKey(entry.getKey())) {
                        featureData.put(entry.getKey(), new ArrayList<>());
                    }
                    featureData.get(entry.getKey()).add(entry.getValue());
                }
                index++;
                if (index == config.numSamples) {
                    break;
                }
            }
        } catch (Exception e) {
            System.err.println("Failed to read CSV File: " + e);
            System.exit(1);
        }
        return featureData;
    }

    private static void writeActualsFile(List<String> associationIds) {
        File csvFile = new File(config.actualsCSVFile);
        if (csvFile.exists()) {
            System.err.println("Output CSV file file '" + config.actualsCSVFile + "' already exists");
            System.exit(1);
        }
        // Generate a placeholder CSV file with the association ids, so that user can then fill
        // the actual values and use it to submit actuals
        //
        // For the purpose of the demo, this code generates random regression value to store in
        // the csv file
        try (FileWriter csvWriter = new FileWriter(csvFile, true)) {
            CSVWriter writer = new CSVWriter(csvWriter, ',', CSVWriter.DEFAULT_QUOTE_CHARACTER,
                    CSVWriter.DEFAULT_ESCAPE_CHARACTER, CSVWriter.DEFAULT_LINE_END);

            String[] header = {"associationId", "wasActedOn", "actualValue", "timestamp"};
            writer.writeNext(header);
            SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX");
            String[] row = new String[4];
            for (String associationId : associationIds) {
                row[0] = associationId;
                row[1] = "False";
                row[2] = getRandomActualValue(config.deploymentType);
                row[3] = format.format(new Date(System.currentTimeMillis()));
                writer.writeNext(row);
                writer.flush();
            }
            csvWriter.flush();
        } catch (Exception e) {
            System.err.println("Failed to write CSV File: " + e);
            System.exit(1);
        }

        System.out.println("Stored all association ids in CSV file: '" + config.actualsCSVFile + "'");
    }

    private static PredictionsDataDemoConfig parseCmdLine(String[] args) {
        Options options = new Options();

        Option deploymentIdOption = Option.builder()
                .longOpt(DEPLOYMENT_ID)
                .hasArg(true)
                .required(true)
                .desc("ID of the deployment to generate predictions and association ids for")
                .build();
        options.addOption(deploymentIdOption);

        Option modelIdOption = Option.builder()
                .longOpt(MODEL_ID)
                .hasArg(true)
                .required(true)
                .desc("ID of the model used to make predictions")
                .build();
        options.addOption(modelIdOption);

        Option numSamplesOption = Option.builder()
                .longOpt(NUM_SAMPLES)
                .hasArg(true)
                .required(false)
                .type(long.class)
                .desc("Number of predictions to generate")
                .build();
        options.addOption(numSamplesOption);

        Option deploymentTypeOption = Option.builder()
                .longOpt(DEPLOYMENT_TYPE)
                .hasArg(true)
                .required(true)
                .desc("Type of deployment for which to generate predictions: 'Regression' or 'Binary'")
                .build();
        options.addOption(deploymentTypeOption);

        Option csvFileNameOption = Option.builder()
                .longOpt(FEATURES_CSV_FILE_NAME)
                .hasArg(true)
                .required(true)
                .desc("Name of the CSV file to read features from")
                .build();
        options.addOption(csvFileNameOption);

        Option actualsCSVFileOption = Option.builder()
                .longOpt(ACTUALS_CSV_FILE_NAME)
                .hasArg(true)
                .required(true)
                .desc("Name of the CSV file where to save association IDs")
                .build();
        options.addOption(actualsCSVFileOption);
        Option helpOption = Option.builder("h").longOpt("help").desc("prints this message").build();
        options.addOption(helpOption);

        CommandLineParser parser = new DefaultParser();
        HelpFormatter formatter = new HelpFormatter();
        CommandLine cmd;

        try {
            cmd = parser.parse(options, args);
            if (cmd.hasOption("help")) {
                formatter.printHelp("PredictionsData Demo", options);
                System.exit(0);
            }

            String deploymentId = validateArgument(cmd, DEPLOYMENT_ID);
            String modelId = validateArgument(cmd, MODEL_ID);
            String deploymentType = validateArgument(cmd, DEPLOYMENT_TYPE);
            if (!deploymentType.contentEquals("Regression") && !deploymentType.contentEquals("Binary")) {
                throw new Exception("Invalid deployment type: '" + deploymentType +
                        "'.  Allowed values: 'Regression' and 'Binary'");
            }
            String csvFileName = validateArgument(cmd, FEATURES_CSV_FILE_NAME);
            String actualsCSVFile = validateArgument(cmd, ACTUALS_CSV_FILE_NAME);

            int numSamples = DEFAULT_NUM_SAMPLES;
            if (cmd.hasOption(NUM_SAMPLES)) {
                String str = cmd.getOptionValue(NUM_SAMPLES);
                if (str != null && !str.isEmpty()) {
                    numSamples = Integer.parseInt(str);
                }
            }

            return new PredictionsDataDemoConfig(deploymentId, modelId, deploymentType,
                    csvFileName, actualsCSVFile, numSamples);
        } catch (Exception e) {
            System.err.println("Demo error: " + e.getMessage());
            formatter.printHelp("PredictionsData Demo", options);
            System.exit(1);
            return null;
        }
    }

    private static String validateArgument(CommandLine cmd, String key) throws Exception {
        if (!cmd.hasOption(key)) {
            throw new Exception(String.format("'%s' parameter not provided", key));
        }

        String value = cmd.getOptionValue(key);
        if (value == null || value.isEmpty()) {
            throw new Exception(String.format("'%s' ID is not provided", key));
        }
        return value;
    }

    public static void main(String args[]) {
        config = parseCmdLine(args);
        rand = new Random();
        run();
    }

    public static class PredictionsDataDemoConfig {
        private String deploymentId;
        private String modelId;
        private int numSamples;
        private String deploymentType;
        private String csvFileName;
        private String actualsCSVFile;

        public PredictionsDataDemoConfig(String deploymentId,
                                 String modelId,
                                 String deploymentType,
                                 String csvFileName,
                                 String actualsCSVFile,
                                 int numSamples)
        {
            this.csvFileName = csvFileName;
            this.deploymentId = deploymentId;
            this.deploymentType = deploymentType;
            this.modelId = modelId;
            this.numSamples = numSamples;
            this.actualsCSVFile = actualsCSVFile;
        }
    }
}
