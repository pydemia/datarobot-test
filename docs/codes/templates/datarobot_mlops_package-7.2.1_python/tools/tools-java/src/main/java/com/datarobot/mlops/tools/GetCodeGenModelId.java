
package com.datarobot.mlops.tools;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.datarobot.prediction.IPredictorInfo;
import com.datarobot.prediction.Predictors;

import java.io.FileReader;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.*;

public class GetCodeGenModelId {
    private String modelFilePath;
    private IPredictorInfo predictorInfo;

    GetCodeGenModelId(String modelFilePath) {
        this.modelFilePath = modelFilePath;
    }

    /**
     * Load the CodeGen model from the model jar file
     */
    void loadModel() {
        try {
            File filePath = new File(modelFilePath);
            URL[] urls = new URL[]{new URL("file://" + filePath.getCanonicalPath())};
            URLClassLoader urlClassLoader = new URLClassLoader(urls);
            this.predictorInfo = Predictors.getPredictor(urlClassLoader);

        } catch (Exception e) {
            System.out.println("Failed to load model. " + e.getMessage());
            System.exit(1);
        }
    }

    /**
     * Load the model from the jar file, then print its modelID.
     */
    public void run() {
        loadModel();
        System.out.println("MLOPS_MODEL_ID=" + predictorInfo.getModelId());
        System.exit(0);
    }

    public static void main(String args[]) {
        String modelFilePath;

        try {
            modelFilePath = args[0];
        } catch (Exception e) {
            String thisProgram = new java.io.File(GetCodeGenModelId.class.getProtectionDomain()
                    .getCodeSource()
                    .getLocation()
                    .getPath())
                    .getName();
            System.err.println("Usage: java -jar " + thisProgram + " <codeGenModelFilePath>");
            System.exit(1);
            return;
        }

        GetCodeGenModelId getModelId = new GetCodeGenModelId(modelFilePath);
        getModelId.run();
    }
}
