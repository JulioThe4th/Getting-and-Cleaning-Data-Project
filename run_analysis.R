# run_analysis.R

# Set the working directory to the location of the Samsung data
setwd("path/to/your/dataset")  # Replace with the actual path

# Getting and Cleaning Data Project John Hopkins Coursera

# Load necessary packages
requiredPackages <- c("data.table", "reshape2")
sapply(requiredPackages, require, character.only=TRUE, quietly=TRUE)

# Define the path and download the dataset
currentPath <- getwd()
datasetURL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(datasetURL, file.path(currentPath, "dataset.zip"))
unzip(zipfile = "dataset.zip", exdir = currentPath)

# Load activity labels and features
activityDescriptions <- fread(file.path(currentPath, "UCI HAR Dataset/activity_labels.txt"),
                              col.names = c("activityID", "activityLabel"))
featureList <- fread(file.path(currentPath, "UCI HAR Dataset/features.txt"),
                     col.names = c("featureIndex", "featureName"))

# Extract only the measurements on the mean and standard deviation
desiredFeatures <- grep("(mean|std)\\(\\)", featureList[, featureName])
selectedMeasurements <- featureList[desiredFeatures, featureName]
selectedMeasurements <- gsub('[()]', '', selectedMeasurements)

# Load and preprocess training data
trainingData <- fread(file.path(currentPath, "UCI HAR Dataset/train/X_train.txt"))[, desiredFeatures, with = FALSE]
setnames(trainingData, colnames(trainingData), selectedMeasurements)
trainingActivities <- fread(file.path(currentPath, "UCI HAR Dataset/train/Y_train.txt"),
                            col.names = c("ActivityID"))
trainingSubjects <- fread(file.path(currentPath, "UCI HAR Dataset/train/subject_train.txt"),
                          col.names = c("SubjectID"))
trainingDataset <- cbind(trainingSubjects, trainingActivities, trainingData)

# Load and preprocess test data
testingData <- fread(file.path(currentPath, "UCI HAR Dataset/test/X_test.txt"))[, desiredFeatures, with = FALSE]
setnames(testingData, colnames(testingData), selectedMeasurements)
testingActivities <- fread(file.path(currentPath, "UCI HAR Dataset/test/Y_test.txt"),
                           col.names = c("ActivityID"))
testingSubjects <- fread(file.path(currentPath, "UCI HAR Dataset/test/subject_test.txt"),
                         col.names = c("SubjectID"))
testingDataset <- cbind(testingSubjects, testingActivities, testingData)

# Merge the training and the test sets to create one data set
mergedDataset <- rbind(trainingDataset, testingDataset)

# Convert activity IDs to descriptive activity names
mergedDataset[["ActivityID"]] <- factor(mergedDataset[, ActivityID],
                                        levels = activityDescriptions[["activityID"]],
                                        labels = activityDescriptions[["activityLabel"]])

# Convert SubjectID to factor
mergedDataset[["SubjectID"]] <- as.factor(mergedDataset[, SubjectID])

# Melt and cast the data to get the average of each variable for each activity and each subject
reshapedDataset <- melt(data = mergedDataset, id = c("SubjectID", "ActivityID"))
tidyDataset <- dcast(data = reshapedDataset, SubjectID + ActivityID ~ variable, fun.aggregate = mean)

# Write the tidy data set to a text file
fwrite(x = tidyDataset, file = "tidyData.txt", quote = FALSE)
