# DataRobot Test

## Menu

* AI Catalog
* MLOps
* Model Registry
  * Add new package
    * [New external model package]()
* Applications


## AI Catalog

## MLOps

## Model Registry

### Add new package

* New external model package
![Build Environment](img/model_registry/model_build_env.png)
* Select a dataset from the AI Catalog
![](img/model_registry/select_from_ai_catalog.png)
* Select Target
![](img/model_registry/select_target.png)
* Select Prediction type
![](img/model_registry/select_pred_type.png)
* Show the Model package
![](img/model_registry/model_package.png)


### Actions in Model Package

#### Share
![](img/model_registry/share_the_model.png)

#### Permanently Archive
![](img/model_registry/permanent_archive_the_model.png)


#### Deploy

##### Pre-defined & Fixed

* Model & Prediction Type, Target
* Training Data

##### Options

* Timestamp (Request Time | Data itself: By the feature name)
*  

![](img/model_registry/deploy_the_model.png)

Select Prediction Environment
![](img/model_registry/deploy_prediction_env.png)

###### Functionality: Data Drift
* Tracking
![](img/model_registry/deploy_data_drift_tracking.png)
* Comparing(with Model Performances)
![](img/model_registry/deploy_data_drift_comparing.png)
* Analyzing(with Categorical Results, by segmantation)
![](img/model_registry/deploy_data_drift_analyzing.png)

![](img/model_registry/deploy_with_associationid.png)
![](img/model_registry/deployment_importance.png)
![](img/model_registry/deploying_status0.png)
![](img/model_registry/deploying_status1.png)
![](img/model_registry/deploying_finished.png)


#### Monitoring

##### Configure Monitoring Agent

* Sample Codes
  * [Python](codes/monitoring/monitoring.py)
  * [Java](codes/monitoring/monitoring.java)

* Settings
  * main
![](img/monitoring/configure_monitoring_agent.png)
  * Service Health Noti. Cycle
![](img/monitoring/monitoring_setting_service_health_noti_cycle.png)
  * Data Drift Noti. Cycle
![](img/monitoring/monitoring_setting_data_drift_noti_cycle.png)
  * Data Drift Range
![](img/monitoring/monitoring_setting_data_drift_range.png)
  * Accuracy Noti. Cycle
![](img/monitoring/monitoring_setting_accuracy_noti_cycle.png)
  * Accuracy Definition
![](img/monitoring/monitoring_setting_accuracy_def.png)

`datarobot_mlops_package-7.2.1-1074.tar.gz`: 179MB

#### Deployments

##### Inference
![](img/mlops/deployment_inference.png)
![](img/mlops/deployment_data_drift.png)


#### Application

##### Create from Deployment
![](img/application/create_application0.png)
![](img/application/create_application1.png)

##### Create from Gallery

![](img/application/create_application_from_gallery.png)

