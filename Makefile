txt/combined_mr_task_times.csv: txt/anti_task_mr.tsv txt/anti_task_display.tsv
	./merge.R

txt/anti_task_display.tsv:
	./display_time.bash

txt/anti_task_mr.tsv:
	./mr_time.bash

# also made by merge.R
run_diffs_over_date.png: txt/combined_mr_task_times.csv plot.R
	./plot.R
	magick ./run_diffs_over_date.png -scale 30%  ./run_diffs_over_date.png
