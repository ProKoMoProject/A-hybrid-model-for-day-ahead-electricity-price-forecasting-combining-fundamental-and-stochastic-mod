set

    year   all years  /y2010*y2021/
    year_focus(year)  the year which is on the current focus    /y%YearonFocus%/

    month  months of a year                /m1*m12/
    day    days of a year                  /d1*d31/
    hour   hours of a day                  /h0*h23/
    bs     secondary control power blocks
    bp     primary control power blocks

    i       set of technologies

*subsets for technologies
    nuclear(i)  nuclear clusters
    lignite(i)  lignite clusters
    coal(i)     hard coal clusters
    gas(i)      gas technologies
    oil(i)      oil technologies
    Biomass(i)  Biomass technology

    Hydro(i)    hydro power plants
    Thermal(i)  thermal power plants
    ResT(i)     RES technologies
    ReservoirCluster(i)
    StorageCluster(i)


    n   nodes

* mapping
    map_YMDHbbT(year,month,day,hour,bs,bp,t) mapping time steps to years monthes days hour
    map_YMDHT(year,month,day,hour,t) mapping time steps to years monthes days hour
    map_YMDT(year,month,day,t)        mapping time steps t to years and months and days
    map_YMT(year,month,t)       mapping time steps t to years and months
    map_YDT(year,day,t)         mapping time steps t to years and days
    map_YT(year,t)              mapping time steps t to years
    map_MT(month,t)            mapping time steps t to months
    Day_T(day,t)                mapping time steps t to days
    hour_T(hour,t)              mapping time steps t to hours

    map_bst(bs,t)                  mapping time steps t to secondary control power blocks
    map_bpt(bp,t)                  mapping time steps t to primary control power blocks

*    map_YMDH(year,month,day,hour) mapping year month days hour

    tfirst(t)  first hour of the model horizon
    tlast(t)   last hour of the model horizon

;

alias (n,nn), (t,tt)    ;

tfirst(t) = yes$(ord(t) eq 1);
tlast(t)  = yes$(ord(t) eq card(t));


*##############################   stochastic elements   ###############################
sets
    sd  stochstic demand set /sd1*sd3/
;
parameters
prob(sd)
;

prob('sd1') = 1/6 ;
prob('sd2') = 2/3 ;
prob('sd3') = 1/6 ;


*##############################   Parameters   ##############################

Parameters

*technology parameters
    cap_up(n,i,year,month)         installed capacity [MW]
    cap(i,n,t)
    cap_lig(n,t)                capacity of all lignite clusters
    cap_coal(n,t)               capacity of all hard coal clusters
    cap_gas(n,t)                capacity of all gas clusters
    cap_oil(n,t)                capacity of all oil clusters

    g_min(i)                    minimum capacity
    eta_fl(i,n)                 power plant efficiency at full load
    eta_ml(i,n)                 power plant efficiency at minimum load
    carbon_content(i)           CO2 emission per MWh_th [ton_CO2 per MWh_th]
    outages_up                  outage_upload
    outages(i,n,t)              outages of power plant technologies
    af_tech_general(i,n)        constant availability of power plants
    af_tech_t(i,n,t)            hourly availability based on af_tech_general
    af_overall(i,n,t)           final overal availability factor
    downtime(i)                 minimum downtime [hours]


*cost parameters
    fc(i,n,year,month,day)         fuel costs [EUR per MWh_th]
    vOM_cost(i)                    variable O&M costs [EUR per MWh_el]
    co2_price(year,month,day)      CO2 price [EUR per ton_CO2]
    co2_price_UK(year,month,day)   CO2 price [EUR per ton_CO2] in the UK due to a price floor
    vc_fl(i,n,t)       variable costs at full load [EUR per MWh]
    vc_ml(i,n,t)       variable costs at min load [EUR per MWh]

*start-up parameters
    stc(i,n,t)                  start-up costs [EUR per MW] (are computed within the model)
    sdc(i,n,t)                 shut down costs [EUR per MW]
    costs_depr(i)               depreciation costs for a start-up [EUR per MW]
    fuel_start(i)               fuel requirement for a cold start [MWhth per MW]
    start_factor(i)             defines if a technology is carrying out cold, warm or hot starts (scales the fuel requirementof a cold start)
$ontext     nuclear plants are assumed to carry out only hot starts, requiring only 30% of the cold-start fuel requirement
            Lignite and hard coal plants are assumed to carry out warm starts with 50% of the cold-start fuel requirement
            natural gas and oil technologies are assumed to carry out cold starts, incurring 100% of the start-up fuel requirements
$offtext
    nd_fuel_factor(i)       states to what percentage a second fuel is used for a start-up, second fuel always oil

*demand parameters

    demand(t,n)             DA electricity demand forecast Entsoe [MWh per hour]
    demand_2DA_stoch(t,n,sd)        2DA demand
    TwoDayAhead_KIT_stoch(t,n,sd)   stochastic KIT electricity demand forecast two day ahead for Germany only [MWh per hour]
    TwoDAlastweek(t,n)      naive one week ago electricity demand forecast for two day ahead of countries other than Germany (t-168) [MWh per hour]

*RES parameters
    res_gen(t,n,i)      electricity production by RES technologies [MWh per MW]


*Hydro parameters

    cap_PSP_cluster_cluster_up(n,i,month)         PSP cluster upload
    cap_Reservoir_cluster_up(n,i,month)   Reservoir cluster upload
    cap_PSP_cluster(n,i,t)            hourly PSP cap
    cap_Reservoir_cluster(n,i,t)      hourly Reservoirs cap

    water_value_PSP_gen_up(n,i,month)   value for water regarding PSP while generating electricity upload [EUR per MWh]
    water_value_PSP_pump_up(n,i,month)  value for water regarding PSP while charging electricity [EUR per MWh]
    water_value_Reservoir_up(n,i,month) value for water regarding Reservoirs while generating electricity upload [EUR per MWh]
    water_value_PSP_gen(n,i,t)          hourly water value PSP
    water_value_PSP_pump(n,i,t)         value for water regarding PSP while charging electricity [EUR per MWh]
    water_value_Reservoir(n,i,t)        hourly water value Reservoirs

    wvf                 watervalue factor based on price levels

    availability_hydro(month,i,n)       turbine availability factor for hydro plants (seasonality etc)
    af_hydro(i,n,t)                     turbine availability factor for hydro plants (seasonality etc)
    budget(year,n)                      annual water budget factor for Reservoirs


*CHP parameters
    CHP_gen(i,n,t)                      CHP production which states a 'must-production' for CHP plants [MWh]
    CHP_gen_lig(n,t)
    CHP_gen_coal(n,t)
    CHP_gen_gas(n,t)
    CHP_gen_oil(n,t)

    CHP_gen_lig_cluster(i,n,t)          CHP production is evenly allocated to the fuel specific clusters
    CHP_gen_coal_cluster(i,n,t)         CHP production is evenly allocated to the fuel specific clusters
    CHP_gen_gas_cluster(i,n,t)          CHP production is evenly allocated to the fuel specific clusters
    CHP_gen_oil_cluster(i,n,t)          CHP production is evenly allocated to the fuel specific clusters



    CHP_net_production_up               annual net electricty production by CHP plants [GWh]
    CHP_total_factor_hourly(t,n)        country specific hourly CHP factor for the total CHP production

*NTC/Trade parameters
    ntc(t,n,nn)                         transfer capacity between node n and node nn [MW]


* Control Power
    PR(n)        primary reserve
    SR_pos(n)    secondary reserve - positive
    SR_neg(n)    secondary reserve - negative

* upload tables
    priceup         upload table for prices (fuels and CO2)
    gaspriceup      upload table for country-specific gas prices
    techup          upload table for technologies
    CP_up           upload of control power data


    running_cap_fx(i,n,t)  fixed running capacity for loop start

;

Scalars
    scaling_objective   scaling the objective function by 1 bn EUR /1000000/
    store_cpf           capacity power factor for Storages  /9/
    voll                value of lost load                  /3000/
    cost_curt           penalty cost for curtaiment         /20/
    number_hours        number of running hours

    share_PSP_daily     share of PSP cap that runs a daily cycle /0.7/


    x_down
    x_up
    x_focus             first hour of the forcasted day
    x_focus_up
;

    number_hours = card(year)*8760  ;




*#############################   Data Upload   ##############################
*-------- Input_general (allyears) -----------
$onecho > Import_general.txt
    set=i           rng=Technology!B3       rdim=1
    set=n           rng=nodes!B3            rdim=1

    par=cap_up         rng=capacity!A2         rdim=2 cdim=2

    par=priceup        rng=prices!N2:Y4100           rdim=3 cdim=1
    par=gaspriceup     rng=prices!AB2:BA4100         rdim=3 cdim=1

    par=techup         rng=Technology!B2:Q55   rdim=1 cdim=1
    par=CHP_net_production_up    rng=el_production_CHP!B2:AA44   rdim=2 cdim=1
    par=af_tech_general               rng=nodes!E2        rdim=1 cdim=1

    par=cap_PSP_cluster_cluster_up    rng=Hydro!A3:N40    rdim=2 cdim=1
    par=cap_Reservoir_cluster_up      rng=Hydro!A118:N155 rdim=2 cdim=1
    par=water_value_PSP_gen_up        rng=Hydro!A45:N80   rdim=2 cdim=1
    par=water_value_PSP_pump_up       rng=Hydro!A82:N116  rdim=2 cdim=1
    par=water_value_Reservoir_up      rng=Hydro!A157:N195 rdim=2 cdim=1
    par=availability_hydro            rng=nodes!D43:AC100 rdim=2 cdim=1

$offecho

$onUNDF
$call GDXXRW I=%datadir%%DataIn_general%.xlsx O=%datadir%%DataIn_general%.gdx cmerge=1 @Import_general.txt
$gdxin %datadir%%DataIn_general%.gdx

$LOAD i, n
$LOAD priceup, gaspriceup, techup
$LOAD CHP_net_production_up
$load cap_up
$LOAD af_tech_general
$LOAD cap_Reservoir_cluster_up,cap_PSP_cluster_cluster_up
$Load water_value_PSP_gen_up,water_value_Reservoir_up, water_value_PSP_pump_up
$Load availability_hydro

$gdxin
$offUNDF

*-------- Input_year-specific -----------
$onecho > Import_yearly.txt
    set=bs           rng=CP!H2            rdim=1
    set=bp           rng=CP!I2            rdim=1
    set=map_YMDHbbT        rng=timemap!B2      rdim=7

    par=outages_up               rng=Outages!B1                 rdim=1 cdim=2
    par=CHP_total_factor_hourly  rng=CHP_hourly!B2:Y9050        rdim=1 cdim=1

    par=demand              rng=Demand!B1               rdim=1 cdim=1
    par=TwoDayAhead_KIT_stoch     rng=Demand_2DA_KIT_stoch!B1       rdim=1 cdim=2
    par=TwoDAlastweek       rng=Demand_t-168!B1         rdim=1 cdim=1
    par=res_gen             rng=RES!B1                  rdim=1 cdim=2

    par=ntc                 rng=NTC!B1          rdim=1  cdim=2
    par=CP_up               rng=CP!B2           rdim=1
    par=wvf                 rng=Hydro!B3        rdim=0 cdim=0

$offecho

$onUNDF
$call GDXXRW I=%datadir%%DataIn_yearly%.xlsx O=%datadir%%DataIn_yearly%.gdx cmerge=1 @Import_yearly.txt
$gdxin %datadir%%DataIn_yearly%.gdx

$LOAD bs, bp
$LOAD map_YMDHbbT
$LOAD outages_up
$LOAD CHP_total_factor_hourly
$LOAD demand, TwoDAlastweek, TwoDayAhead_KIT_stoch
$LOAD res_gen
$LOAD wvf
$LOAD ntc
$Load CP_up

$gdxin
$offUNDF

*$stop

*#############################   Parameter Processing   ##############################

* -------------------    MAPPING TIME   --------------------
    Loop(map_YMDHbbT(year,month,day,hour,bs,bp,t),

        Day_T(day,t)        = yes;
        map_YMT(year,month,t) = yes ;
        map_YMDT(year,month,day,t) = yes;
        map_YMDHT(year,month,day,hour,t) = yes;
        map_YDT(year,day,t) = yes ;
        map_YT(year,t)      = yes ;
        map_MT(month,t)     = yes ;
        map_bsT(bs,t)         = yes ;
        map_bpT(bp,t)         = yes ;
        );


* --------------- Subset Definitions    --------------------
    Thermal(i) = NO;
    Hydro(i)   = NO;
    ResT(i)    = NO;
    Nuclear(i)  = NO;
    Lignite(i)  = NO;
    Coal(i)     = NO;
    Gas(i)      = NO;
    Oil(i)      = NO;
    Biomass(i)  = NO;
    ReservoirCluster(i)= NO;
    StorageCluster(i) = NO;

    Thermal(i)  = techup(i,'Tech_class_2')= 1 ;
    ResT(i)     = techup(i,'Tech_class_2')= 2 ;
    Hydro(i)    = techup(i,'Tech_class_2')= 3 ;
    Nuclear(i)  = techup(i,'Tech_class_1')= 1 ;
    Lignite(i)  = techup(i,'Tech_class_1')= 2 ;
    Coal(i)     = techup(i,'Tech_class_1')= 3 ;
    Gas(i)      = techup(i,'Tech_class_1')= 4 ;
    Oil(i)      = techup(i,'Tech_class_1')= 5 ;
    Biomass(i)  = techup(i,'Tech_class_1')= 6 ;
    ReservoirCluster(i) = techup(i,'Tech_class_1')= 7 ;
    StorageCluster(i)   = techup(i,'Tech_class_1')= 8 ;


* ------------   Loading Parameters     ---------------------
    co2_price(year,month,day)    = priceup(year,month,day,'CO2')         ;
    co2_price_UK(year,month,day) = priceup(year,month,day,'CO2_UK')        ;
    fc(Nuclear,n,year,month,day) = priceup(year,month,day,'Nuclear')     ;
    fc(Lignite,n,year,month,day) = priceup(year,month,day,'Lignite')     ;
    fc(Coal,n,year,month,day)    = priceup(year,month,day,'Coal')        ;
    fc(Gas,n,year,month,day)     = gaspriceup(year,month,day,n)          ;
    fc(Oil,n,year,month,day)     = priceup(year,month,day,'Oil')         ;
    fc(Biomass,n,year,month,day) = priceup(year,month,day,'Biomass')     ;

    vOM_cost(i) = techup(i,'variable OM costs') ;

    eta_fl(i,n) = techup(i,'efficiency full load') ;
    eta_ml(i,n) = techup(i,'efficiency min load') ;
    carbon_content(i) = techup(i,'carbon content') ;

    g_min(i)    = techup(i,'minimum generation')  ;
    downtime(i) = techup(i,'minimum downtime')   ;

    costs_depr(i)   = techup(i,'depreciation costs')    ;
    fuel_start(i)   = techup(i,'fuel startup')    ;
    nd_fuel_factor(i) = techup(i,'share second startup fuel')    ;
    start_factor(i) = techup(i,'startup_factor')    ;


    cap(i,n,t)    =  sum( (year,month)$map_YMT(year,month,t), cap_up(n,i,year,month))  ;

    cap_lig(n,t)  = sum(lignite, cap(lignite,n,t))   ;
    cap_coal(n,t) = sum(coal, cap(coal,n,t))   ;
    cap_gas(n,t)  = sum(gas, cap(gas,n,t))   ;
    cap_oil(n,t)  = sum(oil, cap(oil,n,t))   ;



    cap_PSP_cluster(n,i,t)        = sum( (month)$map_MT(month,t), cap_PSP_cluster_cluster_up(n,i,month) );
    cap_Reservoir_cluster(n,i,t)  = sum( (month)$map_MT(month,t), cap_Reservoir_cluster_up(n,i,month) );

    water_value_PSP_pump(n,i,t)   = sum( (month)$map_MT(month,t),  water_value_PSP_pump_up(n,i,month) *wvf );
    water_value_PSP_gen(n,i,t)    = sum( (month)$map_MT(month,t),  water_value_PSP_gen_up(n,i,month)*wvf )      ;
    water_value_Reservoir(n,i,t)  = sum( (month)$map_MT(month,t),  water_value_Reservoir_up(n,i,month)*wvf );

    af_hydro(i,n,t) = sum( (month)$map_MT(month,t), availability_hydro(month,i,n))  ;

%Before2015% af_tech_general(Thermal,n) = 0.87 ;

    af_tech_t(i,n,t) =  af_tech_general(i,n);
    af_overall(i,n,t) = af_tech_t(i,n,t) ;

    demand_2DA_stoch(t,n,sd) = TwoDayAhead_KIT_stoch(t,n,sd) + TwoDAlastweek(t,n) ;



    outages('lignite_1',n,t)$cap('lignite_1',n,t) = outages_up(t,n,'Lig')*cap('lignite_1',n,t)/sum(lignite,cap(lignite,n,t))     ;
    outages('lignite_2',n,t)$cap('lignite_2',n,t) = outages_up(t,n,'Lig')*cap('lignite_2',n,t)/sum(lignite,cap(lignite,n,t))     ;
    outages('lignite_3',n,t)$cap('lignite_3',n,t) = outages_up(t,n,'Lig')*cap('lignite_3',n,t)/sum(lignite,cap(lignite,n,t))     ;
    outages('lignite_4',n,t)$cap('lignite_4',n,t) = outages_up(t,n,'Lig')*cap('lignite_4',n,t)/sum(lignite,cap(lignite,n,t))     ;

    outages('coal_1',n,t)$cap('coal_1',n,t) = outages_up(t,n,'HC')*cap('coal_1',n,t)/sum(coal,cap(coal,n,t))     ;
    outages('coal_2',n,t)$cap('coal_2',n,t) = outages_up(t,n,'HC')*cap('coal_2',n,t)/sum(coal,cap(coal,n,t))     ;
    outages('coal_3',n,t)$cap('coal_3',n,t) = outages_up(t,n,'HC')*cap('coal_3',n,t)/sum(coal,cap(coal,n,t))     ;
    outages('coal_4',n,t)$cap('coal_4',n,t) = outages_up(t,n,'HC')*cap('coal_4',n,t)/sum(coal,cap(coal,n,t))     ;

    outages('CCGT_1',n,t)$cap('CCGT_1',n,t) = outages_up(t,n,'natural gas')*cap('CCGT_1',n,t)/sum(gas,cap(gas,n,t))     ;
    outages('CCGT_2',n,t)$cap('CCGT_2',n,t) = outages_up(t,n,'natural gas')*cap('CCGT_2',n,t)/sum(gas,cap(gas,n,t))     ;
    outages('CCGT_3',n,t)$cap('CCGT_3',n,t) = outages_up(t,n,'natural gas')*cap('CCGT_3',n,t)/sum(gas,cap(gas,n,t))     ;
    outages('CCGT_4',n,t)$cap('CCGT_4',n,t) = outages_up(t,n,'natural gas')*cap('CCGT_4',n,t)/sum(gas,cap(gas,n,t))     ;

    outages('OCGT_1',n,t)$cap('OCGT_1',n,t) = outages_up(t,n,'natural gas')*cap('OCGT_1',n,t)/sum(gas,cap(gas,n,t))     ;
    outages('OCGT_2',n,t)$cap('OCGT_2',n,t) = outages_up(t,n,'natural gas')*cap('OCGT_2',n,t)/sum(gas,cap(gas,n,t))     ;
    outages('OCGT_3',n,t)$cap('OCGT_3',n,t) = outages_up(t,n,'natural gas')*cap('OCGT_3',n,t)/sum(gas,cap(gas,n,t))     ;
    outages('OCGT_4',n,t)$cap('OCGT_4',n,t) = outages_up(t,n,'natural gas')*cap('OCGT_4',n,t)/sum(gas,cap(gas,n,t))     ;

    outages('gassteam_1',n,t)$cap('gassteam_1',n,t) = outages_up(t,n,'natural gas')*cap('gassteam_1',n,t)/sum(gas,cap(gas,n,t))     ;
    outages('gassteam_2',n,t)$cap('gassteam_2',n,t) = outages_up(t,n,'natural gas')*cap('gassteam_2',n,t)/sum(gas,cap(gas,n,t))     ;
    outages('gassteam_3',n,t)$cap('gassteam_3',n,t) = outages_up(t,n,'natural gas')*cap('gassteam_3',n,t)/sum(gas,cap(gas,n,t))     ;
    outages('gassteam_4',n,t)$cap('gassteam_4',n,t) = outages_up(t,n,'natural gas')*cap('gassteam_4',n,t)/sum(gas,cap(gas,n,t))     ;

    outages('nuclear_3',n,t) = outages_up(t,n,'nuc')  ;

    vc_fl(i,n,t)$eta_fl(i,n) = vOM_cost(i)+ sum( (year,month,day)$map_YMDT(year,month,day,t),(fc(i,n,year,month,day)+carbon_content(i)*co2_price(year,month,day)) / eta_fl(i,n))   ;
    vc_fl(i,"UK",t)$eta_fl(i,"UK") = vOM_cost(i)+ sum( (year,month,day)$map_YMDT(year,month,day,t),(fc(i,"UK",year,month,day)+carbon_content(i)*co2_price_UK(year,month,day)) / eta_fl(i,"UK"))   ;
    vc_ml(i,n,t)$eta_ml(i,n) = vOM_cost(i)+ sum( (year,month,day)$map_YMDT(year,month,day,t),(fc(i,n,year,month,day)+carbon_content(i)*co2_price(year,month,day)) / eta_ml(i,n))   ;
    vc_ml(i,"UK",t)$eta_ml(i,"UK") = vOM_cost(i)+ sum( (year,month,day)$map_YMDT(year,month,day,t),(fc(i,"UK",year,month,day)+carbon_content(i)*co2_price_UK(year,month,day)) / eta_ml(i,"UK"))   ;

    stc(i,n,t) = sum( (year,month,day)$map_YMDT(year,month,day,t), (costs_depr(i) + fuel_start(i)*start_factor(i) *
           (fc(i,n,year,month,day)+carbon_content(i)*co2_price(year,month,day)) *(1-nd_fuel_factor(i))
         + (fc('OCOT_1',n,year,month,day)+carbon_content('OCOT_1') * co2_price(year,month,day)) *nd_fuel_factor(i)) )
    ;
    stc(i,"UK",t) = sum( (year,month,day)$map_YMDT(year,month,day,t), (costs_depr(i) + fuel_start(i)*start_factor(i) *
           (fc(i,"UK",year,month,day)+carbon_content(i)*co2_price_UK(year,month,day)) *(1-nd_fuel_factor(i))
         + (fc('OCOT_1',"UK",year,month,day)+carbon_content('OCOT_1') * co2_price_UK(year,month,day)) *nd_fuel_factor(i)) )
    ;

    sdc(i,n,t) = stc(i,n,t) / 10 ;

    PR(n)    = 0  ;
    SR_pos(n) = 0 ;
    SR_neg(n) = 0 ;

    PR('DE')    = CP_up('Primary')  ;
    SR_pos('DE') = CP_up('Secondary_pos') ;
    SR_neg('DE') = CP_up('Secondary_neg') ;

    CHP_gen_lig(n,t)        = sum((year)$map_YT(year,t), CHP_net_production_up(year,'Lig',n))*1000 * CHP_total_factor_hourly(t,n)  ;
    CHP_gen_coal(n,t)       = sum((year)$map_YT(year,t), CHP_net_production_up(year,'HC',n))*1000 * CHP_total_factor_hourly(t,n)     ;
    CHP_gen_gas(n,t)        = sum((year)$map_YT(year,t), CHP_net_production_up(year,'natural gas',n))*1000 * CHP_total_factor_hourly(t,n)     ;
    CHP_gen_oil(n,t)        = sum((year)$map_YT(year,t), CHP_net_production_up(year,'öl',n))*1000 * CHP_total_factor_hourly(t,n)         ;


    CHP_gen_lig_cluster(lignite,n,t)$cap_lig(n,t) =    CHP_gen_lig(n,t) * cap(lignite,n,t) /  cap_lig(n,t) ;
    CHP_gen_coal_cluster(coal,n,t)$cap_coal(n,t)  =   CHP_gen_coal(n,t) * cap(coal,n,t) /   cap_coal(n,t) ;
    CHP_gen_gas_cluster(gas,n,t)$cap_gas(n,t)    =   CHP_gen_gas(n,t) * cap(gas,n,t) / cap_gas(n,t) ;
    CHP_gen_oil_cluster(oil,n,t)$cap_oil(n,t)    =   CHP_gen_oil(n,t) * cap(oil,n,t) / cap_oil(n,t) ;

    CHP_gen_gas_cluster(gas,'PL',t)$cap_gas('PL',t)     = 0.5 * CHP_gen_gas('PL',t) * cap(gas,'PL',t) / cap_gas('PL',t);







* --------------------- killing upload parameters -----------------------------

Option kill =    priceup          ;
Option kill =    gaspriceup       ;
Option kill =    techup           ;
Option kill =    CP_up            ;
Option kill =    CHP_net_production_up      ;
Option kill =    CHP_total_factor_hourly    ;
Option kill =    cap_PSP_cluster_cluster_up      ;
Option kill =    cap_Reservoir_cluster_up        ;
Option kill =    water_value_PSP_pump_up         ;
Option kill =    water_value_PSP_gen_up          ;
Option kill =    water_value_Reservoir_up        ;
Option kill =    availability_hydro              ;
Option kill =    outages_up                      ;
Option kill =    fc                              ;
Option kill =    co2_price                       ;
Option kill =    co2_price_UK                    ;
Option kill =    CHP_gen_lig                     ;
Option kill =    CHP_gen_coal                    ;
Option kill =    CHP_gen_gas                     ;
Option kill =    CHP_gen_oil                     ;
Option kill =    cap_up                     ;
Option kill =    cap_lig                         ;
Option kill =    cap_coal                        ;
Option kill =    cap_gas                         ;
Option kill =    cap_oil                         ;
Option kill =   TwoDayAhead_KIT_stoch            ;
Option kill =   TwoDAlastweek                    ;



