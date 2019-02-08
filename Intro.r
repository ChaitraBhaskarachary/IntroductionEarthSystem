#R script to convert netCDF Climate dataset to Quicklook
## 1. Reading a netCDF data set using the ncdf4 package
#### The `ndcf4` package is used to read, write and analyze netCDF files.The `netCDF` package is available in both windows and MAC OS X and Linux and supports both older NetCDF3 format as well as netCDF4. To begin, load the ncdf4 package
```{r}

library(ncdf4)
```
#### `fn` is the path where the file is located and cru10min30_tmp.nc is the file name. 
#### `name` is the name of the variable that will be read in 

## 2. Open the netCDF file

```{r}
#Set path and filename
fn <- "F:\\IntroductionEarthData\\data_samples\\netCDF\\cru10min30_tmp.nc"
name <- "tmp"    # tmp means temperature 

```
####Open the NetCDF dataset and print basic information. The `print()` function applied to `nc`object provides information about the dataset
```{r}
#open a netCDF file
nc<- nc_open(fn)
print(nc)
```
## 2.1. Get Coordinate including time variables
####`ncvr_get()` function is used to read the coordinate variables `longitude` and `latitude`. `head()` and `tail()` functions are used to list first few values and the number of variables can be verified using `dim()` function: 
```{r}
##get longitude and latitude
lon <- ncvar_get(nc,"lon")
nlon <- dim(lon)
head(lon)
```
```{r}
lat <- ncvar_get(nc,"lat")
nlat <- dim(lat)
head(lat)
```
```{r}
print(c(nlon,nlat))
```
####Time variable and its attributes are derived by `ncvar_get()` and `ncatt_get()` functions and the dimensions of the time is obtained using `dim()` function
```{r}
##get time
time <- ncvar_get(nc,"time")
time
```
```{r}
tunits <- ncatt_get(nc,"time","units")
nt <- dim(time)
nt
```
####Print the time units string. It can be noticed that the structure of the object tunits has two components hasatt (a logical variable), and tunits$value, the actual "time since" string.
```{r}
tunits
```
##2.2. Get a variable 

####Get a variable `tmp` and its attribute and verify the size of the array
```{r}
#get temperature

tmp_array <- ncvar_get(nc,name)
dlname <- ncatt_get(nc,name,"long_name")
dunits <- ncatt_get(nc,name,"units")
fillvalue <- ncatt_get(nc,name,"_FillValue")
dim(tmp_array)
```
####Get the global attributes 
```{r}
#get global attributes
title <- ncatt_get(nc,0,"title")
institution <- ncatt_get(nc,0,"institution")
datasource <- ncatt_get(nc,0,"source")
references <- ncatt_get(nc,0,"references")
history <- ncatt_get(nc,0,"history")
Conventions <- ncatt_get(nc,0,"Conventions")
```
### Close the netCDF file
####Check the current workspace:
```{r}
ls()
``` 

##3. Reshaping from raster to rectangular 
####NetCDF files or data sets are naturally raster slabs (e.g. a longitude by latitude "slice"), bricks(longitude by latitude by time), or 4-d arrays(longitude by latitude by height by time) while most data analysis routines in R expect 2-d variable-by-observation data frames. In addition, time is usually stored as the CF (Climate Forecast) "time since" format that is not usually human-readable. 

####Install and Load the below packages 
```{r}
#load some packages
library(chron)
library(lattice)
library(RColorBrewer)
```
##3.1.Convert the time variable 

####The time variable in "time-since" units is converted into readable form. `Chron()` function is used to determine the absolute value of each time value from time origin. 
```{r}
# convert time -- split the time units string into fields
tustr <- strsplit(tunits$value, " ")
tdstr <- strsplit(unlist(tustr)[3], "-")
tmonth <- as.integer(unlist(tdstr)[2])
tday <- as.integer(unlist(tdstr)[3])
tyear <- as.integer(unlist(tdstr)[1])
chron(time,origin=c(tmonth, tday, tyear))
```
##3.2. Replace netCDF fillvalues with R NAs
####The missing values are flagged using specific `(_FillValues)`or `(missing_value) in netCDF files. The missing values are treated by replacing unavailable data using `NA` value. 
```{r}
# replace netCDF fill values with NA's
tmp_array[tmp_array==fillvalue$value] <- NA
```
```{r}
length(na.omit(as.vector(tmp_array[,,1])))
```
##3.3. Get a single time slice of data
####NetCDF variables are read and written as one-dimensional vectors (e.g. longitudes), two-dimensional arrays or matrices (raster "slices"), or multi-dimensional arrays (raster "bricks"). In such data structures, the coordinate values for each grid point are implicit, inferred from the marginal values of, for example, longitude, latitude and time. In contrast, in R, the principal data structure for a variable is the data frame. In the kinds of data sets usually stored as netCDF files, each row in the data frame will contain the data for an individual grid point, with each column representing a particular variable, including explicit values for longitude and latitude (and perhaps time). In the example CRU data set considered here, the variables would consist of longitude, latitude and 12 columns of long-term means for each month, with the full data set thus consisting of 259200 rows (720 by 360) and 14 columns.

####This particular structure of this data set can be illustrated by selecting a single slice from the temperature "brick", turning it into a data frame with three variables and 720 by 360 rows,
```{r}
# get a single slice or layer (January)
m <- 1
tmp_slice <- tmp_array[,,m]
```
####The dimensions of `tmp_slice`, e.g. 720, 360, can be verified using the `dim()` function.

##4. Visualization
####A quick look (map) of the extracted slice of data can be obtained using the `image()` function.The `expand.grid()` function is used to create a set of 720 by 360 pairs of latitude and longitude values (with latitudes varying most rapidly), one for each element in the `tmp_slice` array. Specific values of the cutpoints of temperature categories are defined to cover the range of temperature values
```{r}
# quick map
grid <- expand.grid(lon=lon, lat=lat)
cutpts <- c(-50,-40,-30,-20,-10,0,10,20,30,40,50)
levelplot(tmp_slice ~ lon * lat, data=grid, at=cutpts, cuts=11, pretty=T, 
col.regions=(rev(brewer.pal(10,"RdBu"))))

```

#### Quicklook of slice of data with different month, red color indicates the variation of increase in the temperature and Blue color indicates the winter period. Consider for example during the month `June` we can notice that most part of the world is experiencing an increase in the temperature
```{r}
# June Month
m <- 6
tmp_slice <- tmp_array[,,m]
```
```{r}
# quick map
grid <- expand.grid(lon=lon, lat=lat)
cutpts <- c(-50,-40,-30,-20,-10,0,10,20,30,40,50)
levelplot(tmp_slice ~ lon * lat, data=grid, at=cutpts, cuts=11, pretty=T, 
  col.regions=(rev(brewer.pal(10,"RdBu"))))