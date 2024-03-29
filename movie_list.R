# Read the IMDB data and derive a list of movies based on books

# This version uses the Crew data set.
# Disadvantage is that writers can be identified, but it
# returns a list of all writes (script writers, book writers)
# and has no way to identify those movies based on a book
# Need to split crew table when there are multiple writers listed 
# Tried splitting methods from this page:
# https://stackoverflow.com/questions/13773770/split-comma-separated-strings-in-a-column-into-separate-rows
# Turns out: it takes time.
# I tried the best method listed there (the jaap_DT2 method) but couldn't get it to work easily,
# so reverted to the str_split method

# For a possible update, could change the movie title details to include each different movie title
# including the primary title, the original title, and all the AKA titles.

library(dplyr)
library(rmutil)
library(tidyr)

PROJECT_DIR <- "c:/R/two_goats"
DATA_DIR    <- paste0(PROJECT_DIR,"/data")

# Read the data
load(file=paste0(DATA_DIR,"/crew.RData"))
load(file=paste0(DATA_DIR,"/basics.RData"))
load(file=paste0(DATA_DIR,"/names.RData"))
load(file=paste0(DATA_DIR,"/ratings.RData"))

# Checking: Lightyear where are you?
crew       %>% filter(tconst=="tt10298810")
basics     %>% filter(tconst=="tt10298810")
names      %>% filter(nconst=="tt10298810")
ratings    %>% filter(tconst=="tt10298810")

# Checking: Time Travellers Wife where are you?
crew       %>% filter(tconst=="tt8783930")
basics     %>% filter(tconst=="tt8783930")
names      %>% filter(nconst=="tt8783930")
ratings    %>% filter(tconst=="tt8783930")

# Identify writers of a movie
head(crew)

# Writer IDs
writers <- crew %>% 
  filter(writers != "\\N") %>% 
  select(-directors) 

# This method is very slow but it works.
writers <- writers %>%
  separate_rows(writers)  %>%
  rename(nconst=writers)

head(writers)
# Checking
#writers     %>% filter(tconst=="tt0304141")
#writers     %>% filter(tconst=="tt0120855")

save(writers,file=paste0(DATA_DIR,"/writers.RData"))

# Combined movie data
movie_list <- writers %>% 
  left_join(basics %>% select(tconst,primaryTitle,originalTitle,titleType,startYear,episodes,totalRuntime),by="tconst") %>%
  left_join(names %>% select(nconst,primaryName),by="nconst") %>% 
  rename(writer    = primaryName,
         movieYear = startYear) %>%
  left_join(ratings,by="tconst") %>% 
  rename(movie_rating=averageRating,movie_votes=numVotes) %>%
  filter(movie_votes >= 100)

head(movie_list)

save(movie_list,file=paste0(DATA_DIR,"/movie_list.RData"))

# Checking.  What happened to Harry Potter?
#crew       %>% filter(tconst=="tt0304141")
#basics     %>% filter(tconst=="tt0304141")
#writers    %>% filter(tconst=="tt0304141")
#movie_list %>% filter(tconst=="tt0304141")
#movie_list    %>% filter(tconst=="tt0120855") # Disney Tarzan
