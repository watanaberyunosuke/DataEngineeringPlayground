###############################################################
################## Setting up the Workspace ###################
###############################################################

## Start off from a workspace in the Azure cloud platform (say loony-db-rg)
## Create a new Azure Databricks Premium workspace in the US East 2 region (say, loony-db-workspace)
## Launch the workspace once it is ready

## In the Databricks workspace click on the drop down and show the 3 environments
## Select each environment and show the main workspace of the environment

## In the Databricks workspace, head to Compute
## Create a new cluster called loony-cluster
## The cluster has the following config
####	- mode => Single Node
####	- Node Type => Standard_DS3_v2 (14G mem, 4 cores)
## Create the cluster

## Head to Menu --> Data -> and show only the Database Tables tab is visible (no DBFS)
## Within the Database Tables tab show that there are no tables

## Go to Menu --> Settings --> Admin Console --> Workspace Settings
## Enable the DBFS file browser and reload the page
## Upload a CSV File to DBFS
## Head to Menu --> Data -> DBFS
## Upload the file menu_data.csv (included in the course materials) into a datasets folder
## Note that the path to the file will be something like /FileStore/datasets/menu_data.csv
## We will reference this path when be build tables from this file




###############################################################
##################### Creating a Notebook #####################
###############################################################


## Head over to the Menu --> Create --> Notebook
## Specify the notebook name, language, and cluster
## For the first notebook, the details are:
####  - Name: CreatingAndAccessingDeltaTablesUsingApacheSpark
####  - Language: Python
####  - Cluster: loony_cluster

### Refer to the notebook CreatingAndAccessingDeltaTablesUsingApacheSpark included in the course materials
###         for the commands to run





-----------------------------------------------------------------------------------







###############################################################
############### Introduction to Databricks SQL ################
###############################################################


## In the Databricks UI, head to Menu
## Click on the drop-down menu which points to Data Science and Engineering
## Select SQL from this drop-down to head over to Databricks SQL
## This is where we can focus on data analysis via SQL queries

## Pull up the menu on the left and observe that the options are different from what we had
##      in the Data Science and Engineering perspective
## Head to SQL Warehouses (previously SQL Endpoints)
## Click on the Starter Warehouse (previously Starter Endpoint)

## Click on the 3 tables Overview, Connection details, Monitoring

## Back on Overview

## In the config page for the Starter Warehouse, click on Edit in the top-right
## Change the name to Loony Warehouse
## Set the cluster size to 2X-Small
## Expand the Advanced options and click on the drop-down for Spot Instance Policy
## Make no changes and hit Save 
## Click Start to provision the warehouse

## The warehouse is in fact a cluster of VMs created on your cloud platform


## Click on Menu -> SQL Warehouse and wait for the warehouse to be provisioned

## Go to Menu -> Data
## Select the "default" database and show that menu_nutrition_data table is present there

## Select the table and show details
## Select Schema, Sample Data, Details, Permissions, History


## Head to Menu --> SQL Editor

## Ensure that the Loony Warehouse is the one which is selected
## Observe the Schema browser on the left which allows us to navigate to databases and tables

## Run a query on the same Delta Table


SELECT Category, Item, Serving_Size, Sugars, Protein
FROM menu_nutrition_data
WHERE Protein > 20
  AND Sugars < 10
ORDER BY Protein DESC


## Click on +Add Visualization

# Create a bar chart (click on the drop down and show the other options)

# X column: Category
# Y column: Protein
# Aggregation: Average (show the drop down for other aggregations available)

# Name the visualization "Average Protein by Category"

# Save it and show

