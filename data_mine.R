source("main.R")

# get DHS
parse_and_save_foia(yaml_file = "yaml/DHS.yaml", method = "rds")
# dhs_foia <- readRDS("data/DHS_data.rds")
# View(dhs_foia)
