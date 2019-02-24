*******************************************************************************;
**************** 80-character banner for column width reference ***************;
* (set window width to banner width to calibrate line length to 80 characters *;
*******************************************************************************;

* 
[Dataset 1 Name] Pokemon_GO_Stats

[Dataset Description] The information contained in this dataset include Pokemon 
Go attributes such as Base Stats, HP, Attach, Stamina, CP, etc.  

[Experimental Unit Description] Individual Pokemon attributes

[Number of Observations]  708

[Number of Features] 9

[Data Source] The file https://docs.google.com/spreadsheets/d/1UoCZzfsMNIhDW2YcR
q9nuzDrDiOvtJ6MeAbN0yvtPOQ/edit#gid=1171406684 was downloaded and edited to 
only contain pertinent columns related to the Pokemon Go mobile game, removed
special characters from the unique key in order to join the other data sources,
and removed spaces from column names.

[Data Dictionary] https://docs.google.com/spreadsheets/d/1UoCZzfsMNIhDW2YcRq9n
uzDrDiOvtJ6MeAbN0yvtPOQ/edit#gid=1171406684

[Unique ID Schema] The column "Dex" is a unique id that can be used to
join to other tables.

;
%let inputDataset1DSN = poke_stat;
%let inputDataset1URL = 
https://github.com/stat697/team-1_project_repo/blob/master/data/Pokemon_GO_Stats.xlsx?raw=true;
%let inputDataset1Type = xlsx;


* 
[Dataset 2 Name] pokemon_stats_detailed

[Dataset Description] The information contained in this dataset include Base 
Stats, Performance against Other Types, Height, Weight, Classification, Egg 
Steps, Experience Points, Abilities, and more.

[Experimental Unit Description] Individual Pokemon attributes and stats

[Number of Observations] 801

[Number of Features] 41

[Data Source] The file was downloaded from 
https://www.kaggle.com/rounakbanik/pokemon

[Data Dictionary] https://www.kaggle.com/rounakbanik/pokemon

[Unique ID Schema] The column "pokedex_number" is a unique id that can be used 
to join to other tables.
;
%let inputDataset2DSN = poke_stat_dtld;
%let inputDataset2URL = 
https://github.com/stat697/team-1_project_repo/blob/master/data/pokemon_stats_detailed.xlsx?raw=true;
%let inputDataset2Type = xlsx;


* 
[Dataset 3 Name] sightings_09_02_2016

[Dataset Description] Subset of the original source of Pokemon sightings on 
September 2, 2016. It contains coordinates, time, weather, population density, 
distance to pokestops/gyms and additional data about appearances.

[Experimental Unit Description] Each appearance of a Pokemon for the specified 
day.

[Number of Observations] 3,735

[Number of Features] 209

[Data Source] The file was downloaded from 
https://www.kaggle.com/semioniy/predictemall . The date of appearance was 
converted from datestamp to mm/dd/yyyy format using Excel substring & date 
functions to create a new column called "appeared_time", while only 
retaining appearances on 9/2/2016.

[Data Dictionary] https://www.kaggle.com/semioniy/predictemall

[Unique ID Schema] The column "_id" is a unique key, but joins to the other
tables using the "pokemonId" column.

;
%let inputDataset3DSN = sight_9_2_16;
%let inputDataset3URL = 
https://github.com/stat697/team-1_project_repo/blob/master/data/sightings_09_02_2016.xlsx?raw=true;
%let inputDataset3Type = xlsx;


* 
[Dataset 4 Name] sightings_09_03_2016

[Dataset Description] Subset of the original source of Pokemon sightings on 
September 3, 2016. It contains coordinates, time, weather, population density, 
distance to pokestops/ gyms and additional data about appearances.

[Experimental Unit Description] Each appearance of a Pokemon for the specified 
day.

[Number of Observations] 26,999

[Number of Features] 209

[Data Source] https://www.kaggle.com/semioniy/predictemall

[Data Dictionary] The file was downloaded from 
https://www.kaggle.com/semioniy/predictemall . The date of appearance was 
converted from datestamp to mm/dd/yyyy format using Excel substring & date 
functions to create a new column called "appeared_time", while only 
retaining appearances on 9/3/2016.

[Unique ID Schema] The column "_id" is a unique key, but joins to the other
tables using the "pokemonId" column.
;
%let inputDataset4DSN = sight_9_3_16;
%let inputDataset4URL = 
https://github.com/stat697/team-1_project_repo/blob/master/data/sightings_09_03_2016.xlsx?raw=true;
%let inputDataset4Type = xlsx;


*
[Dataset 5 Name] combo_sights

[Dataset Description] Combined data observations/rows from sight_9_2_16 & 
sight_9_3_16 into a single data set and also retained only the pertinent columns
needed for analysis

[Experimental Unit Description] Each appearance of a Pokemon for the specified 
day

[Number of Observations] 30,733

[Number of Features] 22

[Data Source] https://www.kaggle.com/semioniy/predictemall

[Data Dictionary] The original files were downloaded from 
https://www.kaggle.com/semioniy/predictemall. This data set was combined from
the sight_9_2_16 & sight_9_3_16 data sets in a Proc SQL Union All step.

[Unique ID Schema] The column "_id" is a unique key, but joins to the other
tables using the "pokemonId" column.
;
%let inputDataset5DSN = combo_sights;
%let inputDataset5URL = 
https://github.com/stat697/team-1_project_repo/blob/v0.3/data/combo_sight-edited.xlsx?raw=true;
%let inputDataset5Type = xlsx;


* set global system options;
options fullstimer;


* load raw datasets over the wire, if they doesn't already exist;
%macro loadDataIfNotAlreadyAvailable(dsn,url,filetype);
    %put &=dsn;
    %put &=url;
    %put &=filetype;
    %if
        %sysfunc(exist(&dsn.)) = 0
    %then
        %do;
            %put Loading dataset &dsn. over the wire now...;
            filename
                tempfile
                "%sysfunc(getoption(work))/tempfile.&filetype."
            ;
            proc http
                method="get"
                url="&url."
                out=tempfile
                ;
            run;
            proc import
                file=tempfile
                out=&dsn.
                dbms=&filetype.;
            run;
            filename tempfile clear;
        %end;
    %else
        %do;
            %put Dataset &dsn. already exists. Please delete and try again.;
        %end;
%mend;
%macro loadDatasets;
    %do i = 1 %to 5;
        %loadDataIfNotAlreadyAvailable(
            &&inputDataset&i.DSN.,
            &&inputDataset&i.URL.,
            &&inputDataset&i.Type.
        )
    %end;
%mend;
%loadDatasets;



* check poke_stat for bad unique id values, where the column dex is intended 
to form a composite key;
proc sql;
    /* check for duplicate unique id values; after executing this query, we
       see that poke_stat_dups only has one row, where dex is missing, which 
       we can mitigate as part of eliminating rows having missing unique id 
       component in the next query */
    create table poke_stat_dups as
        select
            dex
            ,count(*) as row_count_for_unique_id_value
        from
            poke_stat
        group by
            dex
        having
            row_count_for_unique_id_value > 1
    ;

    /* remove rows with missing unique id components, or with unique ids that
       do not correspond to dex; after executing this query, the new
       dataset poke_stat_final will have no duplicate/repeated unique id values,
       and all unique id values will correspond to our experimental units of
       interest; this means the column dex in poke_stat is guaranteed to form a 
       composite key */
    create table poke_stat_final as
        select
            *
        from
            poke_stat
        where
            /* remove rows with missing unique id value components */
            not(missing(dex)) 
        order by
            dex
    ;
quit;


* check sight_9_2_16 and sight_9_3_16 for duplicate unique id values, where the 
column _id is intended to form the primary key;

%macro inspect_sight(var);
   * macro step to check for duplicate unique id values in the sight_9_2_16 and 
   sight_9_3_16 datasets. the output confirms that niether of the datasets have
   duplicate primary keys;
    title "Inspect for missing values in _ID column which is the primary key in 
    &var table";
    proc sql; 
        create table &var._dups as
            select
                _id
                ,count(*) as row_count
            from
                &var
            group by
                _id
            having
                row_count > 1
         ;
    quit;
    title;
%mend;
%inspect_sight(sight_9_2_16);
%inspect_sight(sight_9_3_16);


*create a single data set with sight_9_2_16 and sight_9_3_16 combined since
both tables contain the same columns. This step also removes columns that are 
not being utilized in the analysis for increase efficiency and better system 
performance;

proc sql;
    *the combined dataset contains 30,733 rows which equals the total number of 
     rows from sight_9_2_16 (3,734) and sight_9_3_16 (26,999) when combined. 
     this shows that no rows were lost during the union all process;
    title "Combine only required columns for analysis in select statement to 
    union sight_9_2_16 and sight_9_3_16 tables into a single data source";
    create table combo_sights as
        select 
            _id
            ,pokemonId
            ,latitude	
            ,longitude
            ,appeared_time
            ,appearedTimeOfDay
            ,appearedHour	
            ,appearedMinute
            ,city	
            ,continent	
            ,weather	
            ,temperature	
            ,windSpeed	
            ,windBearing	
            ,pressure	
            ,weatherIcon
            ,population_density	
			,closetowater
            ,urban	
            ,suburban	
            ,midurban	
            ,rural	
            ,gymDistanceKm
        from 
            sight_9_2_16
        union all
        select 
            _id
            ,pokemonId
            ,latitude	
            ,longitude
            ,appeared_time
            ,appearedTimeOfDay
            ,appearedHour	
            ,appearedMinute
            ,city	
            ,continent	
            ,weather	
            ,temperature	
            ,windSpeed	
            ,windBearing	
            ,pressure	
            ,weatherIcon
            ,population_density	
			,closetowater
            ,urban	
            ,suburban	
            ,midurban	
            ,rural	
            ,gymDistanceKm
        from 
            sight_9_3_16
        order by 
            pokemonId
            ,_id
    ;
quit;
title;


* check poke_stat_dtld for bad unique id values, where the column pokedex_number 
is intended to form a composite key;
proc sql;
    /* check for duplicate unique id values; after executing this query, we
       see that poke_stat_dtld_dups only has one row, where dex is missing, 
       which we can mitigate as part of eliminating rows having missing unique 
       id component in the next query */
    create table poke_stat_dtld_dups as
        select
            pokedex_number
            ,count(*) as row_count_for_unique_id_value
        from
            poke_stat_dtld
        group by
            pokedex_number
        having
            row_count_for_unique_id_value > 1
    ;

    /* remove rows with missing unique id components, or with unique ids that
       do not correspond to pokedex_number; after executing this query, the 
       new dataset poke_stat_dtld_final will have no duplicate/repeated unique
       id values and all unique id values will correspond to our experimental 
       units of interest; this means the column pokedex_number in 
       poke_stat_dtld is guaranteed to form a composite key */
    create table poke_stat_dtld_final as
        select
            *
        from
            poke_stat_dtld
        where
            /* remove rows with missing unique id value components */
            not(missing(pokedex_number)) 
        order by 
            pokedex_number
    ;
quit;


* inspect columns of interest in cleaned versions of datasets;
/*
    %macro inspect(var);
        title "Inspect &var in poke_stat_final";
        proc sql;
            select
                min(&var) as min
                ,max(&var) as max
                ,mean(&var) as mean
                ,median(&var) as median
                ,nmiss(&var) as missing
            from
                poke_stat_final
            ;
        quit;
        title;
    %mend;
    %inspect(stamina);
    %inspect(attack);
    %inspect(defense);
    %inspect(maxCP);


    * inspect columns of interest in the cleaned combined sighting data set;
    %macro inspect_comb_sight(var);
        *check for missing values from specific columns used in our analysis. 
         the output confirmed there were no missing values for the specified
         columns;
        title "Inspect for missing values &var in combo_sights";
        proc sql; 
            select
                nmiss(&var) as missing
            from
                combo_sights
            ;
        quit;
        title;
    %mend;
    %inspect_comb_sight(continent);
    %inspect_comb_sight(pokemonid);
    %inspect_comb_sight(city);
    %inspect_comb_sight(urban);
    %inspect_comb_sight(suburban);
    %inspect_comb_sight(midurban);
    %inspect_comb_sight(rural);

    %macro inspect_num_sight_comb(var);
        * check for missing or unusual values from specific columns used in our 
          analysis which contain numeric values. no missing values or unusual 
          values were found after running this step;
        title "Inspect for missing or unusual numeric values in &var in combo_sights";
        proc sql;
            select 
                min(&var) as min
                ,max(&var) as max
                ,mean(&var) as mean
                ,median(&var) as median
                ,nmiss(&var) as missing
            from
                combo_sights
            ;
        quit;
        title;
    %mend;
    %inspect_num_sight_comb(temperature);
    %inspect_num_sight_comb(windspeed);
    %inspect_num_sight_comb(windbearing);
    %inspect_num_sight_comb(pressure);


    * inspect columns of interest in cleaned versions of datasets;
    %macro inspect_dtld(var);
        title "Inspect &var in poke_stat_dtld_final";
        proc sql;
            select
                min(&var) as min
                ,max(&var) as max
                ,mean(&var) as mean
                ,median(&var) as median
                ,nmiss(&var) as missing
            from
                poke_stat_dtld_final
            ;
        quit;
        title;
    %mend;
    %inspect_dtld(base_egg_steps);
    %inspect_dtld(capture_rate);
    %inspect_dtld(experience_growth);
    %inspect_dtld(is_legendary);
    %inspect_dtld(speed);

*/


* combine poke_stat_final, poke_stat_dtld_final and combo_sights horizontally 
  using a data-step match-merge;
* note: After running the data step and proc sort step below several times
  and averaging the fullstimer output in the system log, they tend to take
  about 0.08 seconds of combined "real time" to execute and a maximum of
  about 10.5MB of memory (1450 KB for the data step vs. 10,500 KB for the
  proc sort step) on the computer they were tested on;
/*
    data pokemon_stats_all_v1;
	    retain
	        dex
	        _id
			species
	        type1
	        stamina
	        attack
	        defense
	        maxCP
	        base_egg_steps
	        capture_rate
	        experience_growth
	        is_legendary
	        speed
	        continent
	        city
			closetowater
	        urban
	        suburban
	        midurban
	        rural
			weather
	        temperature
	        windspeed
	        windbearing
	        pressure
	    ;
	    keep
	        dex
	        _id
			species
	        type1
	        stamina
	        attack
	        defense
	        maxCP
	        base_egg_steps
	        capture_rate
	        experience_growth
	        is_legendary
	        speed
	        continent
	        city
			closetowater
	        urban
	        suburban
	        midurban
	        rural
			weather
	        temperature
	        windspeed
	        windbearing
	        pressure
	    ;
	    merge
	        poke_stat_final(in=a)
	        poke_stat_dtld_final(
	            drop  = attack
	                    defense
						type1
	            rename=(
	                pokedex_number = dex
	                )
	            )
	        combo_sights(
	            rename=(
	                pokemonid = dex
	                )
	            )
	    ;
	    by dex
	    ;
	    if a
	    ;
    run;

	proc sort data=pokemon_stats_all_v1 nodupkey;
	    by _id
	    ;
	run;
*/


* combine poke_stat_final, poke_stat_dtld_final and combo_sights horizontally 
  using proc sql;
* note: After running the proc sql step below several times and averaging
  the fullstimer output in the system log, they tend to take about 0.07
  seconds of "real time" to execute and about 13.9MB of memory on the computer
  they were tested on. Consequently, the proc sql step appears to take roughly
  the same amount of time to execute as the combined data step and proc sort
  steps above, but to use roughly five times as much memory;
* note to learners: Based upon these results, the proc sql step is preferable
  if memory performance isn't critical. This is because less code is required,
  so it's faster to write and verify correct output has been obtained;
/*
	proc sql;
	    create table pokemon_stats_all_v2 as
	        select 
		    A.dex
		    ,C._id
			,A.species
		    ,A.type1
		    ,A.stamina
		    ,A.attack
		    ,A.defense
		    ,A.maxCP
		    ,B.base_egg_steps
		    ,B.capture_rate
		    ,B.experience_growth
		    ,B.is_legendary
		    ,B.speed
		    ,C.continent
		    ,C.city
			,C.closetowater
		    ,C.urban
		    ,C.suburban
		    ,C.midurban
		    ,C.rural
			,C.weather
		    ,C.temperature
		    ,C.windspeed
		    ,C.windbearing
		    ,C.pressure
	        from
	            poke_stat_final as A
	            left join
	            poke_stat_dtld_final as B
	            on A.dex=B.pokedex_number
		    left join 
		    combo_sights as C 
	            on A.dex=C.pokemonId
	        order by
	            A.dex
	            ,C._id
	    ;
	quit;
*/
* verify that pokemon_stats_all_v1 and pokemon_stats_all_v2 are identical;
/*
    proc compare
	    base=pokemon_stats_all_v1
	    compare=pokemon_stats_all_v2
	    novalues
	    ;
	run;
*/

* combine poke_stat_final, poke_stat_dtld_final and combo_sights horizontally 
  using proc sql and in-line views;
* note: After running the proc sql step below several times and averaging
  the fullstimer output in the system log, they tend to take about 0.06
  seconds of "real time" to execute and about 5.8MB of memory on the computer
  they were tested on. Consequently, the proc sql with in-line views step 
  appears to take roughly the same amount of time to execute as the previous
  steps above, but uses ~2-3x less memory;
proc sql;
    create table poke_analytic_file as
        select
            C._id as sighting_id
			,C.pokemonID
            ,C.continent
            ,C.city
            ,C.closetowater
            ,C.urban
            ,C.suburban
            ,C.midurban
            ,C.rural
            ,C.weather
            ,C.temperature
            ,C.windspeed
            ,C.windbearing
            ,C.pressure
			,A.*
			,B.*
        from 
            combo_sights as C
        left join 
            (select 
                dex
                ,species
                ,type1
                ,stamina
                ,attack
                ,defense
                ,maxCP
            from poke_stat_final) as A
            on A.dex = C.pokemonID
        left join
            (select
                 pokedex_number
                 ,base_egg_steps
                 ,capture_rate
                 ,experience_growth
                 ,is_legendary
                 ,speed
             from poke_stat_dtld_final) as B
             on B.pokedex_number = C.pokemonID
    ;
quit;

proc sort data=poke_analytic_file nodupkey;
    by sighting_id;
run;

* verify that pokemon_stats_all_v1 and poke_analytic_file are identical;
/*
proc compare
	base=pokemon_stats_all_v1
	compare=poke_analytic_file
	novalues
	;
run;
*/
