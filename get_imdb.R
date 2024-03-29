# Get copies of files
# Files are downloaded from IMDB.
# Files are filtered to include movies & TV series/miniseries only
# 22/06/2022  Fixed a reading error where quote in text were messing things up.

library(tidyr)
library(dplyr)
library(rmutil)

PROJECT_DIR <- "c:/R/two_goats"
DATA_DIR    <- paste0(PROJECT_DIR,"/data")
FILE_DIR    <- paste0(DATA_DIR,"/tsv")

get_title <- function(file){
  local_file <- paste0(FILE_DIR,"/",file,".tsv.gz")
  remote_file <- paste0("https://datasets.imdbws.com/",file,".tsv.gz")
  if (!file.exists(local_file) |
      as.Date(file.info(local_file)$mtime) != Sys.Date()){
    if (!file.exists(local_file)) print(paste("Downloading New File:",remote_file,"to Local file:",local_file)) 
    else print(paste("Updating Remote File:",remote_file,"to Local file:",local_file))
    download.file(remote_file,local_file)
  } else {
    print(paste("File",local_file,"Already Exists"))
  }
}

# Download the files
get_title("name.basics")
get_title("title.basics")
get_title("title.crew")
get_title("title.ratings")
get_title("title.episode")
get_title("title.principals")  
get_title("title.akas")

# Episodes
episode  <- read.delim(paste0(FILE_DIR,"/title.episode.tsv.gz") ,stringsAsFactors = FALSE ,quote="")
save(episode,file=paste0(DATA_DIR,"/episode.RData"))   # Save Crew Data Frame

episodes <- episode %>% 
  group_by(parentTconst) %>%
  select(-tconst) %>%
  summarise(episodes = n()) %>%
  rename(tconst=parentTconst)

basics  <- read.delim(paste0(FILE_DIR,"/title.basics.tsv.gz") ,stringsAsFactors = FALSE ,quote="")

# Set types for columns
basics$isAdult   <- as.numeric(basics$isAdult)
basics$startYear <- as.numeric(basics$startYear)
basics$endYear   <- as.numeric(basics$endYear)
basics$runtimeMinutes <- as.numeric(basics$runtimeMinutes)

# Clean Basics
keeptypes <- c("movie","tvMovie","tvMiniSeries","tvSeries")  # List of types to keep
basics    <- basics %>% filter(titleType %in% keeptypes)  # Only keep selected types

# Impute unknown run time with average of type
basics <- basics %>% mutate(runtimeMinutes= ifelse(is.na(runtimeMinutes), mean(runtimeMinutes, na.rm=TRUE), runtimeMinutes))

basics <- basics[basics$startYear <= as.numeric(substr(Sys.Date(),1,4)),]   # drop release date after this year

# Checking: Time Travellers Wife where are you?
basics %>% filter(tconst=="tt8783930")
basics %>% filter(tconst=="tt0452694")

# Define total run time.  
# Note that the runimeMinutes variable from IMDB is the total for movies or miniseries, 
# but must be multiplied by total number of episodes for a TV series
basics <- basics %>% 
  left_join(episodes,by="tconst") %>% 
  replace_na(list(episodes=1))    %>%  
  mutate(totalRuntime=ifelse(titleType=="tvSeries", episodes*runtimeMinutes,runtimeMinutes))

save(basics,file=paste0(DATA_DIR,"/basics.RData"))

#  Filter and save the results
movies_only <- basics %>% select(tconst)

# Ratings
ratings <- read.delim(paste0(FILE_DIR,"/title.ratings.tsv.gz") ,stringsAsFactors = FALSE ,quote="")
ratings <- ratings %>% inner_join(movies_only,by="tconst")   # Filter on Movies only
save(ratings,file=paste0(DATA_DIR,"/ratings.RData"))

# Names (Can't filter names as they don't have tconst)
names  <- read.delim(paste0(FILE_DIR,"/name.basics.tsv.gz") ,stringsAsFactors = FALSE ,quote="")
head(names)
summary(names)
save(names,file=paste0(DATA_DIR,"/names.RData"))  # Save names data frame

# Principals
principals  <- read.delim(paste0(FILE_DIR,"/title.principals.tsv.gz") ,stringsAsFactors = FALSE ,quote="")
# Clean principals
principals <- principals %>% inner_join(movies_only,by="tconst")  # Filter on Movies only
principals$category <- as.factor(principals$category)
summary(principals$category)
save(principals,file=paste0(DATA_DIR,"/principals.RData"))  # Save Principals data frame

# Crew
crew  <- read.delim(paste0(FILE_DIR,"/title.crew.tsv.gz") ,stringsAsFactors = FALSE ,quote="")
crew  <- crew %>% inner_join(movies_only,by="tconst")  # Filter on Movies only
save(crew,file=paste0(DATA_DIR,"/crew.RData"))   # Save Crew Data Frame

# AKAs
akas  <- read.delim(paste0(FILE_DIR,"/title.akas.tsv.gz") ,stringsAsFactors = FALSE ,quote="")
akas <- akas %>% rename(tconst=titleId)
akas  <- akas %>% inner_join(movies_only,by="tconst")  # Filter on Movies only
save(akas,file=paste0(DATA_DIR,"/akas.RData"))   # Save Crew Data Frame
