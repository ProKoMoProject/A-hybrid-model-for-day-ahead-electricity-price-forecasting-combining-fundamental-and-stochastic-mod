
*##############################   Variables   ###############################

Variables
    COSTS           total generation costs (ojective variable)[bn €]
;

Positive Variables
*variables for the deterministic day and day-ahead 
    G(i,n,t)        generation of each technology cluster [MWh per h]
    P_on(i,n,t)     running (started) generation capacities [MW]
    SU(i,n,t)       start-up activity of a generation technology [MW]
    FLOW(n,nn,t)    electricity transfer from node n to nn [MWh per h]
    Pump(i,n,t)     storage charging driven by water value 
    Charge(i,n,t)   storage charging driven by storage mechanism
    Shed(n,t)       laod shedding
    Curtailment(i,n,t)  curtailment
     X_dem(n,t)         dummy variyble for demand increase
     storagelevel(i,n,t)    
    pcr(i,n,bp)         primary reserve provision
    scr_pos(i,n,bs)     secondary reserve provision - positive
    scr_neg(i,n,bs)     secondary reserve provision - negative

*variables for the stochastic two-day-ahead
    G_s(i,n,sd,t)
    P_on_s(i,n,sd,t)
    SU_s(i,n,sd,t)
    FLOW_s(n,nn,sd,t)
    Pump_s(i,n,sd,t)
    Charge_s(i,n,sd,t)
    Shed_S(n,sd,t)
    Curtailment_s(i,n,sd,t)
    X_dem_s(n,sd,t)
    storagelevel_s(i,n,sd,t)
    pcr_s(i,n,sd,bp)         primary reserve provision
    scr_pos_s(i,n,sd,bs)     secondary reserve provision - positive
    scr_neg_s(i,n,sd,bs)     secondary reserve provision - negative
;

*##############################   Equations   ###############################

Equations
    ojective            objective function minimizes total system costs
    energy_balance      demand equals supply
        energy_balance_2
    max_gen             generation is lower than running capacity
         max_gen_2
    min_gen             
        min_gen_2

    max_cap             running capacity is lower than installed capacity
         max_cap_2

    startup_constraint  constraining start-up activities
             startup_constraint_2  constraining start-up activities
             startup_constraint_3  constraining start-up activities

    shutdown_constraint constraining shutdown activities
        shutdown_constraint_2 constraining shutdown activities


    max_RES             maximum RES generation
        max_RES_2

    CHP_constraint_lig      must production for CHP plants
         CHP_constraint_lig_2
    CHP_constraint_coal      must production for CHP plants
         CHP_constraint_coal_2
    CHP_constraint_gas      must production for CHP plants
         CHP_constraint_gas_2
    CHP_constraint_oil      must production for CHP plants
         CHP_constraint_oil_2

    lineflow            Flow is restricted by the time dependent NTC
         lineflow_2

    Store_Level
    Store_Level_2
    Store_Level_3

    Store_Level_max
         Store_Level_max_2

    Store_max           maximum turbine capacity [MW]
         Store_max_2

    Store_tfirst
    Store_tlast

    res_psp1
    res_psp2

            Store_max_cluster
                 Store_max_cluster_2
            Pump_max_cluster
                 Pump_max_cluster_2
            Reservoir_power_max
                 Reservoir_power_max_2

    PrimReserve          Primary Reserve
        PrimReserve_2          Primary Reserve 2
    SecReserve_pos       positive Secondary Reserve
        SecReserve_pos_2       positive Secondary Reserve
    SecReserve_neg       negative Secondary Reserve
        SecReserve_neg_2       positive Secondary Reserve

;

ojective..      COSTS =E= ( sum(t$(ord(t)>=x_down and ord(t)<=x_focus_up),
                         sum( (Thermal,n)$cap(thermal,n,t), G(Thermal,n,t) * vc_fl(Thermal,n,t))
%Startup%              + sum( (Thermal,n)$cap(thermal,n,t), SU(Thermal,n,t) * stc(Thermal,n,t))
%Startup%              + sum( (Thermal,n)$cap(thermal,n,t), (P_on(Thermal,n,t)-G(Thermal,n,t)) * (vc_ml(Thermal,n,t)-vc_fl(Thermal,n,t))*g_min(Thermal) / (1-g_min(Thermal)))
                       + sum( (StorageCluster,n),G(StorageCluster,n,t)* water_value_PSP_gen(n,StorageCluster,t) )
                       + sum( (StorageCluster,n),Pump(StorageCluster,n,t)* water_value_PSP_pump(n,StorageCluster,t))
                       + sum( (ReservoirCluster,n),G(ReservoirCluster,n,t)*water_value_Reservoir(n,ReservoirCluster,t))
                       + sum( n, Shed(n,t)*voll + X_dem(n,t)*350)
                       + sum( (ResT,n), Curtailment(ResT,n,t) * cost_curt)
                         )) / scaling_objective

                      + (sum( t$(ord(t)>x_focus_up and ord(t)<=x_up), sum(sd, prob(sd) *(
                         sum( (Thermal,n)$cap(thermal,n,t), G_s(Thermal,n,sd,t) * vc_fl(Thermal,n,t) )
%Startup%              + sum( (Thermal,n)$cap(thermal,n,t), SU_s(Thermal,n,sd,t) * stc(Thermal,n,t) )
%Startup%              + sum( (Thermal,n)$cap(thermal,n,t), (((P_on_s(Thermal,n,sd,t)-G_s(Thermal,n,sd,t)) * (vc_ml(Thermal,n,t)-vc_fl(Thermal,n,t))*g_min(Thermal)) / (1-g_min(Thermal))) )
                       + sum( (StorageCluster,n), G_s(StorageCluster,n,sd,t)* water_value_PSP_gen(n,StorageCluster,t)  )
                       + sum( (StorageCluster,n), Pump_s(StorageCluster,n,sd,t)* water_value_PSP_pump(n,StorageCluster,t)  )
                       + sum( (ReservoirCluster,n), G_s(ReservoirCluster,n,sd,t)*water_value_Reservoir(n,ReservoirCluster,t)  )
                       + sum( n, (Shed_s(n,sd,t)*voll + X_dem_s(n,sd,t)*350)  )
                       + sum( (ResT,n), Curtailment_s(ResT,n,sd,t) * cost_curt )

                       )))) / scaling_objective
;


energy_balance(n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..      demand(t,n) + cap('PSP',n,t)*af_hydro('PSP',n,t)*(1-share_PSP_daily) =E=
                                                 sum(i, G(i,n,t))
                                            + sum(StorageCluster, Pump(StorageCluster,n,t))
%Store%                                     - Charge('PSP',n,t)
%Flow%                                      + sum(nn$ntc(t,nn,n), FLOW(nn,n,t)) - sum(nn$ntc(t,n,nn), FLOW(n,nn,t))
                                            + Shed(n,t)
%xDem%                                      - X_dem(n,t)
;

energy_balance_2(n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..     demand_2DA_stoch(t,n,sd) + cap('PSP',n,t)*af_hydro('PSP',n,t)*(1-share_PSP_daily) =E=
                                              sum(i, G_s(i,n,sd,t))
                                            + sum(StorageCluster, Pump_s(StorageCluster,n,sd,t) )
%Store%                                     - Charge_s('PSP',n,sd,t)
%Flow%                                      + sum(nn$ntc(t,nn,n), FLOW_s(nn,n,sd,t)) - sum(nn$ntc(t,n,nn), FLOW_s(n,nn,sd,t))
                                            + Shed_s(n,sd,t)
%xDem%                                      - X_dem_s(n,sd,t)
;


max_gen(Thermal,n,bs,bp,t)$(ord(t)>=x_down and ord(t)<=x_focus_up and map_bpt(bp,t)and map_bst(bs,t) )..       G(Thermal,n,t)
%ConPow%                                         + pcr(Thermal,n,bp)+scr_pos(Thermal,n,bs)
                                                                    =L=
%Startup%                                       P_on(Thermal,n,t)
%exc_Startup%                                   cap(Thermal,n,t) * af_overall(Thermal,n,t) - outages(Thermal,n,t)
;

max_gen_2(Thermal,n,sd,bs,bp ,t)$(ord(t)>x_focus_up and ord(t)<=x_up and map_bpt(bp,t)and map_bst(bs,t) )..       G_s(Thermal,n,sd,t)
%ConPow%                                         + pcr_s(Thermal,n,sd,bp)+scr_pos_s(Thermal,n,sd,bs)
                                                                    =L=
%Startup%                                       P_on_s(Thermal,n,sd,t)
%exc_Startup%                                   cap(Thermal,n,t) * af_overall(Thermal,n,t) - outages(Thermal,n,t)
;

min_gen(Thermal,n,bs,bp,t)$(ord(t)>=x_down and ord(t)<=x_focus_up and map_bpt(bp,t)and map_bst(bs,t) )..       G(Thermal,n,t) =G= P_on(Thermal,n,t)*g_min(Thermal)
%ConPow%                                                                                 + pcr(Thermal,n,bp)+scr_neg(Thermal,n,bs)
;
min_gen_2(Thermal,n,sd,bs,bp,t)$(ord(t)>x_focus_up and ord(t)<=x_up and map_bpt(bp,t)and map_bst(bs,t) )..       G_s(Thermal,n,sd,t) =G= P_on_s(Thermal,n,sd,t)*g_min(Thermal)
%ConPow%                                                                                 + pcr_s(Thermal,n,sd,bp)+scr_neg_s(Thermal,n,sd,bs)
;

max_cap(Thermal,n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..         P_on(Thermal,n,t)  =L= cap(Thermal,n,t) * af_overall(Thermal,n,t) - outages(Thermal,n,t)
;
max_cap_2(Thermal,n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..       P_on_s(Thermal,n,sd,t) =L= cap(Thermal,n,t) * af_overall(Thermal,n,t) - outages(Thermal,n,t)
;

startup_constraint(Thermal,n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..  P_on(Thermal,n,t)- P_on(Thermal,n,t-1) =L= SU(Thermal,n,t)
;
startup_constraint_2(Thermal,n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..  P_on_s(Thermal,n,sd,t) - P_on_s(Thermal,n,sd,t-1) =L= SU_s(Thermal,n,sd,t)
;
startup_constraint_3(Thermal,n,sd,t)$(ord(t)=x_focus_up )..         P_on_s(Thermal,n,sd,t) =E=  P_on(Thermal,n,t)
;
max_RES(ResT,n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..         G(ResT,n,t) =E= sqrt(sqr(res_gen(t,n,ResT))) - Curtailment(ResT,n,t)
;
max_RES_2(ResT,n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..         G_s(ResT,n,sd,t) =E=  sqrt(sqr(res_gen(t-24,n,ResT))) - Curtailment_s(ResT,n,sd,t)
;

CHP_constraint_lig(lignite,n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..    G(lignite,n,t) =G= CHP_gen_lig_cluster(lignite,n,t)
;
CHP_constraint_lig_2(lignite,n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..   G_s(lignite,n,sd,t) =G= CHP_gen_lig_cluster(lignite,n,t)
;
CHP_constraint_coal(coal,n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..      G(coal,n,t) =G= CHP_gen_coal_cluster(coal,n,t)
;
CHP_constraint_coal_2(coal,n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..      G_s(coal,n,sd,t) =G= CHP_gen_coal_cluster(coal,n,t)
;
CHP_constraint_gas(gas,n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..        G(gas,n,t) =G= CHP_gen_gas_cluster(gas,n,t)
;
CHP_constraint_gas_2(gas,n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..       G_s(gas,n,sd,t) =G= CHP_gen_gas_cluster(gas,n,t)
;
CHP_constraint_oil(oil,n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..        G(oil,n,t) =G= CHP_gen_oil_cluster(oil,n,t)
;
CHP_constraint_oil_2(oil,n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..        G_s(oil,n,sd,t) =G= CHP_gen_oil_cluster(oil,n,t)
;

lineflow(n,nn,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..      FLOW(n,nn,t)  =L=  ntc(t,n,nn)
;
lineflow_2(n,nn,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..      FLOW_s(n,nn,sd,t)  =L=  ntc(t-24,n,nn)
;

*daily storages
Store_Level(n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..     storagelevel('PSP',n,t+1) =E= storagelevel('PSP',n,t) - G('PSP',n,t) + Charge('PSP',n,t)*eta_fl('PSP',n)
;
Store_Level_2(n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..    storagelevel_s('PSP',n,sd,t+1) =E= storagelevel_s('PSP',n,sd,t) - G_s('PSP',n,sd,t) + Charge_s('PSP',n,sd,t)*eta_fl('PSP',n)
;
Store_Level_3(n,sd,t)$(ord(t)=x_focus_up )..                 storagelevel_s('PSP',n,sd,t-1) =E=  storagelevel('PSP',n,t) - G('PSP',n,t) + Charge('PSP',n,t)*eta_fl('PSP',n)
;

Store_Level_max(n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..      storagelevel('PSP',n,t) =L= cap('PSP',n,t) * share_PSP_daily * store_cpf
;
Store_Level_max_2(n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..      storagelevel_s('PSP',n,sd,t) =L= cap('PSP',n,t) * share_PSP_daily * store_cpf
;

Store_max(n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..        G('PSP',n,t) + Charge('PSP',n,t)*1.1
                                                                                        =L= cap('PSP',n,t) * share_PSP_daily * af_hydro('PSP',n,t)
;
Store_max_2(n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..        G_s('PSP',n,sd,t)  + Charge_s('PSP',n,sd,t)*1.1
                                                                                        =L= cap('PSP',n,t) * share_PSP_daily * af_hydro('PSP',n,t)
;

res_psp1(n,t)$(ord(t)>x_focus_up)..               G('PSP',n,t) + Charge('PSP',n,t)          =E= 0
;
res_psp2(n,sd,t)$(ord(t)<=x_focus_up)..           G_s('PSP',n,sd,t)+ Charge_s('PSP',n,sd,t) =E= 0
;

Store_tfirst(n,t,'PSP')$(ord(t)=x_down)..    storagelevel('PSP',n,t) =E= cap('PSP',n,t)* share_PSP_daily * af_hydro('PSP',n,t)*store_cpf * 0.3
;
Store_tlast(n,sd,t,'PSP')$(ord(t)=x_up)..     storagelevel_s('PSP',n,sd,t) =E= cap('PSP',n,t) * share_PSP_daily * af_hydro('PSP',n,t)*store_cpf * 0.3
;

*seasonal storages
Store_max_cluster(StorageCluster,n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..
                                        G(StorageCluster,n,t) =L= cap_PSP_cluster(n,StorageCluster,t) * (1-share_PSP_daily)
;
Store_max_cluster_2(StorageCluster,n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..
                                       G_s(StorageCluster,n,sd,t) =L= cap_PSP_cluster(n,StorageCluster,t) * (1-share_PSP_daily)
;
Pump_max_cluster(StorageCluster,n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..
                                        Pump(StorageCluster,n,t) =L= cap_PSP_cluster(n,StorageCluster,t) * (1-share_PSP_daily)
;
Pump_max_cluster_2(StorageCluster,n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..
                                        Pump_s(StorageCluster,n,sd,t)  =L= cap_PSP_cluster(n,StorageCluster,t) * (1-share_PSP_daily)
;
Reservoir_power_max(ReservoirCluster,n,t)$(ord(t)>=x_down and ord(t)<=x_focus_up)..
                                        G(ReservoirCluster,n,t)  =L= cap_Reservoir_cluster(n,ReservoirCluster,t)
;
Reservoir_power_max_2(ReservoirCluster,n,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up)..
                                        G_s(ReservoirCluster,n,sd,t) =L= cap_Reservoir_cluster(n,ReservoirCluster,t)
;

PrimReserve(bp,t)$(ord(t)>=x_down and ord(t)<=x_focus_up and map_bpt(bp,t))..         sum(Thermal, pcr(Thermal,'DE',bp)) =E= PR('DE')
;
PrimReserve_2(bp,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up and map_bpt(bp,t))..         sum(Thermal, pcr_s(Thermal,'DE',sd,bp)) =E= PR('DE')
;
SecReserve_pos(bs,t)$(ord(t)>=x_down and ord(t)<=x_focus_up and map_bst(bs,t))..     sum(Thermal, scr_pos(Thermal,'DE',bs)) =E= SR_pos('DE')
;
SecReserve_pos_2(bs,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up and map_bst(bs,t))..     sum(Thermal, scr_pos_s(Thermal,'DE',sd,bs)) =E= SR_pos('DE')
;
SecReserve_neg(bs,t)$(ord(t)>=x_down and ord(t)<=x_focus_up and map_bst(bs,t))..     sum(Thermal, scr_neg(Thermal,'DE',bs)) =E= SR_neg('DE')
;
SecReserve_neg_2(bs,sd,t)$(ord(t)>x_focus_up and ord(t)<=x_up and map_bst(bs,t))..     sum(Thermal, scr_neg_s(Thermal,'DE',sd,bs)) =E= SR_neg('DE')
;


G.fx('Reservoir',n,t)       =0      ;
G_s.fx('Reservoir',n,sd,t)  =0   ;

G.fx(Biomass,n,t)       = cap(Biomass,n,t)* af_overall(Biomass,n,t)      ;
G_s.fx(Biomass,n,sd,t)  = cap(Biomass,n,t)* af_overall(Biomass,n,t) ;

G.fx('RoR',n,t)         = CAP('RoR',n,t) * af_hydro('RoR',n,t)      ;
G_s.fx('RoR',n,sd,t)    = cap('RoR',n,t)* af_hydro('RoR',n,t) ;


model ProKoMo
    /
            ojective
            energy_balance
            energy_balance_2
            max_gen
            max_gen_2
%Startup%   min_gen
%Startup%   min_gen_2

%Startup%   max_cap
%Startup%   max_cap_2
%Startup%   startup_constraint
%Startup%   startup_constraint_2
%Startup%   startup_constraint_3


         max_RES
         max_RES_2

%CHP%       CHP_constraint_lig
%CHP%       CHP_constraint_lig_2
%CHP%       CHP_constraint_coal
%CHP%       CHP_constraint_coal_2
%CHP%       CHP_constraint_gas
%CHP%       CHP_constraint_gas_2
%CHP%       CHP_constraint_oil
%CHP%       CHP_constraint_oil_2

%Flow%      lineflow
%Flow%      lineflow_2

            Store_max_cluster
                 Store_max_cluster_2
            Pump_max_cluster
                 Pump_max_cluster_2
            Reservoir_power_max
                 Reservoir_power_max_2

%store%     Store_Level
%store%     Store_Level_2
%store%     Store_Level_3
%store%     Store_Level_max
%store%     Store_Level_max_2
%store%     Store_max
%store%     Store_max_2
%store%      res_psp1
%store%      res_psp2
%store%     Store_tfirst
%store%     Store_tlast

%ConPow%    PrimReserve
%ConPow%    PrimReserve_2
%ConPow%    SecReserve_pos
%ConPow%    SecReserve_pos_2
%ConPow%    SecReserve_neg
%ConPow%    SecReserve_neg_2
    /  ;

ProKoMo.reslim = 1000000000;
ProKoMo.iterlim = 1000000000;
ProKoMo.holdfixed = 1;

option LP = CPLEX   ;

option threads = 0;

option BRatio = 1 ;

*    ProKoMo.optfile = 1;
*    ProKoMo.dictfile=0;
*    ProKoMo.SCALEOPT = 1;
*    OBJECTIVE_GLOBAL.scale = 1e006;

option
    limrow = 0,         # equations listed per block
    limcol = 0,         # variables listed per block
    solprint = off,     # solver's solution output printed
    sysout = off;       # solver's system output printed

* Turn off the listing of the input file
$offlisting

* Turn off the listing and cross-reference of the symbols used
$offsymxref offsymlist

;
