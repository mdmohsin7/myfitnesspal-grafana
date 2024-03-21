# myfitnesspal-grafana
This Project is based on Flutter. User will be able to generate Grafana Dashboard using CSV file generated from MyFitnessPal Android App.

Note: Sample data file has been uploaded to data Folder. This file has been downloaded from some website providing user an sample csv file for MyFitnessPal Android App.

## Problem Statement
Language: Any

Must work in: Linux (anything server side)

MyFitnessPal is a mobile app used to track food & energy intake, exercise, and more. It supports CSV data export (e.g. through email) to facilitate archival, but this style is a bit antiquated for manual viewing.

A simple website that accepts CSV exports and renders nice visual representations using Grafana would be much better for users. This should be feasible to complete in a few days since all of the major components already exist.

## Solution
This Application take CSV file as an input -> Send data to backend as JSON -> Sanitize the data -> insert data into a table in PostgreSQL -> Grafana Dashboard is generated based on the data of table.

You can test the live demo by visiting here: https://myfitnesspal-grafana-4a7e.globeapp.dev/ (uploading would result in CORS error, so please try locally)

Or you can run it locally as well

## How to Setup the Application Locally
- Clone the repository
- In fitnessgrafanashell/main.dart file, replace the environment variables with actual values of your Postgres instance
- Open fitnessgrafanaui directory in a terminal and run `flutter pub get && flutter run`
- Open fitnnessgrafanashelf directory in another terminal and run `dart pub get && dart run lib/main.dart`
- In fitnessgrafanaui/lib/main.dart, replace `http://myfitnesspal-grafana.globeapp.dev/uploadCsvData` with `http://localhost:8080/uploadCsvData` (your local backend instance)
- Change the instances of Grafana snapshot URLs with yours in fitnessgrafanaui