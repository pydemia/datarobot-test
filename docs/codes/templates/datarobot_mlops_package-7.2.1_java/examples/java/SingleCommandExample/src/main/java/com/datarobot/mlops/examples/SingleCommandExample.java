package com.datarobot.mlops.examples;
import com.datarobot.mlops.MLOps;
import com.datarobot.mlops.common.exceptions.DRCommonException;
import com.datarobot.prediction.IClassificationPredictor;
import com.datarobot.prediction.IPredictorInfo;
import com.datarobot.prediction.Predictors;

import com.opencsv.CSVReader;
import com.opencsv.CSVReaderBuilder;
import org.apache.commons.cli.*;

import java.io.File;
import java.io.FileReader;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SingleCommandExample {

    private static final String FEATURES_CSV_FILE_NAME = "features-csv";
    private static final String MODEL_JAR_FILE_NAME = "model-jar";
    private static final String MLOPS_SERVICE_URL = "mlops-url";
    private static final String MLOPS_API_TOKEN = "token";
    private static final String FS_SPOOLER_DIRECTORY = "spool-dir";
    private static final String FS_SPOOLER_DIRECTORY_DEFAULT = "/tmp/ta";

    private String csvFileName;
    private String dataRobotUrl;
    private String dataRobotToken;
    private String codeGenJarFilename = null;
    private Path fsSpoolerDirectory = null;

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

    private void parseCmdLine(String[] args) {
        Options options = new Options();

        Option modelJarOption = Option.builder()
                .longOpt(MODEL_JAR_FILE_NAME)
                .hasArg(true)
                .required(false)
                .desc("CodeGen model jar used to make predictions")
                .build();
        options.addOption(modelJarOption);

        Option csvFileNameOption = Option.builder()
                .longOpt(FEATURES_CSV_FILE_NAME)
                .hasArg(true)
                .required(true)
                .desc("Name of the CSV file to read features from")
                .build();
        options.addOption(csvFileNameOption);

        Option dataRobotUrlOption = Option.builder()
                .longOpt(MLOPS_SERVICE_URL)
                .hasArg(true)
                .required(true)
                .desc("URL of DataRobot MLOps")
                .build();
        options.addOption(dataRobotUrlOption);

        Option dataRobotTokenOption = Option.builder()
                .longOpt(MLOPS_API_TOKEN)
                .hasArg(true)
                .required(true)
                .desc("API token for DataRobot MLOps")
                .build();
        options.addOption(dataRobotTokenOption);

        Option spoolerOption = Option.builder()
                .longOpt(FS_SPOOLER_DIRECTORY)
                .hasArg(true)
                .required(false)
                .desc("Path to the spool directory(only for filesystem spooler")
                .build();
        options.addOption(spoolerOption);

        Option helpOption = Option.builder("h").longOpt("help").desc("prints this message").build();
        options.addOption(helpOption);

        CommandLineParser parser = new DefaultParser();
        HelpFormatter formatter = new HelpFormatter();
        CommandLine cmd;

        try {
            cmd = parser.parse(options, args);
            if (cmd.hasOption("help")) {
                formatter.printHelp("SingleCommandExample ", options);
                System.exit(0);
            }

            this.csvFileName = validateArgument(cmd, FEATURES_CSV_FILE_NAME);
            this.dataRobotUrl  = validateArgument(cmd, MLOPS_SERVICE_URL);
            this.dataRobotToken  = validateArgument(cmd, MLOPS_API_TOKEN);
            this.fsSpoolerDirectory = createSpoolerDirectory(cmd);

            if (cmd.hasOption(MODEL_JAR_FILE_NAME)) {
                this.codeGenJarFilename = cmd.getOptionValue(MODEL_JAR_FILE_NAME);
            }

        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            formatter.printHelp("SingleCommandExample ", options);
            System.exit(-1);
        }
    }

    private Path createSpoolerDirectory(CommandLine cmd) throws DRCommonException {
        String directoryStr = cmd.getOptionValue(FS_SPOOLER_DIRECTORY, FS_SPOOLER_DIRECTORY_DEFAULT);
        File directory = Paths.get(directoryStr).toFile();

        if (directory.exists() && directory.isFile()) {
            throw new DRCommonException(String.format("Provided directory is a file - %s ", directory));
        }

        if (!directory.exists() && !directory.mkdirs()) {
            throw new DRCommonException(String.format("Fail to create spooler directory - %s", directory));
        }

        return directory.toPath();
    }

    /**
     * Load the CodeGen model from the model jar file
     */
    IPredictorInfo loadModel(String modelFilePath) {
        IPredictorInfo predictor = null;
        try {
            File filePath = new File(modelFilePath);
            URL[] urls = new URL[]{new URL("file://" + filePath.getCanonicalPath())};

            // Create a new URLClassLoader to avoid class name conflicts in the jar
            URLClassLoader urlClassLoader = URLClassLoader.newInstance(urls, this.getClass().getClassLoader());
            predictor = Predictors.getPredictor(urlClassLoader);

        } catch (Exception e) {
            System.err.println("Failed to load model. " + e.getMessage());
            System.exit(-1);
        }
        return predictor;
    }

    public List<String[]> readAllDataAtOnce(String file) {
        List<String[]> allData = null;
        try {
            // Create an object of file reader
            // class with CSV file as a parameter.
            FileReader filereader = new FileReader(file);

            // create csvReader object
            CSVReader csvReader = new CSVReaderBuilder(filereader)
                    .build();
            allData = csvReader.readAll();

        } catch (Exception e) {
            e.printStackTrace();
        }

        return allData;
    }

    /**
     * Convert rows to a format that CodeGen uses for input
     * @param featureNames list of feature column names
     * @param rows input rows as arrays of strings
     * @param skipHeader whether to skip the first (header) row
     * @return rows converted into a list of feature name to value maps
     */
    public List<Map<String, Object>> convertRowsToListOfFeatureDicts(String[] featureNames, List<String[]> rows, Boolean skipHeader) {
        List<Map<String, Object>> listOfFeatureDicts = new ArrayList<>();

        int startRow = 0;
        if (skipHeader) {
            startRow = 1;
        }

        // convert each sample row to a map of <"feature name", feature value>
        for (String[] row : rows.subList(startRow, rows.size())) {
            Map<String, Object> sample = new HashMap<>();
            for (int i = 0; i < featureNames.length; ++i) {
                sample.put(featureNames[i], row[i]);
            }
            listOfFeatureDicts.add(sample);
        }
        return listOfFeatureDicts;
    }

    /**
     * Call the CodeGen model to make predictions on the samples
     * @param samples
     * @return list of predictions. For classification models, each prediction is a map of classname to probability
     *         (as a Double) for each possible class.
     */
    List<Map<String,Double>> makeClassificationPredictions(IClassificationPredictor predictor, List<Map<String, Object>> samples) {
        List<Map<String,Double>> predictions = new ArrayList<>();
        Map<String, Double> score;

        for (Map<String, Object> sample : samples) {
            // return map of each class label to its probability
            if (predictor != null) {
                score = predictor.score(sample);
            } else {
                // if we have now model, fake the predictions for class labels "1" and "0"
                score = new HashMap<>();
                score.put("1", .15);
                score.put("0", .85);
            }
            predictions.add(score);
        }
        return predictions;
    }

    public void run (String args[]) {
        IClassificationPredictor model = null;

        parseCmdLine(args);

        // load CodeGen classification model if provided
        if (this.codeGenJarFilename != null) {
            IPredictorInfo m = loadModel(codeGenJarFilename);
            if (m instanceof IClassificationPredictor) {
                model = (IClassificationPredictor) m;
            } else {
                System.err.println("This example only supports Classification CodeGen models.");
                System.exit(-1);
            }
        }

        // read csv, convert to features for CodeGen
        List<String[]> rows = readAllDataAtOnce(this.csvFileName);
        String[] headers = rows.get(0);
        List<Map<String, Object>> listOfFeatureMaps = convertRowsToListOfFeatureDicts(headers, rows, true);

        // MLOPS: declaration
        MLOps mlops = null;
        try {
            if (!MLOps.agentIsAvailable()) {
                System.err.println("The agent is not included in this example.");
                System.exit(-1);
            }

            // MLOPS: initialize mlops instance, include agent configuration
            mlops = MLOps.getInstance()
                    .setSyncReporting()
                    .setFilesystemSpooler(fsSpoolerDirectory.toAbsolutePath().toString())
                    .agent(dataRobotUrl, dataRobotToken)
                    .init();

            // make predictions
            long startTime = System.currentTimeMillis();
            List<Map<String,Double>> predictions = makeClassificationPredictions(model, listOfFeatureMaps);
            long endTime = System.currentTimeMillis();

            // MLOPS: report number of samples and time to produce predictions.
            mlops.reportDeploymentStats(listOfFeatureMaps.size(), endTime - startTime);

            // MLOPS: report feature data and predictions together to MLOps service;
            // this is used for feature drift and target drift calculation
            mlops.reportPredictionsDataList(listOfFeatureMaps, predictions);

        } catch (DRCommonException e) {
            System.out.println(e.getMessage());
            System.exit(-1);
        } finally {
            // MLOPS: shutdown
            if (mlops != null) {
                mlops.shutdown();
            }
        }
    }

    public static void main(String args[]) {
        SingleCommandExample example = new SingleCommandExample();
        example.run(args);
        System.exit(0);
    }
}