# Target Data - ERVISS

This folder contains the ground truth information about Covid-19 cases in EU/EEA countries from [ERVISS](https://erviss.org/).

To access the latest data file, consider the [`latest-hospital_admissions.csv`]((https://github.com/european-modelling-hubs/RespiCast-Covid19/blob/main/target-data/ERVISS/latest-hospital_admissions.csv)). Alternatively, historical data files are stored in the folder [`snapshots`](https://github.com/european-modelling-hubs/RespiCast-Covid19/tree/main/target-data/ERVISS/snapshots) and are named `YYYY-MM-DD-hospital_admissions.csv`, with `YYYY-MM-DD` representing the date of the last data update (which occurs every Friday). It's important to note that the latest files not only includes new data points but also the entire available history.

**Note**: To access additional datasets for informing your model, please visit the [Respiratory Viruses Weekly Data](https://github.com/EU-ECDC/Respiratory_viruses_weekly_data/tree/main) repository published by the ECDC.

Each ground truth CSV file contains the following columns:

| column | column type | description |
| -------- | -------- | ------- |
| `target` | string | The forecast target: "hospital admissions" |
| `location` | string | **ISO-2** code identifying the country |
| `truth_date` | date | Date in format **YYYY-MM-DD**: the last day of the truth week (Sunday)|
| `year_week` | string | A string denoting the year and week to which the truth data corresponds |
| `value ` | decimal | Covid-19 hospitalisations


ERVISS covers the following countries: 

    AT, BE, BG, CY, CZ, DE, DK, EE, ES, FI, FR, GR, HU, IE, IS, IT, LI, LT, LU, LV, MT, NL, PL, PT, RO, SE, SI, SK
