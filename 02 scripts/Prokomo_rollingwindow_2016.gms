$ontext
Dispatch model project ProKoMo

LSEW BTU

target:
    price forecast for 24 hours of the next day

method:
    - rolling horizon including a time intervall before and after the forecasted day
    - for storages a fixed (water)price is implemented
    - data is uploaded by annual data sets
    - years, months, days and hours are mapped
    - UTC time is applied for all data
    - data is uploaded only for the current year, all other years are de-activated


CODE STANDARTS (to be defined !)
    i              - major set
    StorG(i)       - subset
    lowercase      - parameter
    UPPERCASE      - variable
$offtext


*#############################  DEFAULT OPTIONS  #############################
$eolcom #


*to reproduce the paper, please keep the following settings
$setglobal Before2015 "*"      # "*" for years after 2015 (outages included), if "" then constant availability factor. Note that outages are included up from 2015

$setglobal Store  ""      # if "*" the storage functions excluded, if "" storage functions included
$setglobal Reserv  ""     # if "*" the reservoir functions excluded, if "" reservoir functions included
$setglobal Startup ""     # if "*" the startup functions excluded, if "" startup functions included
$setglobal Flow   ""      # if "*" the trade excluded, if "" trade included
$setglobal CHP    ""      # if "*" the trade excluded, if "" trade included
$setglobal xDem   ""      # if "*" the demand increase excluded, if "" demand increase included
$setglobal ConPow ""      # if "*" Control Power excluded, if "" Control Power included

$ifthen "%Store%" == ""     $setglobal exc_Store "*"
$else                       $setglobal exc_Store ""
$endif

$ifthen "%Reserv%" == ""     $setglobal exc_Reserv "*"
$else                       $setglobal exc_Reserv ""
$endif

$ifthen "%Startup%" == ""   $setglobal exc_Startup "*"
$else                       $setglobal exc_Startup ""
$endif



*#####################  DIRECTORIRY and FILE MANAGEMENT  #####################

$setglobal YearonFocus "2016"

*Location of input files
$setglobal datadir                data\
$setglobal DataIn_yearly              InputData%YearonFocus%
$setglobal DataIn_general             InputData_allyears

*Location of output files
$setglobal output_dir   output\
$setglobal result       Results_year%YearonFocus%

set
    daily_window  all days of the model horizon /day1*day374/

    t      all hours                       / t1*t8952  /
;

*#############################   DATA LOAD     ###############################

$include 01_declare_parameters.gms


*#############################   REPORTING INPUT ###############################

*execute_unload '%datadir%Input_final.gdx'
*$stop

*#############################   MODEL     #####################################

$include 02_MODEL.gms


*#############################   SOLVING     ###################################

$include 03_loop.gms

*#############################   results     #################################

$include 04_aftermath.gms














