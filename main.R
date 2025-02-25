library(yaml)
library(tidyverse)
library(XML)
library(xml2)
library(tibble)

ORG_want_function <- function(xml_top_node,
                              xml_parsed,
                              subunit_want) {
  
  this_ORG_x <- xmlValue(
    getNodeSet(xml_top_node,
    "/iepd:FoiaAnnualReport/nc:Organization/nc:OrganizationAbbreviationText"))
  
  # this_year_x <- xmlValue(getNodeSet(xml_top_node,
  #                    "/iepd:FoiaAnnualReport/foia:DocumentFiscalYearDate"))
  
  nodes_ORG_x <- getNodeSet(
    xml_top_node, "/iepd:FoiaAnnualReport/nc:Organization/nc:OrganizationSubUnit")
  
  df_ORG_x <- xmlToDataFrame(nodes = nodes_ORG_x, stringsAsFactors = FALSE)
  
  df_ORG_x$ParentOrganization <- this_ORG_x
  
  # df_ORG_x$FY <- this_year_x
  
  ORG_attrs_x <- xpathSApply(
    xml_parsed, 
    "/iepd:FoiaAnnualReport/nc:Organization/nc:OrganizationSubUnit/@s:id")
  
  df_ORG_x$OrganizationReference <- ORG_attrs_x
  
  df_ORG_want_x <- filter(df_ORG_x, OrganizationAbbreviationText %in% subunit_want)
  
  return(df_ORG_want_x)
}

df_assoc_want_function <- function(ORG_want,
                                   values_addresses,
                                   assoc_addresses, 
                                   assoc_attrs_orgs, 
                                   assoc_attrs_vals,
                                   xml_parsed,
                                   xml_top_node) {
  df_assoc_x = c()
  
  for (i in 1:length(assoc_addresses)){
    node_assoc_sub_x <- getNodeSet(xml_top_node, assoc_addresses[i])
    df_assoc_sub_x <- xmlToDataFrame(nodes = node_assoc_sub_x, stringsAsFactors = FALSE)
    assoc_attrs_val_sub_x <- xpathSApply(xml_parsed, assoc_attrs_vals[i])
    assoc_attrs_org_sub_x <- xpathSApply(xml_parsed, assoc_attrs_orgs[i])
    df_assoc_sub_x[ , 1] <-  assoc_attrs_val_sub_x
    df_assoc_sub_x[ , 2] <- assoc_attrs_org_sub_x
    df_assoc_sub_x$values_address <- values_addresses[i]
    
    df_assoc_x <- bind_rows(df_assoc_x, df_assoc_sub_x)
  }
  
  df_assoc_want_x <- filter(df_assoc_x, OrganizationReference %in%
                              ORG_want$OrganizationReference)
  
  df_assoc_want_x$Section <- str_extract(df_assoc_want_x$values_address, '(?<=:)\\w*$')
  
  return(df_assoc_want_x)
  
}

# section_values_function <- function(ORG_want,
#                                     assoc_want,
#                                     xml_top_node,
#                                     values_address) {
#   section_values_year_x <- data.frame()
#   
#   for (i in 1:nrow(assoc_want)){
#     
#     node_section_subset_x <- getNodeSet(xml_top_node, 
#                                         paste0(values_address,
#                                                "[@s:id ='", 
#                                                assoc_want$ComponentDataReference[i],
#                                                "']"))
#     
#     if (length(node_section_subset_x) > 1) {
#       print(paste0("Too many nodes mapped:\n\tvalues_address: ", values_address,
#                   "\n\tComponentDataReference: ", assoc_want$ComponentDataReference[i]))
#     } else if (length(node_section_subset_x) == 0) {
#       print((paste0("No nodes mapped:\n\tvalues_address: ", values_address,
#                   "\n\tComponentDataReference: ", assoc_want$ComponentDataReference[i])))
#     }
#     
#     extract_section_subunit_subset_x = xmlSApply(node_section_subset_x, 
#                                                  function(x) xmlSApply(x, xmlValue))
#     section_subunit_values_subset_x = data.frame(t(extract_section_subunit_subset_x), 
#                                                  row.names = NULL)
#     
#     section_subunit_values_subset_x$ComponentDataReference <- assoc_want$ComponentDataReference[i]
#     section_subunit_values_subset_x$OrganizationReference <- assoc_want$OrganizationReference[i]
#     
#     section_values_year_x <- bind_rows(section_values_year_x, section_subunit_values_subset_x)
#   }
#   
#   section_values_year_x <- section_values_year_x %>% left_join(ORG_want,
#                                                                by = "OrganizationReference")
#   
#   section_values_year_x <- section_values_year_x %>% left_join(assoc_want,
#                                                                by = "ComponentDataReference") %>% 
#     select(-ends_with(".y"))
#   
#   if ("t.extract_section_subunit_subset_x." %in% colnames(section_values_year_x)) {
#     print(str_glue("If statement applied here: {values_address}"))
#     print(section_values_year_x)
#     section_values_year_x <- select(section_values_year_x, -"t.extract_section_subunit_subset_x.")
#   }
#   
#   return(section_values_year_x)
# }

##### NEW recursive code to extract values from the nodes separately
get_xml_value_recursive <- function(node) {
  if (xmlSize(node) == 1 & all(names(xmlChildren(node)) == "text")){
    return(xmlSApply(node, xmlValue))
  } else if (xmlSize(node) == 0) {
    return(NA)
  } else {
    return(xmlApply(node, get_xml_value_recursive))
  }
}

# helper function to convert extracted xml data to a data frame
check_all_chr <- function(x) {
  tmp <- x %>%
    map_chr(class)
  return(all((tmp == "character") | (tmp == "logical")))
}

# this function converts the node subset output to a data frame
node_subset_to_df <- function(node_subset) {
  node_subset_ <- node_subset[[1]]
  i <- 0
  
  while (!check_all_chr(node_subset_)) {
    # cap the number of iterations list_flatten runs to prevent from being
    # stuch in infinite loop
    if (i > 10) stop("Error in node_subset_to_df: too many iterations for",
                     " flattening the list. Please check the data.")
    
    node_subset_ <- node_subset_ %>% list_flatten()
    i <- i + 1
  }
  
  node_subset_ %>%
    as.data.frame(row.names = NULL)
  
}


# new implementation of section_values_function
section_values_function <- function(ORG_want,
                                    assoc_want,
                                    xml_top_node,
                                    values_address) {
  
  section_values_year_x <- data.frame()
  
  for (i in seq_len(nrow(assoc_want))){
    
    # grab head node according to the data reference ID and extract values recursively
    node_section_subset_x <- getNodeSet(
      xml_top_node,
      str_glue("{values_address}[@s:id ='{assoc_want$ComponentDataReference[i]}']"),
      fun = get_xml_value_recursive)
    
    if (length(node_section_subset_x) > 1) {
      stop(str_glue(
        "Too many nodes mapped:",
        "\tvalues_address: {values_address}",
        "\tComponentDataReference: {assoc_want$ComponentDataReference[i]}",
        .sep = "\n"
      ))
    } else if (length(node_section_subset_x) == 0) {
      warning(str_glue(
        "No nodes mapped:",
        "\tvalues_address: {values_address}",
        "\tComponentDataReference: {assoc_want$ComponentDataReference[i]}\n",
        .sep = "\n"
      ))
      section_subunit_values_subset_x <- data.frame()
    } else {
      section_subunit_values_subset_x <- node_subset_to_df(node_section_subset_x)
    }
    
    # sometimes the head node exists doesn't contain any data, resulting in a
    # data frame with 0 rows. In this case just create a new data frame 
    # with data / organization reference ID
    # Check "Existing node, missing data" section in "unusual_cases.Rmd" file
    if (nrow(section_subunit_values_subset_x) == 0) {
      section_subunit_values_subset_x <- data.frame(
        ComponentDataReference = assoc_want$ComponentDataReference[i],
        OrganizationReference = assoc_want$OrganizationReference[i]
      )
    } else {
      section_subunit_values_subset_x$ComponentDataReference <- assoc_want$ComponentDataReference[i]
      section_subunit_values_subset_x$OrganizationReference <- assoc_want$OrganizationReference[i]
    }
    
    section_values_year_x <- bind_rows(section_values_year_x, section_subunit_values_subset_x)
  }
  
  # if section_values_year_x is empty, create a new data frame with the
  # data / organization reference ID columns
  if (nrow(section_values_year_x) == 0) {
    section_values_year_x <- section_values_year_x %>%
      mutate(
        ComponentDataReference = character(0),
        OrganizationReference = character(0)
      )
  }
  
  # join the data with the organization and association data
  section_values_year_x <- section_values_year_x %>% 
    left_join(ORG_want, by = "OrganizationReference") %>%
    left_join(assoc_want, by = "ComponentDataReference") %>%
    select(-ends_with(".y"))
  
  if ("t.extract_section_subunit_subset_x." %in% colnames(section_values_year_x)) {
    # keep this check just to make sure that all possibility is accounted for
    # based on the original function
    # Check "Existing node, missing data" section in "unusual_cases.Rmd" file
    # for more information
    stop("'t.extract_section_subunit_subset_x.' column exists.",
         " Check comments in the section_values_function2() function.")
  }
  
  return(section_values_year_x)
}


parse_xml <- function(
    file_dir,
    subunit_want_list,
    values_address_list,
    assoc_address_list,
    assoc_attrs_val_list,
    assoc_attrs_org_list) {
  filenames <- dir(path = file_dir)
  
  # Create an empty list to store the data frames for each item in values_address_list
  foia_data <- list()
  
  for (i in filenames) {
    message("\nParsing ", i, "...")
    
    # Import and parse the XML file so we have a workable R format.
    xml_1 <- xmlParse(file.path(file_dir, i))
    
    # Get the top-level node in the XML document we just parsed. This will allow
    # us to more easily locate nodes of interest.
    xml_top <- xmlRoot(xml_1)
    
    df_ORG_want <- ORG_want_function(
      xml_top_node = xml_top,
      xml_parsed = xml_1,
      subunit_want = subunit_want_list
    )
    
    df_assoc_want <- df_assoc_want_function(
      ORG_want = df_ORG_want,
      values_addresses = values_address_list,
      assoc_addresses = assoc_address_list,
      assoc_attrs_orgs = assoc_attrs_org_list,
      assoc_attrs_vals = assoc_attrs_val_list,
      xml_parsed = xml_1,
      xml_top_node = xml_top
    )
    
    # Loop through each item in values_address_list
    for (address in values_address_list) {
      # Filter based on section name.
      df_assoc_want_filter <- filter(df_assoc_want, values_address == address)
      
      section_values_data <-
        section_values_function(
          ORG_want = df_ORG_want,
          assoc_want = df_assoc_want_filter,
          xml_top_node = xml_top,
          values_address = address
        )
      
      # Add filename and FY to section_values_data
      if (nrow(section_values_data) == 0) {
        message(str_glue(" - NOTE: No data found for {address} in {i} for specified components."))
        section_values_data <- bind_rows(
          section_values_data,
          data.frame(filename = i, FY = NA)
        )
      } else {
        section_values_data$filename <- i
        section_values_data$FY <- str_extract(i, '[:digit:]+')
      }
      
      # Create a unique data frame name based on the section.
      section_data_name <- str_extract(address, 'foia:([^/]+)')
      section_data_name <- str_remove(section_data_name, 'foia:')
      
      # If section_data_name already exists in foia_data and the number
      # of columns match, append to it. Before appending, make sure that the order
      # of the column names match. (bind_rows() takes care of that)
      if (section_data_name %in% names(foia_data)) {
        
        foia_data[[section_data_name]] <- foia_data[[section_data_name]] %>%
          bind_rows(section_values_data)  %>%
          relocate(ComponentDataReference, OrganizationReference.x, OrganizationAbbreviationText,
                   OrganizationName, ParentOrganization, values_address, Section, filename, FY,
                   .after = last_col())
        
      } else {
        # If section_data_name doesn't exist, create a new entry in the list
        foia_data[[section_data_name]] <- section_values_data %>%
          relocate(ComponentDataReference, OrganizationReference.x, OrganizationAbbreviationText,
                   OrganizationName, ParentOrganization, values_address, Section, filename, FY,
                   .after = last_col())
      }
    } # To access the data in a section you can use foia_data$SectionName (e.g.,
  }   # foia_data$RequestDisposition) or foia_data[["SectionName"]].
  
  return(foia_data)
}

parse_yaml <- function(yaml_file) {
  yaml_data <- yaml.load_file(yaml_file)
  
  # extract global vectors
  values_address_list <- yaml_data$tables %>% map_chr("values_address")
  assoc_address_list <- yaml_data$tables %>% map_chr("assoc_address")
  assoc_attrs_val_list <- yaml_data$tables %>% map_chr("assoc_attrs_val")
  assoc_attrs_org_list <- yaml_data$tables %>% map_chr("assoc_attrs_org")
  
  # clean yaml data into list
  output_list <- list(
    data_dir = yaml_data$xml_directory,
    components = yaml_data$components,
    output_file = yaml_data$output_file,
    values_address_list = values_address_list,
    assoc_address_list = assoc_address_list,
    assoc_attrs_val_list = assoc_attrs_val_list,
    assoc_attrs_org_list = assoc_attrs_org_list
  )
  
  return(output_list)
}

parse_and_save_foia <- function(yaml_file, method = c("rda", "rds", "none"), output_dir = ".") {
  if (length(method) != 1) {
    message("Using default method: rda")
    method <- "rda"
  } else if (!(method %in% c("rda", "rds", "none"))) {
    stop("Invalid method! method should be one of 'rda', 'rds', or 'none'")
  }
  
  yaml_data <- parse_yaml(yaml_file)
  
  foia_data <- parse_xml(
    file_dir = yaml_data$data_dir,
    subunit_want_list = yaml_data$components,
    values_address_list = yaml_data$values_address_list,
    assoc_address_list = yaml_data$assoc_address_list,
    assoc_attrs_val_list = yaml_data$assoc_attrs_val_list,
    assoc_attrs_org_list = yaml_data$assoc_attrs_org_list
  )
  
  outfile <- yaml_data$output_file
  
  if (method == "rda") {
    if (!str_detect(tolower(outfile), ".rda")) {
      outfile <- str_c(outfile, ".rda")
    }
    save(foia_data, file = file.path(output_dir, outfile))
  } else if (method == "rds") {
    if (!str_detect(tolower(outfile), ".rds")) {
      outfile <- str_c(outfile, ".rds")
    }
    saveRDS(foia_data, file = file.path(output_dir, outfile))
  } else {
    return(foia_data)
  }
}
