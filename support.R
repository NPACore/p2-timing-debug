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
