library(dplyr)
library(ggplot2)
thres <- 6 # missing many
thres <- 4 # still missing a few -- likely bad fits b/c of timing?
thres <- 2.9103 # Fstat of p=.01
d <- glue::glue('txt/ts/btn/1*/PMC_fstat-{thres}.txt') |>
   Sys.glob() |>
   readr::read_delim(delim="\t")

tent <- d |>
  mutate(
   ses=stringr::str_extract(File,'\\d{5}_\\d_\\d{8}'),
   vol=gsub('[^0-9]','',`Sub-brick`)|>as.numeric()) |>
  select(ses,vol,matches('NZ'))  |>
  group_by(ses)|>
  mutate(peak=which.max(NZMean_1)-1)

tent|>
   filter(peak==vol) |>
   write.csv(file=glue::glue('txt/buttonpush-tent_PMC_fstat-{thres}.txt'))

p_tent <- ggplot(tent) + 
   aes(x=vol,y=NZMean_1,
       linewidth=NZcount_1,
       group=ses,
       label=ses,
       color=as.factor(peak)) +
   geom_line(alpha=.4) +
   geom_label(data=tent|>filter(peak!=2,peak==vol),
              alpha=.5) +
   facet_grid(peak==2~.) +
   theme_bw() +
   labs(color="Peak HRF volume",
        y=expression("ROI Mean "~beta[btnpush]),
        x="Volume (1.3s)",
        linewidth="Voxels in ROI",
        title="TENT() HRF for Habit Task Button Push")

p_peak <- tent|>filter(peak==vol) |>
   mutate(sesdate=lubridate::ymd(stringr::str_extract(ses,'\\d{8}')))|>
   ggplot()+
   aes(x=sesdate, y=peak,
       color=NZMean_1) +
   geom_point() + 
   theme_bw() +
   labs(title="Peak HRF volume by session date",
        color=expression("ROI Mean "~beta),
        x="Session Date",
        y="Volume of Peak")
p <- cowplot::plot_grid(p_tent,p_peak, ncol=1, nrow=2, rel_heights=c(3,1))
ggsave(p,
       file=glue::glue("bntpush-motor_thres-{thres}_tents.png"),
       width=9.87,height=10.9)                


