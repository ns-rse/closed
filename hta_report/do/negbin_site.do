/* File           check_negbin.do                                   */
/* Author         n.shephard@sheffield.ac.uk                        */
/* Description    Uses -xtnbreg- to perform negative binomial       */
/*                time-series regerssion.                           */
clear
set more off
capture log c
version 14.1
/* Conditionally set the base directory                             */
if("`c(os)'" == "Unix"){
    local base_dir "~/work/closed/hta_report/"
}
else{
    di "This scripts will only run on the mcru-closed-hp Virtual Machine due to restrictions on data security."
    exit
}

/* Load the Site level data                                         */
use "`base_dir'/data/site.dta", clear
/* Sort out measure                                                 */
local measure     = subinstr("`1'", "_", " ", .)
local sub_measure = subinstr("`2'", "_", " ", .)
keep if(measure == "`measure'" & sub_measure == "`sub_measure'")
decode town, generate(town_string)
xtset town relative_month
tempfile data
save `data', replace


/* Set the various models, can only run models 0 to 5 as LSOA level */
/* data can not be taken off of the Virtual Machines and I don't    */
/* have Stata available on the GNU/Linux Virtual Machine            */
local iter       200
local tolerance  0.01
local nrtolerance 0.001
local ltolerance  0.001
local outcome    value
local model0     i.closure
local model1     i.closure relative_month i.season i.nhs111 i.other_centre i.ambulance_divert
local model2     i.town##i.closure relative_month i.season i.nhs111 i.other_centre i.ambulance_divert
local model4     i.closure relative_month i.season i.nhs111 other_centre ambulance_divert

/************************************************************************/
/* PROBLEM!!!! Some sites do not run, build local macro conditional     */
/*             on outcome being tested for now until this is solved.    */
/************************************************************************/
if(`measure' == "ed attendances" & `sub_measure' == "any")            local sites '" "Bishop Auckland" "Hartlepool"  "Newark" "Rochdale" "'
else if(`measure' == "ed attendances" & `sub_measure' == "other")     local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead"  "Newark" "Rochdale" "'
else if(`measure' == "ed attendances" & `sub_measure' == "ambulance") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "unnecessary ed attendances" & `sub_measure' == "all") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "all emergency admissions" & `sub_measure' == "all") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "avoidable emergency admissions" & `sub_measure' == "any") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "avoidable emergency admissions" & `sub_measure' == "non-specific chest pain") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "ed attendances admitted" & `sub_measure' == "all") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "ed attendances admitted" & `sub_measure' == "admitted") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "critical care stays" & `sub_measure' == "all") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "critical care stays" & `sub_measure' == "critical care") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "ambulance green calls" & `sub_measure' == "green calls") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "ambulance green calls" & `sub_measure' == "not conveyed green calls") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "ambulance red calls" & `sub_measure' == "hospital transfers") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "ambulance red calls" & `sub_measure' == "total") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "ambulance red calls" & `sub_measure' == "all stays") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'
else if(`measure' == "ambulance red calls" & `sub_measure' == "stays with trasnfer") local sites '" "Bishop Auckland" "Hartlepool" "Hemel Hempstead" "Newark" "Rochdale" "'

/* Run Analyses for within centres                                      */
/* Initially these were not converging found a thread on Stata Forums   */
/* https://goo.gl/a5wHMx                                                */
foreach x of local sites{
    use "`data'", clear
    /* Model 0                                                          */
    di "`x' : Model 0"
    xtnbreg `outcome' `model0' if(town_string == "`x'"), iterate(`iter') ltolerance(`ltolerance') nrtolerance(`nrtolerance')
    parmest, saving("`base_dir'/data/results/model0.dta", replace) eform label
    /* Model 1                                                          */
    di "`x' : Model 1"
    xtnbreg `outcome' `model1' if(town_string == "`x'"), iterate(`iter') ltolerance(`ltolerance') nrtolerance(`nrtolerance')
    parmest, saving("`base_dir'/data/results/model1.dta", replace) eform label
    /* Model 2                                                          */
    di "`x' : Model 2"
    if("x'" == "Bishop Auckland")      local x2 = "Whitehaven"
    else if("x'" == "Hartlepool")      local x2 = "Grimsby"
    else if("x'" == "Hemel Hempstead") local x2 = "Warwick"
    else if("x'" == "Newark")          local x2 = "Southport"
    else if("x'" == "Rochdale")        local x2 = "Rotherham"
    xtnbreg `outcome' `model2' if(town_string == "`x'" | town_string == "`x2'"), iterate(`iter') ltolerance(`ltolerance') nrtolerance(`nrtolerance')
    parmest, saving("`base_dir'/data/results/model2.dta", replace) eform label
    use "`base_dir'/data/results/model0.dta", clear
    gen model = "model0"
    tempfile t
    save `t', replace
    use "`base_dir'/data/results/model1.dta", clear
    gen model = "model1"
    append using `t'
    save `t', replace
    use "`base_dir'/data/results/model2.dta", clear
    gen model = "model2"
    append using `t'
    gen town = "`x'"
    if("`x'" == "Bishop Auckland"){
        tempfile results
        save `results', replace
    }
    else{
        append using `results'
        save `results', replace
    }
}


/* Run Analyses for pooled centres at both Site level (model 4)       */
di "All : Model 4"
use `data', clear
keep if(town_string == "Bishop Auckland" | town_string ==  "Whitehaven" | ///
        town_string == "Hartlepool"      | town_string ==  "Grimsby"    | ///
        town_string == "Hemel Hempstead" | town_string ==  "Warwick"    | ///
        town_string == "Newark"          | town_string ==  "Southport"  | ///
        town_string == "Rochdale"        | town_string ==  "Rotherham")
xtnbreg `outcome' `model4', iterate(`iter') ltolerance(`ltolerance') nrtolerance(`nrtolerance') technique(nr 10 dfp 10 bfgs 10)
parmest, saving("`base_dir'/data/results/model4.dta", replace) eform label
use "`base_dir'/data/results/model4.dta", clear
gen model = "model4"
gen town  = "All"
append using `results'
save `results', replace

/* Add in meaningful terms for the parameters which are now all       */
/* obfuscated                                                         */
gen measure     = "`1'"
gen sub_measure = "`2'"
replace label = "(Intercept)"                 if(parm == "Constant")
replace label = "closure"                     if(parm == "1.closure")
replace label = "season2"                     if(parm == "2.season")
replace label = "season3"                     if(parm == "3.season")
replace label = "season4"                     if(parm == "4.season")
replace label = "season5"                     if(parm == "5.season")
replace label = "season6"                     if(parm == "6.season")
replace label = "townBishop Auckland"         if(parm == "2o.town")
replace label = "townHartlepool"              if(parm == "6o.town")
replace label = "townHemel Hempstead"         if(parm == "7o.town")
replace label = "townNewark"                  if(parm == "8o.town")
replace label = "townRochdale"                if(parm == "9o.town")
replace label = "townBishop Auckland:closure" if(parm == "2o.town#1o.closure")
replace label = "townHartlepool:closure"      if(parm == "6o.town#1o.closure")
replace label = "townHemel Hempstead:closure" if(parm == "7o.town#1o.closure")
replace label = "townNewark:closure"          if(parm == "8o.town#1o.closure")
replace label = "townRochdale:closure"        if(parm == "9o.town#1o.closure")

/* Save for reading into Stata                                        */
keep measure sub_measure town model parm label estimate stderr z p min95 max95
save "`base_dir'/data/results/stata_negbin_site.dta", replace
