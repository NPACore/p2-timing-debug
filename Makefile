.PHONY: all run_diffs_over_date.png
all: clock_drift.png

txt/combined_mr_task_times.csv: txt/anti_task_mr.tsv txt/anti_task_display.tsv
	./merge.R

txt/anti_task_display.tsv:
	./display_time.bash

txt/anti_task_mr.tsv:
	./mr_time.bash anti > $@

txt/habit_task_mr.tsv:
	./mr_time.bash habit > $@

txt/habit_task_display.tsv:
	jq -r '[input_filename, ([.events[]|.rt|select(.!= null)]|length), ."start-time".browser]|@tsv' /Volumes/L/bea_res/Data/Tasks/Habit/MR/1*_2*/*json > $@

# also made by merge.R
run_diffs_over_date.png: txt/combined_mr_task_times.csv plot.R
	./plot.R
	magick ./run_diffs_over_date.png -scale 30%  ./run_diffs_over_date.png

txt/combined_habit_times.csv: txt/habit_task_display.tsv txt/habit_task_mr.tsv
	./habit.R

clock_drift.png: txt/combined_mr_task_times.csv txt/combined_habit_times.csv
	./model_time.R
	magick $@ -scale 25%  $@
