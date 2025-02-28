# FOIA Data Analysis

This repository contains R code for processing and extracting data from
Freedom of Information Act (FOIA) documents downloaded from
[foia.gov](https://www.foia.gov/). The content includes various steps
for handling XML parsing, data extraction, manipulation, and
organization to enhance transparency and facilitate access to
information.

## Overview

This code will extract data stored in XML format as provided by the
[Freedom of Information Act (FOIA) website](https://www.foia.gov/). You
can specify your agency (e.g., Dept. of Labor) and the subcomponents of
interest (e.g., Occupational Safety and Health Administration). You can
also specify your relevant FOIA reporting metrics (e.g., Response Time,
Backlog, etc.).

Ultimately, the code will return a list of data frames, where each data
frame is the metric of interest.

![image](https://github.com/patzacher/foia_data_mining/assets/71090911/cc1de111-f2bf-40c2-9302-a52b043d7731)

![image](https://github.com/patzacher/foia_data_mining/assets/71090911/79165eb3-cc2e-43de-9f18-d430e36dd0c0)

## Installation

To use this code, ensure you have the required R packages installed. The
essential packages include:

XML, xml2, tibble, tidyverse, yaml

### Option 1

The project now supports usage of `renv` to install all relevant
package. To install necessary packages using this method, you will need
R Studio. First open the R project environment by clicking on
`foia_data_mining.Rproj`, which should start R Studio. If the method
doesn't work, try opening R Studio separately and open the `.Rproj` file
within R Studio.

Once inside the project, type in R Console.

```{renv::restore()}
```

This will automatically install all packages used for data mining. These
packages will only be relevant inside the project environment, which
will not interfere with global packages.

### Option 2

The packages can be installed in R manually using the
install.packages("package_name") command.

## Usage

**NOTE:** The code has been updated to support a new and more structured
way to extract FOIA data from XML files using
[yaml](https://en.wikipedia.org/wiki/YAML). This eliminates the need to
explicitly define global variables in Rmd notebook and manually run each
code. Furthermore, the updated code, available via `main.R` has fixed
some bugs present in the original notebook with function definitions to
extract nested data more accurately. Detailed instructions are available
in
[`instructions.md`](https://github.com/rcds-dssv/foia_data_mining/blob/main/instructions.md)
file.

### Data

XML Data can be downloaded from [foia.gov](https://www.foia.gov/). The
code points to the folder 'FOIA Sample' but you can change this as
necessary.

### Global Variables

This section defines various global variables essential for data
extraction, such as lists of subunit agencies, addresses of data
locations within the XML file, organization associations, and reference
IDs for different sections.

### Functions

#### ORG_want_function

-   Identifies and filters component agencies of interest within a
    parent organization. The function generates a dataframe containing
    component agencies, their abbreviations, and reference IDs, helping
    filter the data based on the required agencies.

#### df_assoc_want_function

-   Establishes a key for mapping reference IDs of agencies with
    reference IDs of sections. This function generates a complete key
    for a section, filtering to include only desired subunit agencies.

#### section_values_function

-   Extracts data for a section (e.g., Request Disposition). The
    function iterates through a section, extracting values for the
    desired ID-X attributes and appends section and organization IDs to
    the resulting data frame.

### Extract and Save Data

The final part of the code extracts and saves data from XML files in a
designated folder. It systematically processes each file, applying the
previously defined functions to filter and extract data from different
sections for the agency of interest. The extracted data is stored in a
list of data frames (foia_data), allowing easy access to specific
sections and their data.

## Contributing

Contributions to this project are welcome. If you'd like to contribute,
please follow these steps:

Fork the repository.

Create a new branch for your feature.

Make your changes and submit a pull request.
