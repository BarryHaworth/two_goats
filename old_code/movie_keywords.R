# Movies Tagged as Based on a book
# Rip IMDB to find tags
# All movies with 100+ votes

library(dplyr)
library(rmutil)
library(tidyr)
library(rvest)

PROJECT_DIR <- "c:/R/two_goats"
DATA_DIR    <- paste0(PROJECT_DIR,"/data")

# Read the data
load(file=paste0(DATA_DIR,"/movie_list.RData"))

movies <- movie_list %>% 
  filter(movie_votes> 500) %>%
#  filter(movie_votes> 100) %>%
  select("tconst","movie_votes","primaryTitle") %>%
  arrange(-movie_votes) %>%
  unique()

# Rip the keywords page - test
tconst <- movies$tconst[1]
tconst <- "tt0120855"  # Disney Tarzan
#tconst <- "tt0304141"  # Harry Potter
url <- paste0('https://www.imdb.com/title/',tconst,'/keywords')
webpage <- read_html(url)
tag_html <- html_nodes(webpage,'.sodatext')
tags <- trimws(gsub('[\n]', '', html_text(tag_html)))
keywords <- data.frame("tconst"=tconst,"keywords"=tags)
tags[grep("based on",tags)]
length(grep("based on",tags))

# create a keywords dataframe
movie_keys <- function(id){
  url <- paste0('https://www.imdb.com/title/',id,'/keywords')
  webpage <- read_html(url)
  tag_html <- html_nodes(webpage,'.sodatext')
  tags <- trimws(gsub('[\n]', '', html_text(tag_html)))
  if (length(tags)==0) tags="No Keywords"
  keywords <- data.frame("tconst"=id,"keywords"=tags)
  return(keywords)
}

# If the saved Movie keywords data exists, read it.
if (file.exists(paste0(DATA_DIR,"/movie_keywords.RData"))) {
  load(paste0(DATA_DIR,"/movie_keywords.RData"))
}
  
# If the local file does not exist, initialise it
if (!exists("movie_keywords")) {
  movie_keywords <- keywords(movies_10K$tconst[1])  # Initialise the keywords data frame
}

based_on_book <- c("based on novel","based on book","based on play","based on short story",
                   "based on young adult novel","based on children's book","based on a novel",
                   "based on novella","based on bestseller","based on book series")
based_on_comic <-c("based on comic book","based on comic","based on graphic novel","based on manga")


# Get the list of IDs looked up

looked_up <- movie_keywords$tconst %>% unique()
movies_notyet <- movies %>% filter(!(tconst %in% looked_up))

while(nrow(movies_notyet)>0){
  looked_up <- movie_keywords$tconst %>% unique()
  movies_notyet <- movies %>% filter(!(tconst %in% looked_up))
  print(paste("Movies Looked up:",length(looked_up),"Remaining:",nrow((movies_notyet))))
  for (i in 1:min(100,nrow(movies_notyet))){
    tryCatch({
      print(paste(i,"Movie",movies_notyet$tconst[i]
                  ,movies_notyet$primaryTitle[i]))
      keys <- movie_keys(movies_notyet$tconst[i])
      if (nrow(keys %>% filter(keywords %in% based_on_book))>0) {
        print("                  - Based on a Book")
      } else
        if (nrow(keys %>% filter(keywords %in% based_on_comic))>0)  {
          print("                  - Based on a Comic")
        }
      movie_keywords <- bind_rows(movie_keywords,keys)
    }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
  }
  print("Saving Keywords Data Frame")
  save(movie_keywords,file=paste0(DATA_DIR,"/movie_keywords.RData"))
}
