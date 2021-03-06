
EnsurePackage <- function(x) {
  x <- as.character(x)
  
  if(!require(x,character.only = T)){
    install.packages(pkgs = x,repos = "http://cran.r-project.org")
    require(x,character.only = T)}
  
}
EnsurePackage("data.table")
EnsurePackage("ggplot2")
EnsurePackage("ff")
EnsurePackage("magrittr")
EnsurePackage("reshape2")
EnsurePackage("dplyr")
EnsurePackage("gdata")
EnsurePackage("ggmap") 
EnsurePackage("zipcode") 
EnsurePackage("zipcode")
EnsurePackage("openintro")
EnsurePackage("stringr")

HyattSet <- fread("out-201403.csv")
str(HyattSet)

HyattSetR <- HyattSet[!(HyattSet$NPS_Type == ""), ] 
str(HyattSetR)
write.csv(HyattSetR,file = "Hyatt-032014-Refined.csv")



#Merging the files
HyattMarch <- read.csv("Hyatt-032014-Refined.csv")
HyattJuly <- read.csv("Hyatt-072014-Refined.csv")
HyattDec <- read.csv("Hyatt-122014-Refined.csv")

Hyattmjd <- merge(HyattMarch,HyattJuly,all=TRUE)
Hyattmjd <- merge(Hyattmjd,HyattDec,all=TRUE)
write.csv(Hyattmjd,"hyattmjd1.csv")  


HyattSet <- Hyattmjd


CountryRespondents <- aggregate(data = HyattSet,cbind(count = Country_PL)~Country_PL,FUN = function(x) {NROW(x)})
CountryRespondents$Country_PL <- gsub("United States","USA",CountryRespondents$Country_PL)





HyattSet$State_PL <- tolower(HyattSet$State_PL)
StateRespondents <- aggregate(data = HyattSet,cbind(count = State_PL)~State_PL,FUN = function(x) {NROW(x)})
StateRevenue <-aggregate(data = HyattSet,cbind(REVENUE_R,Net_Rev_H,Gross_Rev_H,Room_Rev_H)~State_PL,FUN = function(x) {sum(x)})

StateRespondents <- StateRespondents[-1,]
#Removing all canadian states
StateRespondents<- StateRespondents[!(StateRespondents$State_PL%in%c("alberta","british columbia","ontario","quebec")),]

StateRespondents$Stateabb<- state2abbr(StateRespondents$State_PL)

# Creating a mapplot

# Creating world map and finding the number of respondents
EnsurePackage("rworldmap")
WorldData <- map_data(map="world")
WorldData <- WorldData[!WorldData$region == "Antarctica",]
p <- ggplot() + 
  geom_map(data=WorldData, map=WorldData,
           aes(x=long, y=lat, group=group, map_id=region),
           fill="white", colour="black")

p<- p+ geom_map(data = CountryRespondents, map=WorldData,
                aes(fill=count, map_id=Country_PL),
                colour="Red", size=0.5)

p <- p + coord_map("rectangular", lat0=0, xlim=c(-180,180), ylim=c(-90, 90))
p <- p + scale_fill_continuous(breaks = c(seq(from = 0, to = 150000, by = 30000)), low = "white", high = "red")
p <- p + scale_y_continuous(breaks=c())
p <- p + scale_x_continuous(breaks=c())
p <- p + labs(fill="Respondents", title="Number of Respondents", x="", y="")
p 

#USA has highest respondents so lets drill down to the map of USA

US <- map_data("state")
US$abb <- state2abbr(US$region)
Text <-aggregate(data = US,cbind(long,lat)~abb,FUN = function(x) {mean(x)})

usmap <- ggplot() + 
  geom_map(data = US, map = US, aes(x = long, y = lat,map_id =region ),fill = "black",colour ="white" )

usmap <- usmap + geom_map(data = StateRespondents, map = US,aes(fill = count,map_id = State_PL ),color = "blue")
usmap <- usmap + scale_fill_continuous(breaks = c(seq(from = 0, to = 40000, by = 5000)), low = "white", high = "red")
usmap <- usmap + geom_text(data = Text ,aes(x = long, y = lat, label = abb),check_overlap = TRUE,size=1) 
usmap<- usmap + geom_label(data = Text,aes(x = long, y = lat,label =abb))
usmap <- usmap + theme(text = element_text(size = 10)) + labs(title= "Respondents across states",fill = "Respondent Count")
usmap

#Find which state gives highest revenue
US <- map_data("state")
US$abb <- state2abbr(US$region)
Text <-aggregate(data = US,cbind(long,lat)~abb,FUN = function(x) {mean(x)})

usrevmap <- ggplot() + 
  geom_map(data = US, map = US, aes(x = long, y = lat,map_id =region ),fill = "black",colour ="white" )

usrevmap <- usrevmap + geom_map(data = StateRevenue, map = US,aes(fill = Net_Rev_H,map_id = State_PL ),color = "blue")
usrevmap <- usrevmap + scale_fill_continuous(breaks = c(seq(from = 0, to = 1000000000, by = 200000000)), low = "white", high = "red")
usrevmap <- usrevmap + geom_text(data = Text ,aes(x = long, y = lat, label = abb,check_overlap = TRUE)) 
usrevmap<- usrevmap + geom_label(data = Text,aes(x = long, y = lat,label =abb))
usrevmap <- usrevmap + theme(text = element_text(size = 10)) + labs(title= "Statewise Revenue",fill = "Revenue in 100 Million")
usrevmap

#Calculate NPS score
HyattSet<- read.csv("hyattmjd1.csv")
StateNPS <- aggregate(data = HyattSetUSA,cbind(count=(NPS_Type))~NPS_Type+State_PL,FUN = function(x) {sum(str_count(x))})

StateNPSmelt <- melt(StateNPS,id=c("State_PL","NPS_Type"),measured = c("count"))
StateNPSCast <- dcast(StateNPSmelt, State_PL ~ NPS_Type,value=variable)

StateNPSCast$Total <- StateNPSCast$Promoter + StateNPSCast$Detractor + StateNPSCast$Passive
StateNPSCast$NPSScore <- (StateNPSCast$Promoter - StateNPSCast$Detractor)/StateNPSCast$Total*100

StateNPSCast$State_PL <- tolower(StateNPSCast$State_PL)

NPSScoremap <- ggplot() + 
  geom_map(data = US, map = US, aes(x = long, y = lat,map_id =region ),fill = "black",colour ="white" )
NPSScoremap <- NPSScoremap + geom_map(data = StateNPSCast, map = US,aes(map_id = State_PL,fill=NPSScore ))
NPSScoremap <- NPSScoremap + labs(title= "NPS Scores Statewise",fill = "NPS Scores") + xlim(-123, -65.0) + ylim(25, 50)
NPSScoremap <- NPSScoremap + scale_fill_continuous(breaks = c(seq(from = 0, to = 100, by = 10)), low = "white", high = "red")
NPSScoremap <- NPSScoremap + geom_text(data = Text ,aes(x = long, y = lat, label = abb,check_overlap = TRUE))
NPSScoremap

#Number of hotels in each state
HyattSet$Property.Latitude_PL <- as.numeric(levels(HyattSet$Property.Latitude_PL))[HyattSet$Property.Latitude_PL]
HyattSet$Property.Longitude_PL <- as.numeric(levels(HyattSet$Property.Longitude_PL))[HyattSet$Property.Longitude_PL]
write.csv(HyattSet,"hyattmjd1.csv") 

ushotels <- aggregate(data = HyattSet[HyattSet$Country_PL == "United States",],cbind(Property.Longitude_PL,Property.Latitude_PL)~Hotel.Name.Long_PL+State_PL,FUN = mean)

ushotelmap <- ggplot() + 
  geom_map(data = US, map = US, aes(x = long, y = lat,map_id =region ),fill = "black",colour ="white" )
ushotelmap <- ushotelmap + geom_map(data = US, map = US,aes(map_id = region ),color = "blue")
ushotelmap <- ushotelmap + geom_point(data = ushotels ,aes(x = Property.Longitude_PL, y = Property.Latitude_PL,colour = "white")) 
ushotelmap <- ushotelmap + labs(title= "Number of hotels",fill = "") + xlim(-123, -65.0) + ylim(25, 50)
ushotelmap <- ushotelmap + geom_text(data = aggregate(ushotels,count = NHotels~Property.Longitude_PL+Property.Latitude_PL+Hotel.Name.Long_PL+State_PL,FUN = sum),aes(x = Property.Longitude_PL, y = Property.Latitude_PL, label = count,check_overlap = TRUE))
ushotelmap

#Map and dates of each state
HyattSet <- HyattSet[,-2]
HyattSetUSA <- HyattSet[HyattSet$Country_PL == "United States",]

EnsurePackage("dplyr")

HyattSet$ARRIVAL_DATE_R <- as.Date(as.character(HyattSet$ARRIVAL_DATE_R),format = "%m/%d/%Y")
  
HyattSet %>%
  filter(HyattSet$Country_PL == "United States") %>%
  group_by(State_PL,ARRIVAL_DATE_R) %>%
  summarise(n = n()) %>%
  mutate(state = tolower(State_PL)) %>%
  ggplot()+
  geom_line(aes(x = ARRIVAL_DATE_R, y = n))+
  facet_wrap(~state, ncol = 7, scales= "free_y")+
  theme_bw()

#From this we find florida california texas newyork and illinois have good footfalls. 
#Lets analyse them further
EnsurePackage("scales")
HyattSet %>%
  filter(HyattSet$Country_PL == "United States", HyattSet$State_PL%in%c("California","New York","Texas","Illinois","Florida")) %>%
  group_by(State_PL,ARRIVAL_DATE_R) %>%
  summarise(n = n()) %>%
  mutate(state = tolower(State_PL)) %>%
  ggplot()+
  geom_line(aes(x = ARRIVAL_DATE_R, y = n))+
  facet_wrap(~state, ncol = 1, scales= "free_y")+
  scale_x_date(date_breaks = "1 month",label=date_format("%m"))+
  theme_bw()





#Detractors and a barplot of how much they rated
HyattSetDetractors <- subset(HyattSet,NPS_Type =="Detractor")
Ratingsubset <- setNames(aggregate(data=HyattSet,cbind(HyattSet$Likelihood_Recommend_H,HyattSet$Overall_Sat_H,
                HyattSet$Guest_Room_H,HyattSet$Tranquility_H,HyattSet$Condition_Hotel_H,
                HyattSet$Customer_SVC_H,HyattSet$Staff_Cared_H,HyattSet$Internet_Sat_H,
                HyattSet$F.B_Overall_Experience_H,HyattSet$Check_In_H)~NPS_Type,na.rm = T,FUN = mean
                ),c("NPS_Type","Likelihood_Recommend","Overall_Sat_H",
                    "Guest_Room_H","Tranquility_H","Condition_Hotel_H",
                    "Customer_SVC_H","Staff_Cared_H","Internet_Sat_H","F.B_Overall_Experience","Check_In_H"))

RatingsMelted <- melt(Ratingsubset,measured=c("NPS_Type","Likelihood_Recommend","Overall_Sat_H",
                                              "Guest_Room_H","Tranquility_H","Condition_Hotel_H",
                                              "Customer_SVC_H","Staff_Cared_H","Internet_Sat_H","F.B_Overall_Experience","Check_In_H"))


barplott <- ggplot(data = RatingsMelted,aes(x= variable,y=value))
barplott <- barplott + geom_bar(stat="identity") + coord_flip()
barplott <- barplott + facet_grid(.~NPS_Type)+geom_hline(yintercept = 7,colour="green")
barplott

#check detractors brandwise
# "Brand_PL" "NPS TYPE"
EnsurePackage("doBy")
EnsurePackage(("stringr"))
EnsurePackage("qdapRegex")

#number of promoters brandwise
HyattSet <- HyattSet1
HyattSet$Brand_PL <- as.character(HyattSet$Brand_PL)

BrandSet <- setNames(aggregate(data=HyattSet,
                               cbind(HyattSet$Likelihood_Recommend_H,HyattSet$Overall_Sat_H,
                               HyattSet$Guest_Room_H,HyattSet$Tranquility_H,HyattSet$Condition_Hotel_H,
                              HyattSet$Customer_SVC_H,HyattSet$Staff_Cared_H,HyattSet$Internet_Sat_H,
                               HyattSet$F.B_Overall_Experience_H,HyattSet$Check_In_H)~NPS_Type+Brand_PL,na.rm = T,
                              FUN = mean),c("NPS_Type","Brand_PL","Likelihood_Recommend","Overall_Sat_H",
                              "Guest_Room_H","Tranquility_H","Condition_Hotel_H",
                              "Customer_SVC_H","Staff_Cared_H","Internet_Sat_H",
                              "F.B_Overall_Experience","Check_In_H"))

trimws()
HyattSet$Brand_PL <- as.character(HyattSet$Brand_PL)
NumofRespondentsBrand <- aggregate(data=HyattSet,(cbind(count = Brand_PL))~NPS_Type + Brand_PL,FUN = function(x){sum(str_count(rm_white(x)," ")+1)})
NumofRespondentsBrand <- NumofRespondentsBrand[-1,]

Brandlook <- merge(NumofRespondentsBrand,BrandSet,by =c("Brand_PL","NPS_Type") )
Brandmelt <- melt(Brandlook,measured=c("Likelihood_Recommend","Overall_Sat_H",
                                          "Guest_Room_H","Tranquility_H","Condition_Hotel_H",
                                          "Customer_SVC_H","Staff_Cared_H","Internet_Sat_H","F.B_Overall_Experience","Check_In_H"),id=c("count","Brand_PL","NPS_Type"))

scatterplottBrandwise <- ggplot(data = Brandmelt,aes(x=variable,y=value,colour=NPS_Type,size=count))
scatterplottBrandwise <- scatterplottBrandwise + geom_point() + coord_flip()
scatterplottBrandwise <- scatterplottBrandwise + facet_wrap(~Brand_PL, ncol = 3, scales= "free_y")
scatterplottBrandwise <- scatterplottBrandwise + scale_y_continuous("Ratings",limits=c(1,10))
scatterplottBrandwise <- scatterplottBrandwise + labs(size = "Number of respondents")
scatterplottBrandwise

#Ratings based on Location
LocationSet <- setNames(aggregate(data=HyattSet,
                               cbind(HyattSet$Likelihood_Recommend_H,HyattSet$Overall_Sat_H,
                                     HyattSet$Guest_Room_H,HyattSet$Tranquility_H,HyattSet$Condition_Hotel_H,
                                     HyattSet$Customer_SVC_H,HyattSet$Staff_Cared_H,HyattSet$Internet_Sat_H,
                                     HyattSet$F.B_Overall_Experience_H,HyattSet$Check_In_H)~NPS_Type+Location_PL,na.rm = T,
                               FUN = mean),c("NPS_Type","Location_PL","Likelihood_Recommend","Overall_Sat_H",
                                             "Guest_Room_H","Tranquility_H","Condition_Hotel_H",
                                             "Customer_SVC_H","Staff_Cared_H","Internet_Sat_H",
                                             "F.B_Overall_Experience","Check_In_H"))


Locationmelt <- melt(LocationSet,measured=c("Likelihood_Recommend","Overall_Sat_H",
                                       "Guest_Room_H","Tranquility_H","Condition_Hotel_H",
                                       "Customer_SVC_H","Staff_Cared_H","Internet_Sat_H","F.B_Overall_Experience","Check_In_H"),id=c("Location_PL","NPS_Type"))

scatterplotLocationwise <- ggplot(data = Locationmelt,aes(x=variable,y=value,colour=NPS_Type))
scatterplotLocationwise <- scatterplotLocationwise + geom_point() + coord_flip()
scatterplotLocationwise <- scatterplotLocationwise + facet_wrap(~Location_PL, ncol = 2, scales= "free_x")
scatterplotLocationwise

#Ratio of promoters and detractors
Npslocation <- data.frame("NPS_Type" = HyattSet$NPS_Type,"Location_PL" = HyattSet$Location_PL)
Npslocation <- Npslocation[Npslocation$Location_PL != "",]
Npslocationagg <- aggregate(data = Npslocation,cbind(count=NPS_Type)~Location_PL+NPS_Type,FUN = function(x){sum(str_count(x))})
Npslocreshape <- recast(Npslocation, NPS_Type ~ Location_PL, id.var = c("NPS_Type", "Location_PL"))

Npslocreshape[4,2:5] <- colSums(Npslocreshape[,2:5])
Npslocreshape$NPS_Type <- as.character(Npslocreshape$NPS_Type)
Npslocreshape[4,1] <- "Total"
str(Npslocreshape)
Npslocreshape$Airport <- Npslocreshape$Airport/Npslocreshape[4,2]
Npslocreshape$Resort <- Npslocreshape$Resort/Npslocreshape[4,3]
Npslocreshape$Suburban <- Npslocreshape$Suburban/Npslocreshape[4,5]
Npslocreshape$Urban <- Npslocreshape$Urban/Npslocreshape[4,5]

Npslocreshapemelt <- melt(Npslocreshape,id = "NPS_Type")
Npslocreshapemelt <- Npslocreshapemelt[Npslocreshapemelt$NPS_Type != "Total",]

barplotLocation <-  ggplot(Npslocreshapemelt, aes(x = variable,y=value)) + 
  geom_bar(aes(fill = NPS_Type), position = "fill",stat = "identity")+
  labs(x="Location",y="Ratio") 
barplotLocation
  
#Calculate Correlation
EnsurePackage("corrplot")
EnsurePackage("Hmisc")

Hyattnumeric <- fread("hyaatnumeric.csv", select = c(4:9,24:34))
Hyattrcorrp <- rcorr(as.matrix(Hyattnumeric))
Hyattcorrp <- cor(Hyattnumeric,use = "complete.obs",method="pearson")


#############################################################################
# Association Mining
#############################################################################
#Cleaning Data and concentrating on California
HyattSet <- read.csv2(file="hyattmjd1.csv", header=TRUE, sep = ",")
HyattSet1 <- data.frame()

HyattSet1  <- subset(HyattSet , HyattSet$State_PL == "California")
write.csv(HyattSet1,"hyatt-california.csv")    

HyattSet <- data.frame(lapply(HyattSet, trimws), stringsAsFactors = FALSE)


HyattSet2 <- data.frame()
HyattSet2 <- as.data.frame(lapply(HyattSet1,function(x) str_trim(x)))
is.na(HyattSet2) <- HyattSet2==''


write.csv(HyattSet2,"hyatt-california-clean.csv")

EnsurePackage("arules")
EnsurePackage("arulesViz")
EnsurePackage("grid")
EnsurePackage("rulesViz")
EnsurePackage("visNetwork")
EnsurePackage("igraph")


#Use california data
HyattCali <- read.csv("hyatt-california.csv")
HyattCaliAs <- HyattCali
HyattCaliAs$Likelihood_Recommend_H <- cut(HyattCaliAs$Likelihood_Recommend_H, breaks=c(-Inf,6,8,10,Inf),
                                 labels=c("low","med","high",right=F))

for (i in 129:138)
{HyattCaliAs[,i] <- cut(HyattCaliAs[,i],breaks=c(-Inf,6,8,10,Inf),
                        labels=c("low","med","high",right=F))}



str(HyattCaliAs)

HyattCaliAs <- select_if(HyattCaliAs, is.factor)

#Clean frequently repeating data

HyattCaliAsSmall <- HyattCaliAs[,-c(1:10,12:34,37:82,94:130,161:163)]

#Hyatt rule for promoter
HyattrulesetPromo <- apriori(HyattCaliAsSmall, parameter=list(support=0.01, confidence=0.6),appearance=list(default="lhs",rhs=("NPS_Type=Promoter")))


inspect(tail(HyattrulesetPromo,6))
inspect(head(Hyattruleset,6))

#Plotting best rules
Hyattgoodrules <- HyattrulesetPromo[quality(HyattrulesetPromo)$lift>1] #Picking rules with lift greater than 2

sortgoodruleslift <- sort(Hyattgoodrules, by="lift", decreasing=TRUE)

sortgoodrulesconf <- sort(Hyattgoodrules, by="confidence", decreasing=TRUE)

sortedgoodrulessupp<- sort(Hyattgoodrules, by="support", decreasing=TRUE)




inspect(head(sortgoodrulesconf,10))
inspect(tail(sortgoodrulesconf,10))

plot(head(sortgoodrulesconf,10), method="graph", control=list(type="items"))

inspect(head(sortgoodruleslift,10))
inpect(tail(sortgoodruleslift,10))

plot(head(sortgoodruleslift,10), method="graph", control=list(type="items"))


inspect(head(sortedgoodrulessupp,10))
inspect(tail(sortedgoodrulessupp,10))

plot(head(sortedgoodrulessupp,10), method="graph", control=list(type="items"))



#Hyatt rule for detractor
HyattrulesetDetractor <- apriori(HyattCaliAsSmall, parameter=list(support=0.01, confidence=0.6),appearance=list(default="lhs",rhs=("NPS_Type=Detractor")))

inspect(tail(HyattrulesetDetractor,6))
inspect(head(HyattrulesetDetractor,6))

HyattgoodrulesDetract <- HyattrulesetDetractor[quality(HyattrulesetDetractor)$lift>2] #Picking rules with lift greater than 2

sortgoodrulesliftDetract <- sort(HyattgoodrulesDetract, by="lift", decreasing=TRUE)

sortgoodrulesconfDetract <- sort(HyattgoodrulesDetract, by="confidence", decreasing=TRUE)

inspect(head(HyattgoodrulesDetract,10))
inspect(tail(HyattgoodrulesDetract,10))

inspect(head(sortgoodrulesliftDetract,10))
inspect(tail(sortgoodrulesliftDetract,10))
plot(head(sortgoodrulesliftDetract,10), method="graph", control=list(type="items"))

inspect(head(sortgoodrulesconfDetract,10))
inspect(tail(sortgoodrulesconfDetract,10))
plot(head(sortgoodrulesconfDetract,10), method="graph", control=list(type="items"))


#SVM Analysis
EnsurePackage("kernlab")
EnsurePackage("e1071")

