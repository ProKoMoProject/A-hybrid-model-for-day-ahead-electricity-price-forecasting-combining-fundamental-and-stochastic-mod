parameter

price(year_focus,month,day,hour,n)
;

price(year_focus,month,day,hour,n)               = sum(daily_window, price_roll(year_focus,month,day,hour,n,daily_window)     );



EXECUTE_UNLOAD '%output_dir%%result%.gdx'    price
               , modelstats, solvestats

;


$onecho >out.tmp

         par=price                         rng=price!A1:AJ9999    rdim=4 cdim=1

         par=modelstats                    rng=stats!A2:B9900     rdim=1 cdim=0
         par=solvestats                    rng=stats!D2:E9900     rdim=1 cdim=0

$offecho

execute "XLSTALK -c    %output_dir%%result%.xlsx" ;

EXECUTE 'gdxxrw %output_dir%%result%.gdx o=%output_dir%%result%.xlsx EpsOut=0 @out.tmp'
;
