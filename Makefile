.PHONY: all run_diffs_over_date.png
all: clock_drift.png


clock_drift.png: txt/luna/combined_anti_times.csv txt/luna/combined_habit_times.csv
	./model_time.R
	magick $@ -scale 25%  $@


## all epfid2d1 MR acquistions types for P2
txt/mr_times_p2.tsv:
	./affected_from_db.bash > $@

## all eprime tasks
txt/eprime_times.tsv: txt/EPrimeLogs/Phillips-D3-rest/*txt  txt/EPrimeLogs/Phillips-CENTRIM/*.txt txt/EPrimeLogs/Sarpal-MARS-C4_AXCPT/*.txt txt/EPrimeLogs/Clark-AlcPics_2023-2024/*.txt | txt/
	./extract_eprime.pl $^ > $@

## ncanda (mr only)
txt/ncanda/alc_task_mr.tsv: ./mr_time.bash | txt/ncanda/
	./mr_time.bash /disk/mace2/scan_data/WPC-6106/20*/*/ncanda-alcpic*  > $@

## luna anti
txt/luna/combined_anti_times.csv: txt/luna/anti_task_mr.tsv txt/luna/anti_task_display.tsv
	./luna/merge_luna_anti.R

txt/luna/anti_task_display.tsv: | txt/luna/
	./lncdtask_display_time.bash anti > $@

txt/luna/anti_task_mr.tsv: ./mr_time.bash | txt/luna/
	./mr_time.bash anti > $@

## luna habit
txt/combined_habit_times.csv: txt/luna/habit_task_display.tsv txt/luna/habit_task_mr.tsv
	./luna/merge_luna_habit.R
txt/luna/habit_task_mr.tsv: ./mr_time.bash | txt/luna/
	./mr_time.bash habit > $@
txt/luna/habit_task_display.tsv: | txt/luna/
	jq -r '[input_filename, ([.events[]|.rt|select(.!= null)]|length), ."start-time".browser]|@tsv' /Volumes/L/bea_res/Data/Tasks/Habit/MR/1*_2*/*json > $@

## TeenSCREEN
txt/BridgeTeenSceen/tasks.tsv:
	./extract_eprime.pl txt/EPrimeLogs/TeenSCREEN/*txt > $@

txt/BridgeTeenSceen/mr_times.tsv:
	./mr_time.bash /Volumes/argo/Studies/TeenSCREEN/Public/Analysis/raw/complete/*/*func-* > $@ 

##  first pass at times

# also made by merge.R
run_diffs_over_date.png: txt/combined_anti_times.csv plot.R
	./plot.R
	magick ./run_diffs_over_date.png -scale 30%  ./run_diffs_over_date.png


%/:
	mkdir -p $@
