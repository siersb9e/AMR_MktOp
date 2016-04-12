$title SAPP market operations model (SAPP_MktOP)
* Goal: test impact of different rules to manage dispatch and tx allocation between bilteral and market transactions

*declaration for sets, parameters, and variables
******************** sets ***********************************
SETS
PERIOD                                 period (hourly)
CONTROLAREA                            control area
COUNTRY                                countries belonging to each region
CtoCA            (COUNTRY,CONTROLAREA) assign a country to a control area
TECHNOLOGY                             technology (BIO COA DIES HFO GAS HYD WIND SOLAR)
THERMAL           (TECHNOLOGY)         thermal plants
HYDRO             (TECHNOLOGY)         hydro plants
RENEW             (TECHNOLOGY)         intermittent renewable plants
LINES             (COUNTRY,COUNTRY)    all interconnections
CALINES           (COUNTRY,COUNTRY)    interconnections within same control area
;

*shorthand references for each set name
ALIAS (p, PERIOD)
ALIAS (r,ri,rf,rr,CONTROLAREA);
ALIAS (c,ci,cf,COUNTRY);
ALIAS (g, TECHNOLOGY);
ALIAS (t, THERMAL);
ALIAS (h, HYDRO);
ALIAS (re,RENEW);

******************** INPUT PARAMETERS ****************************
PARAMETERS
*demand
pDemand                     (PERIOD,COUNTRY)   demand  [MW]

*technology performance
pCapacity                   (COUNTRY,TECHNOLOGY)           existing generating units [MW]
pAvailabilityFactor         (TECHNOLOGY)                   de-rating for maintenance and break downs [p.u]
pHeatRate                   (TECHNOLOGY)                   fuel consumption [MMBTU per MWh]
pRenewCF                    (PERIOD,TECHNOLOGY,COUNTRY)    renewable resources available in each period [p.u.]
pWindCF(p,g,c)
pSolarCF(p,g,c)

*technology costs
pVariableCost               (TECHNOLOGY)              [$ per MWh]
pFixedCost                  (TECHNOLOGY)              [$ per MW per year]
pFuelCost                   (COUNTRY,TECHNOLOGY)      [$ per MMBTU]
pCostNonServedEnergy                                  cost of non-served energy

*line parameters
pTxCapacity             (COUNTRY,COUNTRY)      max transfer capacity for existing and committed lines[MW]
pLosses                                                 line losses [p.u]

*fuel supplies
pFuelLimit                  (COUNTRY,TECHNOLOGY)      limits on the available fuel supplies for each country [MMBTU]

*operating parameters
pOpRes                      (COUNTRY,PERIOD)     operating reserves for each country based on the largest plant and a fraction of peak demand [MW]
pSoSTradeCost                             transaction cost for sharing reserves [$ per MW]

*hydro availability
pHydroUpperLimit            (COUNTRY,HYDRO)  hydro resources available in each period  [MWh]
;

******************** DECISION VARIABLES *****************************

POSITIVE VARIABLES
*activity
vConCapacity            (COUNTRY,PERIOD,TECHNOLOGY) capacity committed (synchronized to the grid) [MW]
vProduction             (COUNTRY,PERIOD,TECHNOLOGY)   production level from each plant in each time slice [MW]

*costs
vGxCost              (COUNTRY,PERIOD) annual fixed generation costs [$]
vENSCost             (COUNTRY,PERIOD)            cost of non-served energy [$]

*trade
vTrade                  (COUNTRY,COUNTRY,PERIOD) trade in each time slice [MW]
vTradeOpRes             (COUNTRY,COUNTRY,PERIOD)               trade in operating reserves [MW]
vENS                    (COUNTRY,PERIOD)                       non-served energy [MW]
vORNS                   (COUNTRY,PERIOD)                       unmet operating reserves [MW]
;

VARIABLES
vTotalCost                                          total cost [$] ;
*****************************************
*        Capacity and demands in MW
*        Investment and Fixed O&M Costs: Power plant: $/MW per year
*        Fuel costs: $/MMBTU
*        Variable O&M (& Import) Costs: $/MWh
*        Transmission investment costs: $/MW/km
*        Emissions: tons/MMBTU, tons
*
*****************************************

** get input data from excel **
SETS
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=Sets!A4:G104
O=Sets.inc
$offecho
$call =xls2gms @input.txt
$include sets.inc
;

*** demand ***
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=demand!A4:J172
O=demand.inc
$offecho
$call =xls2gms @input.txt
Table pDemand(p,c)
$include demand.inc
;

*** existing capacity ***
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=existingGxCap!A4:J13
O=cap.inc
$offecho
$call =xls2gms @input.txt
Table pCapacity(c,g)
$include cap.inc
;

*** generic technology generation params ***
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=GenerationParams!A3:E12
O=genparam.inc
$offecho
$call =xls2gms @input.txt
Table pGenParam(g,*)
$include genparam.inc
;

*** wind resources ***
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=Wind!A4:L172
O=windresource.inc
$offecho
$call =xls2gms @input.txt
Table pWindCF(p,g,c) renewable resources available in each time slice
$include windresource.inc
;

*** solar resources ***
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=Solar!A4:L172
O=solarresource.inc
$offecho
$call =xls2gms @input.txt
Table pSolarCF(p,g,c) renewable resources available in each time slice
$include solarresource.inc
;

*** fossil fuel resources ***
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=FuelResource!A5:D14
O=fuelresource.inc
$offecho
$call =xls2gms @input.txt
Table pFuelLimit(c,g) fossilfuel resources available in each country
$include fuelresource.inc
;

*** available hydro generation  ***
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=hydroResource!A4:B13
O=hydroResource.inc
$offecho
$call =xls2gms @input.txt
Table pHydroUpperLimit(c,h) hydro resources available in each year and climate change scenario
$include hydroresource.inc
;

*** fuel costs for each country, technology ***
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=fuelcosts!A3:J12
O=fuelcosts.inc
$offecho
$call =xls2gms @input.txt
Table pFuelCost(c,g) [$ per MMBTU]
$include fuelcosts.inc
;

*** transmission interconnections ***
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=Network!A4:J13
O=exlines.inc
$offecho
$call =xls2gms @input.txt
Table pTxCapacity(c,c) [MW]
$include exlines.inc
;

*** initial and minimum operating reserves ***
$onecho >input.txt
I="%system.fp%Input_MktOp.xlsx"
R=OpRes!A3:C12
O=res.inc
$offecho
$call =xls2gms @input.txt
Table pResParam(c,*) [MW]
$include res.inc
;

*** assign other parameters ***
*financial parameters
pSoSTradeCost                               = 1;
pCostNonServedEnergy                        = 800;
* all non wind, solar, and hydro plants have a capacity factor of 1
pRenewCF(p,g,c) = pWindCF(p,g,c) + pSolarCF(p,g,c);
pRenewCF(p,g,c)$[pRenewCF(p,g,c)=0] = 1;
* transmission parameters
pLosses                                     = 0.025;

* annualized line capital cost assuming 1.5% interest rate and 40 year payback period
pAvailabilityFactor(g)  = pGenParam(g,'AvailFactor');
pHeatRate(g)            = pGenParam(g,'HeatRate');
pVariableCost(g)        = pGenParam(g,'VarCost');
pFixedCost(g)           = pGenParam(g,'FixedCost');
* operating reserve requirements
pOpRes(c,p)               = pResParam(c,'OpRes');

*model equations
******************************************************************************
*** objective function  ***
equation EQ_totalcost                total costs ;
EQ_totalcost..vTotalCost =e= sum[(c,p),vGxCost(c,p) + vENSCost(c,p)];

******************************************************************************
*** generation costs ***
equation EQ_GxCost(c,p)                        variable costs;
EQ_GxCost(c,p)..vGxCost(c,p) =e= sum[g, vConCapacity(c,p,g)*pVariableCost(g) + vProduction(c,p,g)*pHeatRate(g)*pFuelCost(c,g)]
         + sum[ci, pSoSTradeCost*vTradeOpRes(c,ci,p)];

equation EQ_CostENS(c,p);
EQ_CostENS(c,p)..vENSCost(c,p) =e= pCostNonServedEnergy*(vENS(c,p) + .1*vORNS(c,p)) ;

******************************************************************************
*** generation capacity adequacy A ***

equation EQ_ConnectedCapacity(c,p,g)             maximum connected capacity that can be online;
EQ_ConnectedCapacity(c,p,g)..vConCapacity(c,p,g) =l= pCapacity(c,g)*pAvailabilityFactor(g)*pRenewCF(p,g,c) ;

equation EQ_AvailableCapacity(c,p,g)             cap total production for each time slice by de-rating power plants;
EQ_AvailableCapacity(c,p,g)..vProduction(c,p,g) =l= vConCapacity(c,p,g);

equation EQ_HydroUpperLimit(c,h)                      for each hydro scneario cap total annual hydro production;
EQ_HydroUpperLimit(c,h)..sum[p, vProduction(c,p,h)] =l= pHydroUpperLimit(c,h) ;

equation EQ_FuelUpperLimit(c,t)                           cap total fuel consumption by resource availability;
EQ_FuelUpperLimit(c,t)..sum[p, vProduction(c,p,t)*pHeatRate(t)] =l= pFuelLimit(c,t) ;

******************************************************************************
***energy balance ***

equation EQ_Balance(c,p)                             production must equal demand for all periods;
EQ_Balance(c,p)..sum[g, vProduction(c,p,g)] + vENS(c,p) =e= pDemand(p,c) + sum[LINES(c,cf), vTrade(c,cf,p)*(1-pLosses)]
                          - sum[LINES(ci,c), vTrade(ci,c,p)*(1-pLosses)];

******************************************************************************
*** trade ***
equation EQ_MaxTrade(ci,cf,p)                          technical limit on power trade;
EQ_MaxTrade(ci,cf,p)..vTrade(ci,cf,p) =l= pTxCapacity(ci,cf)   ;

equation EQ_MaxORTrade(ci,cf,p)                          technical limit on sharing operating reserves;
EQ_MaxORTrade(ci,cf,p)..vTradeOpRes(ci,cf,p) =l=  pTxCapacity(ci,cf)   ;

equation EQ_OpResSh(c,p)             operating reserves;
EQ_OpResSh(c,p)..sum[g, vConCapacity(c,p,g)] - sum[g, vProduction(c,p,g)] -
          sum[LINES(c,cf)$CALines(c,cf), vTradeOpRes(c,cf,p)] + sum[LINES(ci,c), vTradeOpRes(ci,c,p)] + vORNS(c,p) =g= pOpRes(c,p);

******* solve the model *********
*************************************


model mktop /EQ_totalcost,EQ_GxCost,EQ_CostENS, EQ_ConnectedCapacity,
            EQ_AvailableCapacity,EQ_HydroUpperLimit,EQ_FuelUpperLimit,
            EQ_Balance,EQ_MaxTrade, EQ_MaxORTrade,EQ_OpResSh/;

option limrow=0, limcol=0, solprint=on;

solve mktop minimizing vTotalCost using LP;

***************************************************************************
*** data output to excel ***

* data output to xls file
file MktOp_Results / mktop_results.txt /
put MktOp_Results putclose 'var=vConCapacity.l rng=vConCap!b2' / 'var=vProduction.l rng=vProd!b2'
         / 'var=vENS.l rng=vENS!b2'/ 'var=vTrade.l rng=vElecTrade!b2' / 'var=vGxCost rng=vGxCost!b2'/
         'var=vTotalCost.l rng=vTotCost!b2'/ 'var=vENSCost.l rng=vENSCost!b2'/
         'var=vTradeOpRes.l rng=vTradeOpRes!g2'/ 'var=vORNS.l rng=vORNS!b2'

execute_unload   'mktop_results.gdx' vConCapacity.l vProduction.l vENS.l
         vTrade.l vGxCost vTotalCost.l vENSCost.l vTradeOpRes.l vORNS.l
execute          'gdxxrw.exe mktop_results.gdx SQ=n EpsOut=0 O="mktop_results.xlsx" @mktop_results.txt'
execute          'del        mktop_results.gdx                            mktop_results.txt'