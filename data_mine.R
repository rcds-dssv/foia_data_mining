source("main.R")

# get DHS
# dhs_foia <- readRDS("data/DHS_data.rds")
# View(dhs_foia)

parse_and_save_foia(yaml_file = "yaml/DHS.yaml", method = "rds")
parse_and_save_foia(yaml_file = "yaml/DOJ.yaml", method = "rds")
parse_and_save_foia(yaml_file = "yaml/DOL.yaml", method = "rds")
parse_and_save_foia(yaml_file = "yaml/DOS.yaml", method = "rds")
parse_and_save_foia(yaml_file = "yaml/EPA.yaml", method = "rds")
parse_and_save_foia(yaml_file = "yaml/HHS.yaml", method = "rds")
