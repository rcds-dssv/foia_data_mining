# FOIA Data Extraction Instructions

## Setup

It is recommended that this method is run inside [R Studio project
environment](https://support.posit.co/hc/en-us/articles/200526207-Using-RStudio-Projects),
which requires installation of R Studio. To open the project, click on
`foia_data_mining.Rproj` file, which should start R Studio. If the
method doesn't work, try opening R Studio separately and open the
`.Rproj` file within R Studio.

Once the project is open, you should see "foia_data_mining" in the top
right corner of the R Studio window. The project utilizes `renv` to
record all packages used in the project environment, and streamlines the
process of installing necessary packages for other users. Run
`renv::restore()` in the R Console to install all necessary packages for
data mining. This will only install packages relevant to the project
environment, and will not interfere with global packages.

## Usage Instructions

### Setup

#### XML Files

You should already have a directory with XML files downloaded from
[foia.gov](https://www.foia.gov/). The file names should be in the
format `{agency}_fy{year}.xml` (e.g. DHS data for FY 2019 would be named
`DHS_fy19.xml`). A directly should contain XML files for one specific
agency across different years. For example, a `DHS/` directory may
contain `DHS_fy13.xml`, `DHS_fy14.xml`, ..., `DHS_fy19.xml`,
`DHS_fy20.xml`, etc.

#### YAML File

The `YAML` file contains configuration for the data extraction process.
The file is structured in a `key: value` format.

The `YAML` file should contain the following keys:

| Key | Explanation |
|---------------------------------|---------------------------------------|
| `xml_directory` | Path to directory with XML files |
| `output_file` | Name of the file that the final output is saved to |
| `components` | A list of sub-agencies of interest, abbreviated |
| `tables` | List of `key: value` pairs that defines data to be extracted. More detail below |

The `tables` key contains a list of dictionaries. Each dictionary should
contain the following keys:

| Key | Explanation |
|-------------------|-----------------------------------------------------|
| `values_address` | XPath to node containing data for specific component (as indicated by `s:id` attribute) within a section |
| `assoc_address` | XPath to node containing mapping from data ID to component ID. Usually under the same section as `values_address` |
| `assoc_attrs_val` | XPath that evaluates to extracting the data ID for corresponding `assoc_address` |
| `assoc_attrs_org` | XPath that evaluates to extracting the component ID for corresponding `assoc_address` |

Example of a yaml file for extracting DHS looks like (truncated):

``` yaml
xml_directory: "../FOIAdashboard/DHS_xmls"
output_file: "data/DHS_data"
components: ["CBP", "PRIV", "USCIS", "ICE", "OIG", "CRCL"]
tables:
- values_address: "/iepd:FoiaAnnualReport/foia:RequestDispositionSection/foia:RequestDisposition"
  assoc_address: "/iepd:FoiaAnnualReport/foia:RequestDispositionSection/foia:RequestDispositionOrganizationAssociation"
  assoc_attrs_val: "/iepd:FoiaAnnualReport/foia:RequestDispositionSection/foia:RequestDispositionOrganizationAssociation/foia:ComponentDataReference/@s:ref"
  assoc_attrs_org: "/iepd:FoiaAnnualReport/foia:RequestDispositionSection/foia:RequestDispositionOrganizationAssociation/nc:OrganizationReference/@s:ref"
  
- values_address: "/iepd:FoiaAnnualReport/foia:ProcessedRequestSection/foia:ProcessingStatistics"
  assoc_address: "/iepd:FoiaAnnualReport/foia:ProcessedRequestSection/foia:ProcessingStatisticsOrganizationAssociation"
  assoc_attrs_val: "/iepd:FoiaAnnualReport/foia:ProcessedRequestSection/foia:ProcessingStatisticsOrganizationAssociation/foia:ComponentDataReference/@s:ref"
  assoc_attrs_org: "/iepd:FoiaAnnualReport/foia:ProcessedRequestSection/foia:ProcessingStatisticsOrganizationAssociation/nc:OrganizationReference/@s:ref"

- values_address: "/iepd:FoiaAnnualReport/foia:ProcessedAppealSection/foia:ProcessingStatistics"
  assoc_address: "/iepd:FoiaAnnualReport/foia:ProcessedAppealSection/foia:ProcessingStatisticsOrganizationAssociation"
  assoc_attrs_val: "/iepd:FoiaAnnualReport/foia:ProcessedAppealSection/foia:ProcessingStatisticsOrganizationAssociation/foia:ComponentDataReference/@s:ref"
  assoc_attrs_org: "/iepd:FoiaAnnualReport/foia:ProcessedAppealSection/foia:ProcessingStatisticsOrganizationAssociation/nc:OrganizationReference/@s:ref"

- values_address: "/iepd:FoiaAnnualReport/foia:AppealDispositionSection/foia:AppealDisposition"
  assoc_address: "/iepd:FoiaAnnualReport/foia:AppealDispositionSection/foia:AppealDispositionOrganizationAssociation"
  assoc_attrs_val: "/iepd:FoiaAnnualReport/foia:AppealDispositionSection/foia:AppealDispositionOrganizationAssociation/foia:ComponentDataReference/@s:ref"
  assoc_attrs_org: "/iepd:FoiaAnnualReport/foia:AppealDispositionSection/foia:AppealDispositionOrganizationAssociation/nc:OrganizationReference/@s:ref"
```

Feel free to use this as a template to extend the list of tables as
desired.

It is **highly recommended** that you explore the XML file for an agency
and understand the relationship between these keys and the XML data.

### Running Code

If you have the XML data and YAML file set up, you're ready to run the
code for extraction. If you are running in the project environment, all
the paths are relatively to the location of `foia_data_mining.Rproj`,
unless you manually changed the working directory via `setwd()`.

Sample code to run the extraction process is available in `data_mine.R`
file.

All you would need to do is `source()` the `main.R` script, which
contains the function definitions, and run `parse_and_save_foia()`
function with the path to the YAML file as an argument.

Example:

``` r
source("main.R")

# get DHS
parse_and_save_foia(yaml_file = "yaml/DHS.yaml", method = "rds")
```

The `parse_and_save_foia()` function takes an additional argument,
`method`, which can be one of `"rda"`, `"rds"`, or `"none"`. By default
it is set to `rda`, but saving the data as `rds` is preferred as this
allows calling the data to a preferred variable name.
