
package com.datarobot.mlops.examples;


import com.datarobot.mlops.MLOps;
import com.datarobot.mlops.common.exceptions.DRCommonException;
import com.datarobot.prediction.IClassificationPredictor;
import com.datarobot.prediction.IRegressionPredictor;
import com.opencsv.CSVReader;
import com.opencsv.CSVReaderBuilder;

import java.io.File;
import java.io.FileWriter;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.datarobot.prediction.IPredictorInfo;
import com.datarobot.prediction.Predictors;
import com.opencsv.CSVWriter;

import java.io.FileReader;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.*;

public class CodeGenExample {

    private String modelFilePath;
    private String csvFilePath;
    private String actualsFilePath;

    public CodeGenExample(String modelFilePath, String csvFilePath, String actualsFilePath) {
        this.modelFilePath = modelFilePath;
        this.csvFilePath = csvFilePath;
        this.actualsFilePath = actualsFilePath;
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
            System.exit(1);
        }
        return predictor;
    }

    /**
     * Call the CodeGen model to make predictions on the samples
     * @param samples
     * @return list of predictions. For regression models, each prediction is a Double.
     */
    List<?> makeRegressionPredictions(IRegressionPredictor predictor, List<Map<String, Object>> samples) {
        List<Double> predictions = new ArrayList<>();

        for (Map<String, Object> sample : samples) {
            Double score = predictor.score(sample);

            predictions.add(score);
        }

        return predictions;
    }

    /**
     * Call the CodeGen model to make predictions on the samples
     * @param samples
     * @return list of predictions. For classification models, each prediction is a map of classname to probability
     *         (as a Double) for each possible class.
     */
    List<Map<String,Double>> makeClassificationPredictions(IClassificationPredictor predictor, List<Map<String, Object>> samples) {
        List<Map<String,Double>> predictions = new ArrayList<>();

        for (Map<String, Object> sample : samples) {
            // return map of each class label to its probability
            Map<String,Double> score = predictor.score(sample);
            predictions.add(score);
        }
        return predictions;
    }

    List<?> makePredictions(IPredictorInfo predictor, List<Map<String, Object>> samples) {
        List<?> predictions = null;

        if (predictor instanceof IRegressionPredictor) {
            predictions = makeRegressionPredictions((IRegressionPredictor)predictor, samples);
        } else if (predictor instanceof IClassificationPredictor) {
            predictions = makeClassificationPredictions((IClassificationPredictor)predictor, samples);
        } else {
            System.err.println("Unknown predictor type: " + predictor.getPredictorClass());
            System.exit(1);
        }

        return predictions;
    }

    /**
     * Sample code demonstrating how to use MLOps library to record metrics on classification predictions.
     * All code specific to MLOps library are commented with "MLOPS"
     */
    public void run() {
        IPredictorInfo predictor = loadModel(modelFilePath);
        List<String[]> rows = readAllDataAtOnce(csvFilePath);

        String[] headers = rows.get(0);
        List<Map<String, Object>> listOfFeatureMaps = convertRowsToListOfFeatureDicts(headers, rows, true);

        // MLOPS: declaration
        MLOps mlops = null;
        try {

            // MLOPS: initialize mlops instance, initialize it with the model ID from the CodeGen model
            mlops = MLOps.getInstance().init();

            List<String> associationIds = generateAssociationIdsForPredictions(listOfFeatureMaps.size());

            // Call the model to generate predictions.
            long startTime = System.currentTimeMillis();
            List<?> predictions = makePredictions(predictor, listOfFeatureMaps);
            long endTime = System.currentTimeMillis();

            // MLOPS: report number of samples and time to produce predictions.
            mlops.reportDeploymentStats(listOfFeatureMaps.size(), endTime - startTime);

            // MLOPS: report feature data and predictions together to MLOps service;
            // this is used for feature drift and target drift calculation
            mlops.reportPredictionsDataList(listOfFeatureMaps, predictions, associationIds, null);

            if (actualsFilePath != null) {
                writeActualsFile(associationIds, predictions);
            } else {
                System.out.println("Actual file was not provided, not generating actuals file");
            }

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
    private void writeActualsFile(List<String> associationIds, List<?> predictions) {
        File actualFile = new File(actualsFilePath);
        if (actualFile.exists()) {
            System.err.println("Output CSV file file '" + actualsFilePath + "' already exists");
            System.exit(1);
        }
        // Generate a placeholder CSV file with the association ids, so that user can then fill
        // the actual values and use it to submit actuals
        //
        // For the purpose of this example, this code generates random regression value to store in
        // the csv file
        try (FileWriter csvWriter = new FileWriter(actualFile, true)) {
            CSVWriter writer = new CSVWriter(csvWriter, ',', CSVWriter.NO_QUOTE_CHARACTER,
                    CSVWriter.NO_ESCAPE_CHARACTER, CSVWriter.DEFAULT_LINE_END);

            String[] header = {"associationId", "wasActedOn", "actualValue", "timestamp"};
            writer.writeNext(header);
            SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX");
            String[] row = new String[4];

            for (int i=0 ; i < associationIds.size() ; i++) {
                row[0] = associationIds.get(i);
                row[1] = "False";
                row[2] = predictions.get(i).toString();
                row[3] = format.format(new Date(System.currentTimeMillis()));
                writer.writeNext(row);
                writer.flush();
            }
            csvWriter.flush();
        } catch (Exception e) {
            System.err.println("Failed to write CSV File: " + e);
            System.exit(1);
        }

        System.out.println("Stored all association ids in CSV file: '" + actualsFilePath + "'");
        System.out.println("Once actuals are ready, you can edit the csv file and put actual values in it.");
        System.out.println("You can then use the utility './upload_actuals.py' to upload the actuals " +
                "to DR server to calculate accuracy");
    }

    public static void main(String args[]) {
        String modelFilePath;
        String csvFilePath;
        String actualsFilePath = null;
        try {
            modelFilePath = args[0];
            csvFilePath = args[1];
            if (args.length >= 3) {
                actualsFilePath = args[2];
            }

        } catch (Exception e) {
            String thisProgram = new java.io.File(CodeGenExample.class.getProtectionDomain()
                    .getCodeSource()
                    .getLocation()
                    .getPath())
                    .getName();
            System.err.println("Usage: java -jar " + thisProgram +
                    " <codeGenModelFilePath>  <csvFilePath> [<actualsFilePath>]");
            System.exit(1);
            return;
        }

        CodeGenExample codeGenExample = new CodeGenExample(modelFilePath, csvFilePath, actualsFilePath);
        codeGenExample.run();
    }
}
