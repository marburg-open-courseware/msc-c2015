# Read observational data on biodiversity of all EPs and combine into dataframe

library(vegan)


# Set path ---------------------------------------------------------------------
if(Sys.info()["sysname"] == "Windows"){
  filepath_base <- "F:/analysis/moc_rs/"
} else {
  filepath_base <- "/media/tnauss/myWork/analysis/moc_rs/"
}

path_biodiv <- paste0(filepath_base, "data/biodiv/")
path_results <- paste0(filepath_base, "data/rdata/")
path_temp <- paste0(filepath_base, "data/temp/")


# Read and adjust vegetation observations --------------------------------------
# Header data vegetation releves 2014
df_veg_2014 <- read.table(
  paste0(path_biodiv, "19807_header data vegetation relev�s 2014_1.1.7/19807.txt"),
  header = TRUE, sep = "\t", dec = ".")
df_veg_2014$epid <- as.character(df_veg_2014$EpPlotID)
df_veg_2014$epid[nchar(df_veg_2014$epid) == 4] <- paste0(
  substr(df_veg_2014$epid[nchar(df_veg_2014$epid) == 4], 1, 3), "0", 
  substr(df_veg_2014$epid[nchar(df_veg_2014$epid) == 4], 4, 4))


# Header data vegetation releves 2015
df_veg_2015 <- read.table(
  paste0(path_biodiv, "19809_header data vegetation relev�s 2015_1.1.5/19809.txt"),
  header = TRUE, sep = "\t", dec = ".")
df_veg_2015$epid <- as.character(df_veg_2015$EpPlotID)
df_veg_2015$epid[nchar(df_veg_2015$epid) == 4] <- paste0(
  substr(df_veg_2015$epid[nchar(df_veg_2015$epid) == 4], 1, 3), "0", 
  substr(df_veg_2015$epid[nchar(df_veg_2015$epid) == 4], 4, 4))


# Vegetation releves 2008 to 2015
df_veg_0815 <- read.table(paste0(path_biodiv, "19686_vegetation relev�s EP 2008-2015_1.2.5/19686.txt"),
                     header = TRUE, sep = "\t", dec = ".")
df_veg_0815$epid <- as.character(df_veg_0815$EP_PlotId)
df_veg_0815$epid[nchar(df_veg_0815$epid) == 4] <- paste0(
  substr(df_veg_0815$epid[nchar(df_veg_0815$epid) == 4], 1, 3), "0", 
  substr(df_veg_0815$epid[nchar(df_veg_0815$epid) == 4], 4, 4))
df_veg_0815$Year <- substr(df_veg_0815$Year, 5, 8)

df_veg_0815_div <- lapply(unique(df_veg_0815$Year), function(y){
  act <- df_veg_0815[df_veg_0815$Year == y,]
  act$cover_bin <- act$cover
  act$cover_bin[act$cover > 0.0 & !is.na(act$cover)] <- 1
  specrich <- aggregate(act$cover_bin, by = list(act$epid), FUN = "sum")
  names(specrich) <- c("epid", "specrich")
  specrich$Year <- as.numeric(y)

  shannon <- lapply(unique(df_veg_0815$epid), function(p){
    act <- df_veg_0815[df_veg_0815$Year == y & df_veg_0815$epid == p, ]
    shannon <- diversity(act$cover)
    shannon <- data.frame(epid = as.character(act$epid[1]),
                          shannon = shannon,
                          Year = as.numeric(y))
    return(shannon)
  })
  shannon <- do.call("rbind", shannon)
  
  comb <- merge(specrich, shannon, by = c("epid", "Year"))
  comb$eveness <- comb$shannon/log(comb$specrich)
  return(comb)
  
})
df_veg_0815_div <- do.call("rbind", df_veg_0815_div)
df_veg_0815_div$epid <- as.factor(df_veg_0815_div$epid)


# Merge vegetation observations ------------------------------------------------
veg_2014 <- merge(df_veg_0815_div[df_veg_0815_div$Year == 2014, ],
                  df_veg_2014, by = "epid")

veg_2015 <- merge(df_veg_0815_div[df_veg_0815_div$Year == 2015, ],
                  df_veg_2015, by = "epid")

veg_2014$year <- 2014
veg_2014$cover_cumulative_all_vascular_plants <- NULL

veg_2015$year <- 2015

veg_2014_2015 <- rbind(veg_2014, veg_2015)

# Write vegetation observations ------------------------------------------------
save(df_veg_0815_div, df_veg_2014, df_veg_2015, veg_2014, veg_2015, veg_2014_2015, 
     file = paste0(path_results, "be_veg_releves.RData"))



