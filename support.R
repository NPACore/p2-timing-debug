
#' @description dicom header yyyymmdd and hh:mm:ss.sssss values to UTC time
#' assumes values are in Eastern time zone
#' see mr_time.bash
#' @param acqdate string date like yyyymmdd from 0008,0022
#' @param acqhms string time like hh:mm:ss.sss from 0008,0032
#' @return POSIXct time object in UTC time zone
#' @examples
#'  mr_to_utc("20180131", "10:30:45.500")
mr_to_utc <- function(acqdate,acqhms) {
   paste(acqdate, acqhms)|>
     lubridate::ymd_hms(tz = "America/New_York") |>
     lubridate::with_tz("UTC")
}

# clock_count/clock_freq + TriggerOffset
epclock_time <- function(cnt, freq, offset) {
    cnt/freq + offset
}

# from richfitz/TRAMPR/blob/master/R/util.R
absolute.min <- function(x)
  if ( all(is.na(x)) && length(x) ) NA else x[which.min(abs(x))]

signed_absmin <- function(x,y)
    apply(cbind(x, y), 1, absolute.min)

#' differences of differences up and down a series
#' @description
#' take the min of the lead and lag differences
#' assuming the outlier will be bad on both sides
#' there are instances where min-ing either side will cause both false postives and negatives
#' use as_dataframe=TRUE to see both lead and lag
#' @examples
#' lead_lag_dod(c(1,1,10,1,1)) # c(0,0,9,0,0)
#' # flats the last 1 as off
#' lead_lag_dod(c(1,1,10,1)) # c(0,0,9,-9)
#' # flags the 1's as off instead of the 10s
#' lead_lag_dod(c(1,10,10,1)) # c(9,0,0,-9)
lead_lag_dod <- function(tdiff, as_dataframe=FALSE) {
   dod_lag <- tdiff - dplyr::lag(tdiff)
   dod_lead <- dplyr::lead(tdiff) - tdiff
   dod <- signed_absmin(dod_lag, dod_lead)
   if(as_dataframe) data.frame(dod_lag, dod_lead, dod) else dod
}

#' @param x vector to diff
#' @return diff vector of same length. first el repeated twice
#' @description  get diff but use lead for first.
#' just repeats first or NA elements
#' @examples
#' diff_lead1(c(1,1,3))     # c(0,0,2)
#' diff_lead1(c(1,0,3))     # c(-1,-1,2)
#' diff_lead1(c(2,1,NA,3,1))# c(-1,-1,NA,-2,-2)
diff_lead1 <- function(x) {
  lg <- x - lag(x)
  ld <- lead(x) - x
  ifelse(is.na(lg),ld,lg)
}
