
program define sensemakr, eclass
version 13
syntax varlist(min=2 ts fv) [if] [, Treat(varlist ts max=1) ///
		Benchmark(varlist ts fv) ///
		GBenchmark(varlist min=2 ts fv) ///
		Gname(name) ///
		Extremeplot ///
		Elim(numlist min=2 max=2) ///
		Contourplot ///
		TContourplot ///
		Clim(numlist min=2 max=2) ///
		r2yz(numlist min=1 max=4 >0 <=1) ///
		Clines(real 7) ///
		Noreduce ///
		Suppress ///
		q(real 1) /// 
		latex(name) ///
		kd(numlist min=1 > 0) ///
		ky(numlist min=1 > 0) ///
		alpha(real .05)]

marksample touse
local depvar: word 1 of `varlist'
local regs: list varlist - depvar
qui: reg `depvar' `regs' if `touse'


// Options and Error handling
if ("`treat'" == ""){
	display as error "Please specify a treatment variable"
    exit 198
}

if (`q' <= 0){
    display as error "q must be greater than 0"
    exit 198
}

if (`alpha' >= 1 | `alpha' <= 0 ){
    display as error "Invalid alpha value"
    exit 198
}

if ("`kd'"==""){
	local noinput = 1
	local kd 1 2 3
} 
else {
	local noinput = 0		
}

if ("`noreduce'" != ""){
	local reduce = 0
	local reduce_t = "FALSE"
} 
else {
	local reduce= 1
	local reduce_t = "TRUE"
}

// Kd-ky
local count_values_kd: word count `kd'

if ("`ky'" != ""){
	local custom_ky = 1
	local count_values_ky: word count `ky'

	if ("`count_values_kd'"!="`count_values_ky'"){
		display as error "ky must have the same number of elements as kd"
		exit 198
	}
} 
else {
	local ky `kd'
	local custom_ky = 0
}

// Extreme scenarios
if ("`r2yz'"==""){
	local mbounds = 1
} 
else {
	local mbounds = "`r2yz'"
}

// Contour plot limits
if ("`clim'"==""){
	local lim_ub = .4
	local lim_lb = 0
	global user_clim = 0
}
else {
	local lim_ub : word 2 of `clim'
	local lim_lb : word 1 of `clim'
	global user_clim = 1
}

if (`lim_ub' > 1){
	display as error "Max upper limit for contour plot is 1"
	exit 198
}

if (`lim_lb' < 0){
	display as error "Min lower limit for contour plot  is 0"
	exit 198
}

if (`lim_lb' > `lim_ub'){
	display as error "Lower limit for contour plot should be less than upper limit"
	exit 198
}	

// Extreme plot limits
if ("`elim'"==""){
	local elim_ub = .4
	local elim_lb = 0
}
else {
	local elim_ub : word 2 of `elim'
	local elim_lb : word 1 of `elim'
}

if (`elim_ub' > 1){
	display as error "Max upper limit for extreme plot is 1"
	exit 198
}

if (`elim_lb' < 0){
	display as error "Min lower limit for extreme plot  is 0"
	exit 198
}

if (`elim_lb' > `elim_ub'){
	display as error "Lower limit for extreme plot should be less than upper limit"
	exit 198
}	

// Minimal Reporting	
local b_treat = _b[`treat']
local se_treat = _se[`treat']
local t_treat =  `b_treat'/`se_treat'
local dof = e(df_r)
local qf = `q' * abs(`t_treat' / sqrt(`dof'))
local critical_f = abs( invt(`dof'-1, (`alpha'/2))) / sqrt(`dof' - 1)
local qf2 = `qf' - (`critical_f')
local r2yd_x = `t_treat'*`t_treat' / (`t_treat'*`t_treat' + `dof')
local f2yd_x = `t_treat'*`t_treat' / `dof'	
local scale = `q'*100
					
if (`qf' < 0){ 
	local rv_q = 0
	local rv_qa = 0
} 
else {
	local rv_q = .5 * (sqrt(`qf'^4 + (4 * `qf'^2)) - `qf'^2)
	local rv_qa = .5 * (sqrt(`qf2'^4 + (4 * `qf2'^2)) - `qf2'^2)
}

if ("`noreduce'" == ""){
	local adjust = `b_treat' - (`b_treat'*`q')
	local t_adjust = sign(`b_treat')*abs((`b_treat'-`adjust')/`se_treat')
}
else {
	local adjust = `b_treat' + (`b_treat'*`q')
	local t_adjust = -1*sign(`b_treat')*abs((`b_treat'-`adjust')/`se_treat')
}

// First Output Table

if (`adjust' == 0){
	mata:  printf("\n{space 59}{txt} DOF    =   %5.0f \n{space 59} q      =    %3.2f \n{space 59} alpha  =    %3.2f \n{space 59} reduce =   %5s\n{space 59} H0     =       0\n",`dof',`q',`alpha',"`reduce_t'")
} 
else {
	if (`adjust' < 0){
		local spacer = 0
	}
	else {
		local spacer = 1
	}
	mata:  printf("\n{space 59}{txt} DOF    =   %5.0f \n{space 59} q      =    %3.2f \n{space 59} alpha  =    %3.2f \n{space 59} reduce =   %5s\n{space 59} H0     =  {space `spacer'}%4.3f\n",`dof',`q',`alpha',"`reduce_t'",`adjust')
}
mata:  printf("\n{txt} Treatment{space 5} {c |} {space 4}Coef.{space 5} S.E.{space 6}t(H0){space 4}R2yd.x{space 5}RV_q{space 4}RV_qa\n")
mata:  printf("{hline 16}{c +}{hline 59}\n")
mata:  printf("{txt}%15s {c |}  {res}%8.4f  %8.4f   %8.4f  %8.4f %8.4f %8.4f\n\n",substr("`treat'",1,15),`b_treat',`se_treat',`t_adjust',`r2yd_x',`rv_q',`rv_qa')

// Verbose Description
if ("`suppress'" == ""){
	mata: printf("{txt} Partial R2 of the treatment with the outcome (R2yd.x): \n An extreme confounder (orthogonal to the covariates) that explains 100 percent of the \n residual variance of the outcome, would need to explain at least %3.2f percent of the \n residual variance of the treatment to fully account for the observed estimated effect. \n \n",100*`r2yd_x')

	if (`q' == 1){
		mata: printf("{txt} Robustness Value, q = %3.2f (RV_q): \n Unobserved confounders (orthogonal to the covariates) that explain more than %4.2f percent \n of the residual variance of both the treatment and the outcome are strong enough to bring \n the point estimate to 0 (a bias of 100 percent of the original estimate). Conversely, \n unobserved confounders that do not explain more than %4.2f percent of the residual variance \n of both the treatment and the outcome are not strong enough to bring the point estimate \n to 0. \n \n",`q',100*`rv_q',100*`rv_q')
		mata: printf("{txt} Robustness Value, q = %3.2f, alpha = %3.2f (RV_qa): \n Unobserved confounders (orthogonal to the covariates) that explain more than %4.2f percent \n of the residual variance of both the treatment and the outcome are strong enough to bring \n the estimate to a range where it is no longer 'statistically different' from 0 (a bias \n of 100 percent of the original estimate), at the significance level of alpha = %3.2f. Conversely,\n unobserved confounders that do not explain more than %4.2f percent of the residual variance \n of both the treatment and the outcome are not strong enough to bring the estimate to a \n range where it is no longer 'statistically different' from 0, at the significance \n level of alpha = %3.2f \n \n",`q',`alpha',100*`rv_qa',`alpha',100*`rv_qa',`alpha')
	} 
	else {
		mata: printf("{txt} Robustness Value, q = %3.2f (RV_q): \n Unobserved confounders (orthogonal to the covariates) that explain more than %4.2f percent \n of the residual variance of both the treatment and the outcome are strong enough to bring \n the point estimate to %-8.4g (a bias of %4.0f percent of the original estimate). Conversely, \n unobserved confounders that do not explain more than %4.2f percent of the residual variance \n of both the treatment and the outcome are not strong enough to bring the point estimate \n to %8.4f. \n \n",`q',100*`rv_q',`adjust',`scale',100*`rv_q',`adjust')
		mata: printf("{txt} Robustness Value, q = %3.2f, alpha = %3.2f (RV_qa): \n Unobserved confounders (orthogonal to the covariates) that explain more than %4.2f percent \n of the residual variance of both the treatment and the outcome are strong enough to bring \n the estimate to a range where it is no longer 'statistically different' from %-8.4g (a bias \n of %4.0f percent of the original estimate), at the significance level of alpha = %3.2f. Conversely,\n unobserved confounders that do not explain more than %4.2f percent of the residual variance \n of both the treatment and the outcome are not strong enough to bring the estimate to a \n range where it is no longer 'statistically different' from %-8.4g, at the significance \n level of alpha = %3.2f \n \n",`q',`alpha',100*`rv_qa',`adjust',`scale',`alpha',100*`rv_qa',`adjust',`alpha')
	}
}

// Benchmark

if("`benchmark'"!="" | "`gbenchmark'"!=""){

// Store benchmarks in mata and resize output tables
	local max_strl = 15
	local bench_master = 0

	if("`benchmark'"!=""){
		mata: benchm = J(1,2,"")
		foreach bench of local benchmark {
			local bench_master = `bench_master' + 1
			mata: benchc = ("`bench'",  "single")
			mata: benchm = (benchm \ benchc)
		}
		mata: benchm = benchm[(2::rows(benchm)),.]

		if ("`gbenchmark'"!=""){
			if ("`gname'" == ""){
				mata: benchc = ("`gbenchmark'",  "grouped")
			}
			else {
				mata: benchc = ("`gname'",  "grouped")
			}
			mata: benchm = (benchm \ benchc)
			local bench_master = `bench_master' + 1
		}		
	} 
	else {
		if ("`gbenchmark'"!=""){
			if ("`gname'" == ""){
				mata: benchm = ("`gbenchmark'",  "grouped")
			}
			else {
				mata: benchm = ("`gname'",  "grouped")
			}
			local bench_master = `bench_master' + 1
		}	
	}	
		
	local spacer_a= 1  + (`max_strl')
	local spacer_b= 8  + (`max_strl')
	local spacer_c= 4  + (`spacer_a')
	local spacer_d= 4  + (`spacer_b')
	
	// Main bounds table
	mata:  printf("{txt} Bounds on Omitted Variable Bias: \n")
	if ("`suppress'"==""){
		mata: printf("{txt} The table shows the maximum strength of unobserved confounders, bounded by a multiple of the \n observed explanatory power of the chosen benchmark covariate(s) with the treatment and the outcome.\n\n")
	}
	if (`custom_ky' == 1){
		mata:  printf("{txt} Bound {space `spacer_c'}{c |}{space 3}R2dz.x{space 3}R2yz.dx{space 5}Coef.{space 6}S.E.{space 5}t(H0){space 2}Lower CI{space 1}Upper CI \n{hline `spacer_d'}{c +}{hline 70}\n")
	} 
	else {
		mata:  printf("{txt} Bound {space `spacer_a'}{c |}{space 3}R2dz.x{space 3}R2yz.dx{space 5}Coef.{space 6}S.E.{space 5}t(H0){space 2}Lower CI{space 1}Upper CI \n{hline `spacer_b'}{c +}{hline 70}\n")
	}
	global lim_ub = `lim_ub'

///////
// Bounds

	// Initial regressions
	qui:reg `depvar' `regs' if `touse', noheader notable
	estimates store main_model
	local regs_treat: list regs - treat
	qui:reg `treat' `regs_treat' if `touse', noheader notable
	estimates store treat_model

	local bench_count = 1
	forvalues i = 1(1)`bench_master'{

			mata: st_local("bench",benchm[`i',1])
			mata: st_local("bench_type",benchm[`i',2])
			
			if ("`bench_type'" == "grouped"){
				if ("`gname'" == ""){
					local bench_name = substr(subinstr("`bench'"," ","-",.),1,15)
				}
				else {
					local bench = "`gbenchmark'"
					local bench_name = "`gname'"
				}
			}
			else {
				local bench_name = "`bench'" 
			}
		
			if ("`bench_type'" =="single" & (strpos("`bench'",".")==0)){
				qui: estimates restore main_model
				local bench_to =  _b[`bench']/_se[`bench']
				local r2yxj_x = `bench_to'*`bench_to' / (`bench_to'*`bench_to' + `dof')

				qui: estimates restore treat_model
				local dof_b = e(df_r)
				local bench_t =  _b[`bench']/_se[`bench']
				local r2dxj_x = `bench_t'*`bench_t' / (`bench_t'*`bench_t' + `dof_b')
			}
			else {
				qui: estimates restore main_model
				local rss_all = e(rss)
				local regs_bench: list regs - bench
				qui:reg `depvar' `regs_bench' if `touse', noheader notable
				local rss_omit = e(rss)
				local r2yxj_x = (`rss_omit'-`rss_all')/`rss_omit'
				
				qui: estimates restore treat_model
				local rss_all = e(rss)
				local regs4: list regs_treat - bench
				qui:reg `treat' `regs4' if `touse', noheader notable
				local rss_omit = e(rss)
				local r2dxj_x = (`rss_omit'-`rss_all')/`rss_omit'
			}
			
			local mkd: subinstr local kd " " ", ", all	
			local mky: subinstr local ky " " ", ", all
			
			local mr2yz: subinstr local mbounds " " ", ", all
		
			if (`bench_count'>1){
				mat oldbench = benchmarks
				mat oldextreme = extreme
			}
			
			mata: iterate_bounds((`mkd'), (`mky'),`r2dxj_x',`r2yxj_x',`dof',`se_treat',`b_treat',`reduce',`alpha',`adjust',"`bench_name'",`custom_ky',(`mr2yz'))

			local bench2 = subinstr("`bench_name'",".","_",.)

			mat rownames benchmarks = `bench2'
			mat rownames extreme = `bench2'

			if (`bench_count'>1){
				mat benchmarks = oldbench\benchmarks
				mat extreme = oldextreme\extreme
			}
			local bench_count = `bench_count' + 1

	}

	ereturn post, esample(`touse')

	/// Extreme bounds
	local spacer_a= (`max_strl'-6)
	mata: printf("\n\n{txt} Extreme Bound{space `spacer_a'}{c |}{space 3}R2dz.x{space 3}R2yz.dx{space 5}Coef.\n{hline `spacer_b'}{c +}{hline 30} \n")
	mata: extreme_bounds(`custom_ky')
	
}
	
if("`benchmark'"!="" | "`gbenchmark'"!="" ){
	capture: graph drop s_contourplot 
	capture: graph drop s_tcontourplot 
	capture: graph drop s_extremeplot

	/// Contourplot
	if ("`contourplot'" != ""){
		mata: contour_plot(`b_treat',`se_treat',`dof',`lim_lb',$lim_ub,`reduce',`clines',`adjust',0,`adjust')
		matrix colnames contourgrid = "x" "y" "z"
		ereturn matrix contourgrid = contourgrid
		s_contourplot `b_treat' `se_treat' `adjust' `clines' `reduce'  `custom_ky'  0 `adjust'
	}

	/// t-Contourplot
	if ("`tcontourplot'" != ""){
		if (`reduce'==0){
			local adjust2 = -1*sign(`b_treat')*(abs( invt(`dof'-1, (`alpha'/2))))
		}
		else {
			local adjust2 = sign(`b_treat')*(abs( invt(`dof'-1, (`alpha'/2))))
		}
		mata: contour_plot(`b_treat',`se_treat',`dof',`lim_lb',$lim_ub,`reduce',`clines',`adjust',1,`adjust2')
		mat contourgrid2 = contourgrid
		matrix colnames contourgrid2 = "x" "y" "z"
		ereturn matrix tcontourgrid = contourgrid2
		
		s_contourplot `b_treat' `se_treat' `adjust' `clines' `reduce'  `custom_ky'  1 `adjust2'
		
	}
}

if ("`extremeplot'" != ""){

	preserve
	
	if ("`r2yz'"!=""){
		local mlines: subinstr local mbounds " " ", ", all
	}
	else {
		local mlines = "1,.75,.5"
	}
	
	// Set bounds and initialize plot
	if ("`elim'"=="" & "`benchmark'"!=""){
		if (((`r2dxj_x'/(1 - `r2dxj_x'))  + .1) < `elim_ub'){
			local elim_ub = `r2dxj_x'/(1 - `r2dxj_x')  + .1
		}
		mata: extreme_plot(`b_treat',`se_treat',`dof',`elim_lb',`elim_ub',`reduce',`adjust',0,(`mlines'))
	} 
	else {
		mata: extreme_plot(`b_treat',`se_treat',`dof',`elim_lb',`elim_ub',`reduce',`adjust',1,(`mlines'))
	}

	local dim = colsof(s_extremeplot)	
	svmat s_extremeplot, names("sense_ep_") 

	if ("`r2yz'" == ""){
		local legend = `"1 "100%" 2 "75%" 3 "50%""'
	}
	else {
			capture: local lab1 : di %4.1f s_extremelabels[1,1]
			capture: local lab2 : di %4.1f s_extremelabels[1,2]		
			capture: local lab3 : di %4.1f s_extremelabels[1,3]
			capture: local lab4 : di %4.1f s_extremelabels[1,4]
				
			if (`dim' == 2){
				local legend = `"1 "`lab1'%""'
			}
			if (`dim' == 3){
				local legend = `"1 "`lab1'%"  2 "`lab2'%""'
			}
			if (`dim' == 4){
				local legend = `"1 "`lab1'%" 2 "`lab2'%" 3 "`lab3'%""'
			}
			if (`dim' == 5){
				local legend = `"1 "`lab1'%" 2 "`lab2'%" 3 "`lab3'%" 4 "`lab4'%""'
			}			
	}
		
	
	if("`benchmark'"!="" |  "`gbenchmark'"!=""){
		// Extract rug
		mat tempvals = benchmarks[1...,3..3]
		svmat tempvals, names(benchval)
		
		capture: graph close _all
		// Plot
		line sense_ep_2 sense_ep_1, nodraw name(s_extremeplot ,replace)  ///
		yline(`adjust',lpattern(dash) lcolor(red)) xlab(,labsize(small)) ylab(,labsize(small)) ///
		xtitle(Partial R{superscript:2} of confounder(s) with the treatment,size(small)) ytitle(Adjusted Effect Estimate,size(small)) lcolor(black) legend(off) ///
		|| hist benchval, frequency discrete width(.0005) bcolor(black) fcolor(black) yaxis(2) ///
		 ylabel(0 " " 20 " " 40 " " 60 " " 80 " " 100 " ", nolab labcolor() axis(2) tlcolor(black) tlwidth(thin) labsize(tiny) tl(0))  ytitle(" ",axis(2)) yscale(alt lstyle(none) lcolor() axis(2)) 
		 
		} 
		else { 
		// Plot
		line sense_ep_2 sense_ep_1, nodraw name(s_extremeplot ,replace)  ///
		yline(`adjust',lpattern(dash) lcolor(red)) xlab(,labsize(small)) ylab(,labsize(small)) ///
		xtitle(Partial R{superscript:2} of confounder(s) with the treatment,size(small)) ytitle(Adjusted Effect Estimate,size(small)) lcolor(black) legend(off) 
		}
	
		if (`dim' > 2){
			 forvalues i = 3(1)`dim' {
				if (`i' == 3){
					addplot_m: line sense_ep_`i' sense_ep_1, lpattern(dash) lcolor(black)
				}
				if (`i' == 4){
					addplot_m: line sense_ep_`i' sense_ep_1, lpattern(dash_dot) lcolor(black)
				}
				if (`i' == 5){
					addplot_m: line sense_ep_`i' sense_ep_1, lpattern(dot) lcolor(black)
				}
			 }
		 }
		 addplot_m: line sense_ep_2 sense_ep_1, lcolor(black) legend(on size(small) lcolor(black) rows(1) subtitle("Partial R{superscript:2} of confounder(s) with the outcome",size(small)) order (`legend'))

 
	capture: drop sense_ep_* benchval	
	capture: mat drop s_extremeplot	
	restore
}

capture: graph display s_contourplot
capture: graph display s_tcontourplot	
capture: graph display s_extremeplot

// Clean up
capture: macro drop lim_ub user_clim kd_count

// E()
if("`benchmark'"!="" | "`gbenchmark'"!=""){
	matrix colnames benchmarks = "kd" "ky" "r2dz_x" "r2yz_dx" "adjusted_e" "adjusted_se" "adjusted_t" "lower_CI" "upper_CI"
	matrix colnames extreme = "kd" "ky" "r2dz_x" "r2yz_dx" "adjusted_e" 
	
	ereturn matrix bounds = benchmarks
	ereturn matrix extreme = extreme
} 
else {
	ereturn post, esample(`touse')
}
ereturn local outcome = "`depvar'"
ereturn local treatment = "`treat'"

if ("`gbenchmark'"!=""){
	ereturn local gbench = "`gbenchmark'"
}
if ("`benchmark'"!=""){
	ereturn local bench = "`benchmark'"
}
ereturn scalar treat_coef = `b_treat'
ereturn scalar treat_se = `se_treat'
ereturn scalar r2yd_x = `r2yd_x'
ereturn scalar rv_q = `rv_q'
ereturn scalar rv_qa = `rv_qa'
ereturn scalar rv_critical = `adjust'
ereturn scalar q = `q'
ereturn scalar dof = `dof'
ereturn scalar alpha = `alpha'

// Latex export

if ("`latex'" != ""){
	capture: file close sense_texfile 
	file open sense_texfile using "`latex'.tex", write replace

		local round_treat = round(`e(treat_coef)',.001)
		local round_se = round(`e(treat_se)',.001)
		local round_t = round(`t_adjust',.001)
		local round_r2yd_x = round(100*`e(r2yd_x)',.01)
		local round_rv_q = round(100*`e(rv_q)',.01)
		local round_rv_qa = round(100*`e(rv_qa)',.01)
		local dim = rowsof(e(bounds))	
		local round_adjust = round(`adjust',.01)
		
		file write sense_texfile  "\begin{table} \centering " _n
		file write sense_texfile  "\begin{tabular}{lrrrrrr} " _n
		file write sense_texfile  "\multicolumn{7}{c}{Outcome: \textit{`e(outcome)'}} \\ \hline \hline " _n
		file write sense_texfile  "Treatment: & Est. & S.E. & t(H0=`round_adjust') & \$R^2_{Y \sim D |{\bf X}}\$ & \$RV_{q = `e(q)'}\$ & \$RV_{q = `e(q)', \alpha = `e(alpha)'}\$ \\ \hline" _n
		file write sense_texfile  "\textit{`e(treatment)'} & `round_treat' &  `round_se' & `round_t' & `round_r2yd_x'\% & `round_rv_q' \% & `round_rv_qa'\% \\ " _n
		file write sense_texfile  "\hline df = `e(dof)' " _n
		
		forvalues  i = 1(1)`dim' {
			mat benchmarks = e(bounds)
			local temp = round(100*benchmarks[`i',3],.01)
			local temp2 = round(100*benchmarks[`i',4],.01)
			local kdlabel = benchmarks[`i',1]
			local kylabel = benchmarks[`i',2]

			file write sense_texfile  "& \multicolumn{6}{r}{ \small \textit{Bound (`kdlabel'/`kylabel'x female)}: \$R^2_{Y\sim Z| {\bf X}, D}\$ = `temp2'\%, \$R^2_{D\sim Z| {\bf X} }\$ = `temp'\%} \\" _n
		
		}
		mat drop benchmarks
		
		file write sense_texfile  "\end{tabular}"	  _n
		file write sense_texfile  "\caption{Minimal sensitivity analysis reporting.} "  _n
		file write sense_texfile  "\label{tab:minimal} "  _n
		file write sense_texfile  "\end{table}" _n
	file close sense_texfile 
	di as smcl `"Click to Open File:  {browse `latex'.tex}"'
}
	

end

program s_contourplot 
version 13
	args b_treat se_treat adjust clines reduce custom_ky tplot thresh

	capture: graph close _all
	
	if (`tplot' == 1){
		local label = q_pos[1,1]+.001
		local round_adjust : di %6.2f `thresh'	
		if (`reduce'==0){
			local round_e = -1*sign(`b_treat')*abs(round((`b_treat'-`adjust')/`se_treat',.01))
		}
		else {
			local round_e = sign(`b_treat')*abs(round((`b_treat'-`adjust')/`se_treat',.01))
		}
		local plotname = "s_tcontourplot"
		local gap = abs((toprange[2,3] - toprange[1,3])/3) 
		local round_e : di %5.2f `round_e'
	} 
	else {
		local label = q_pos[1,1]+abs((toprange[2,3] - toprange[1,3])/6) 
		local round_adjust : di %6.2f `adjust'
		local round_e : di %6.3f `b_treat'
		local plotname = "s_contourplot"
		local gap = abs((toprange[2,2] - toprange[1,2])/4) 
	}
	
	twoway contourline sense_contour_z sense_contour_y sense_contour_x if sense_contour_z!=.,  ///
				name(`plotname',replace) ccuts(`thresh') ccolor(red) nodraw xlab(,labsize(small)) ylab(,labsize(small)) ///
				ytitle(Partial R{superscript:2} of confounder(s) with the outcome, size(small)) xtitle(Partial R{superscript:2} of confounder(s) with the treatment, size(small)) ///
				 text(`label' `label'  "`round_adjust'", size(vsmall) bcolor(white) box place(ne)) ///
				|| scatteri 0 0 "Unadjusted (`round_e')",legend(off) mlabsize(vsmall) msize(vsmall) mcolor(black) 

	local lb = `thresh'  - `gap' 
	local ub = `thresh'  + `gap' 
	
	forvalues i = 1(1)`clines'{
		local cutvalue = round(toprange[`i',3],.0001)
		local cutvalue_round :   di %6.2f toprange[`i',3]
		local cut_x = toprange[`i',2]+.001
		
			if (((`cutvalue' > `lb') & (`cutvalue' < `ub'))){
			}
			else {
				addplot_m: contourline sense_contour_z sense_contour_y sense_contour_x if sense_contour_z!=., ccuts(`cutvalue') ccolor(gray) clwidths(vthin) text(`cut_x' `cut_x'  "`cutvalue_round'", size(vsmall) bcolor(white) box place(ne))
			}
	}
	
	// Add points	
			local dim = rowsof(benchmarks)	
			local rownms: rown benchmarks

			forvalues index= 1(1)`dim'{
			
				mata: st_local("bench_name",tokens(st_local("rownms"))[`index'])
		
				local r2yz_value = benchmarks[`index',4]
				local r2dz_value = benchmarks[`index',3]
				if (`tplot' == 1){
					if (`reduce'==0){
						local coef_value = (-1*sign(benchmarks[`index',5])*abs((benchmarks[`index',5] - `adjust')/benchmarks[`index',6]))
					}
					else {
						local coef_value = (sign(benchmarks[`index',5])*abs((benchmarks[`index',5] - `adjust')/benchmarks[`index',6]))
					}
				}
				else {
					local coef_value = benchmarks[`index',5]
				}
				local kd_value = benchmarks[`index',1]
				local ky_value = benchmarks[`index',2]
				local coef_value : di %5.2f `coef_value'
				
				if (`r2yz_value' < $lim_ub){
					if (`custom_ky'==1){
						addplot_m: 	scatteri `r2yz_value'  `r2dz_value' "`kd_value'/`ky_value'x `bench_name' (`coef_value' )",mcolor(black) msize(vsmall) mlabcolor(black) mlabsize(vsmall) 
					}
					else {
						addplot_m: 	scatteri `r2yz_value'  `r2dz_value' "`kd_value'x `bench_name' (`coef_value' )",mcolor(black) msize(vsmall) mlabcolor(black) mlabsize(vsmall) 
					}
				}
			}
				
	capture: drop scalar coef_value
	capture: drop sense_contour_* 
end

program addplot_m
*! modified version of  program written by Ben Jann
    version 9
    local caller : di _caller()
    _on_colon_parse `0'
    local plots `"`s(before)'"'
    local cmd   `"`s(after)'"'
    gettoken name : plots
    capt confirm name `name'
    if _rc==0 {
        gettoken name plots : plots
    }
    else local name
    if `"`plots'"'!="" {
        numlist `"`plots'"', integer range(>=1)
        local plots `r(numlist)'
    }
    if `"`name'"'=="" {
        gr_current name :
    }
    else {
        capt classutil d `name'
    }
    if `"`plots'"'=="" {
        local grtype `"`.`name'.graphfamily'"'
        if `"`grtype'"'=="twoway" {
            version `caller': .`name'.parse `cmd'
            exit
        }
        local nplots `"`.`name'.n'"'
        capt confirm integer number `nplots'
        if _rc==0 {
            forv plot = 1/`nplots' {
                if `"`.`name'.graphs[`plot'].graphfamily'"'=="twoway" {
                    local plots `plots' `plot'
                }
            }
        }
    }
    else {
        foreach plot of local plots {
            capt classutil d `name'.graphs[`plot']
            local grtype `"`.`name'.graphs[`plot'].graphfamily'"'
        }
    }
    foreach plot of local plots {
        version `caller': .`name'.graphs[`plot'].parse `cmd'
    }

end


version 13
mata:
mata clear
mata set matastrict on
mata set matafavor speed

real scalar adjusted_estimate(estimate, se, dof, r2yz_dx, r2dz_x,reduce){ 
	real scalar bias,adjusted_e
	bias = sqrt(r2yz_dx * r2dz_x / (1 - r2dz_x)) * se * sqrt(dof)

	if (reduce == 1){
		adjusted_e = (sign(estimate)*(abs(estimate) - bias))
	} else {
		adjusted_e = (sign(estimate)*(abs(estimate) + bias))
	}
	return (adjusted_e)
}


real scalar adjusted_t(estimate, se, dof, r2yz_dx, r2dz_x,reduce,h0){ 
	real scalar bias,adjusted_e,adjusted_se
	bias = sqrt(r2yz_dx * r2dz_x / (1 - r2dz_x)) * se * sqrt(dof)

	if (reduce == 1){
		adjusted_e = (sign(estimate)*(abs(estimate) - bias))
		adjusted_se =sqrt((1 - r2yz_dx) / (1 - r2dz_x)) * se * sqrt(dof / (dof - 1))
		
		return (sign(adjusted_e)*abs((adjusted_e - h0)/adjusted_se))
		
	} else {
		adjusted_e = (sign(estimate)*(abs(estimate) + bias))
		adjusted_se =sqrt((1 - r2yz_dx) / (1 - r2dz_x)) * se * sqrt(dof / (dof - 1))
		
		if (adjusted_e < 0){
			return (-1*sign(adjusted_e)*((adjusted_e - h0)/adjusted_se))
		} else {
			return (sign(adjusted_e)*((adjusted_e - h0)/adjusted_se))
		}
	}
}


void recursive_extreme_limits(estimate, se, dof, param, lim_ub, reduce, crit){

	if (reduce==1){
		if (adjusted_estimate(estimate,se,dof,param,lim_ub,reduce) > crit & lim_ub <1){
			 lim_ub = lim_ub + .1
			 (void) recursive_extreme_limits(estimate, se, dof, param, lim_ub, reduce, crit)
		} 
	} else {
		if (adjusted_estimate(estimate,se,dof,param,lim_ub,reduce) < crit & lim_ub < 1){
			 lim_ub = lim_ub + .1
			 (void) recursive_extreme_limits(estimate, se, dof, param, lim_ub, reduce, crit)
		} 	
	}
}

void iterate_bounds(real vector kd,real vector ky,r2dxj_x,r2yxj_x,dof,se_treat,b_treat,reduce,alpha,h0,bench,custom_ky,real vector ebounds){
	real scalar i, j, k, r2dz_x, r2zxj_xd, r2yz_dx, bf,bias, adjusted_e,adjusted_se,upper_CI,lower_CI,user_clim,lim_ub,adjusted_t
	real matrix benchmarks, extreme
	
	benchmarks = J(length(kd),9,.)
	extreme = J(length(kd)*length(ebounds),5,.)
	k = 1
	
	for(i=1;i<=length(kd);i=i+1){

		r2dz_x = kd[i]*(r2dxj_x/(1 - r2dxj_x))
		
		if (r2dz_x > 1){
			 _error("Impossible value. Try a lower kd and/or ky")
		}
		
		r2zxj_xd = kd[i]*(r2dxj_x^2)/((1 - kd[i] * r2dxj_x) * (1 - r2dxj_x))
		
		if (r2zxj_xd > 1){
			 _error("Impossible value. Try a lower kd and/or ky")
		}
		r2yz_dx =  ((sqrt(ky[i]) + sqrt(r2zxj_xd)) / sqrt(1 - r2zxj_xd))^2 * (r2yxj_x/ (1 - r2yxj_x))   	
		bf = sqrt(r2yz_dx * r2dz_x / (1 - r2dz_x))
		bias = bf * se_treat * sqrt(dof)
		
		if (reduce==0){
			adjusted_e = sign(b_treat)*(abs(b_treat) + bias)
		}
		else {
			adjusted_e = sign(b_treat)*(abs(b_treat) - bias)
		}
		adjusted_se =sqrt((1 - r2yz_dx) / (1 - r2dz_x)) * se_treat * sqrt(dof / (dof - 1))	 
		
		if (adjusted_se == .){
			 _error("Implied bound on r2yz_dx greater than 1, try a lower kd and/or ky")
		}
		adjusted_t = (adjusted_e - h0) / adjusted_se
		
		upper_CI = adjusted_e + invt(dof-1,(1-(alpha/2)))*adjusted_se
		lower_CI = adjusted_e - invt(dof-1,(1-(alpha/2)))*adjusted_se
		
		benchmarks[i,1] = kd[i]
		benchmarks[i,2] = ky[i]
		benchmarks[i,3] = r2dz_x
		benchmarks[i,4] = r2yz_dx
		benchmarks[i,5] = adjusted_e
		benchmarks[i,6] = adjusted_se
		benchmarks[i,7] = adjusted_t
		benchmarks[i,8] = lower_CI
		benchmarks[i,9] = upper_CI
		
		if (custom_ky!=1){
			printf("{txt}%5.2fx %15s {c |}{res} %8.4f  %8.4f  %8.4f  %8.4f  %8.4f  %8.4f %8.4f \n",kd[i],substr(bench,1,15),r2dz_x,r2yz_dx,adjusted_e,adjusted_se,adjusted_t,lower_CI,upper_CI)
		} else {
			printf("{txt}%3.2f/%3.2fx %15s {c |}{res} %8.4f  %8.4f  %8.4f  %8.4f  %8.4f  %8.4f %8.4f \n",kd[i],ky[i],substr(bench,1,15),r2dz_x,r2yz_dx,adjusted_e,adjusted_se,adjusted_e/adjusted_se,lower_CI,upper_CI)
		}
		lim_ub = strtoreal(st_global("lim_ub"))
		user_clim = strtoreal(st_global("user_clim"))
	
		// Set limits for contourplot 
		if (user_clim == 0){
				if ((r2dz_x + .1) > lim_ub){
					(void) st_global("lim_ub",strofreal(r2dz_x + .1)) 
				}  
				else if ((r2yz_dx + .05) > lim_ub){
					(void) st_global("lim_ub",strofreal(r2yz_dx + ((r2yz_dx+.05)-lim_ub)))
				}
		} 
		
		for(j=1;j<=length(ebounds);j=j+1){
			// Calculate extreme bounds and save in separate matrix
			extreme[k,1] = kd[i]
			extreme[k,2] = ky[i]
			extreme[k,3] = r2dz_x
			extreme[k,4] = ebounds[j]
			
			if (reduce==0){
				adjusted_e = sign(b_treat)*(abs(b_treat) + (sqrt(extreme[k,4] * r2dz_x / (1 - r2dz_x)) * se_treat * sqrt(dof)))
			}
			else {
				adjusted_e = sign(b_treat)*(abs(b_treat) - (sqrt(extreme[k,4] * r2dz_x / (1 - r2dz_x)) * se_treat * sqrt(dof)))
			}
			
			extreme[k,5] = adjusted_e
			k = k +1
		}	
	}
	(void) st_matrix("extreme",extreme)
	(void) st_matrix("benchmarks",benchmarks)
}

void extreme_bounds(custom_ky){
	real scalar i,j
	real matrix extreme
	string matrix benchmarks, benchmark_single
	
	benchmarks = st_matrixrowstripe("benchmarks")
	for (i=1; i<=rows(benchmarks); i=i+1){  
		if(i==1){
			benchmark_single = J(1,1,benchmarks[i,2])
		} else {
			if (benchmarks[i,2] != benchmarks[i-1,2]){
				benchmark_single = (benchmark_single \ benchmarks[i,2])
			}
		}
	}
	
	extreme = st_matrix("extreme")

	j = 1
	for (i=1; i<=rows(extreme); i=i+1){ 
		if(extreme[i,1] == extreme[1,1] & extreme[i,2] == extreme[1,2] & extreme[i,4]==extreme[1,4] & i!=1){
			j = j +1
		}
	
	printf("{txt}%5.2fx %15s {c |}{res} %8.4f{space 2}%8.4f{space 2}%8.4f \n",extreme[i,1],substr(benchmark_single[j,1],1,15),extreme[i,3],extreme[i,4],extreme[i,5])

	}	
}


void extreme_plot(estimate, se, dof, lim_lb,lim_ub,reduce,crit, userlim, real vector r2yz){
	real matrix params, output, Y
	real scalar k, i, j, n_outputs
	real colvector limits

	n_outputs = length(r2yz) + 1
	
	
	if (userlim==0){
		(void) recursive_extreme_limits(estimate, se, dof, .45, lim_ub, reduce, crit)
	}
	limits = length(range(lim_lb, lim_ub, .001))
	
	(void) st_addobs(limits)
	output = J(limits,n_outputs,.)
	k = 1

	for (i=lim_lb; i<=lim_ub; i=i+.001){ 
	   output[k,1] = i 
	   for (j=2; j<=n_outputs; j=j+1){
		  output[k,j] = adjusted_estimate(estimate,se,dof,r2yz[1,j-1],i,reduce)
	   }
	   k = k + 1
	}	
	
	r2yz = r2yz*100

	(void) st_matrix("s_extremeplot",output)
	(void) st_matrix("s_extremelabels",r2yz)
}


void contour_plot(estimate,se,dof,lim_lb,lim_ub,reduce,clines,critical,tplot,thresh){
	real colvector grid_values, grid_values_cuts 
	real scalar i,j,grid_length, z
	real matrix contourGrid,cuts
	
	// Create contour grid
	grid_values = range(lim_lb, lim_ub, lim_ub/50)
	grid_length = length(grid_values)
	
	(void) st_addobs(grid_length*grid_length)
	
	contourGrid=J(grid_length*grid_length,3,.)

	z = 1
	for (i=1; i<=grid_length; i++){
		for (j=grid_length; j>=1; j--){
				contourGrid[z,1] = grid_values[i]
				contourGrid[z,2] = grid_values[j]
				if (tplot==1){
					contourGrid[z,3] = adjusted_t(estimate,se,dof,grid_values[j],grid_values[i],reduce,critical)
				} else {
					contourGrid[z,3] = adjusted_estimate(estimate,se,dof,grid_values[j],grid_values[i],reduce)
				}
				z = z+1
		}
	}

	(void) st_addvar("double","sense_contour_x")
	(void) st_addvar("double","sense_contour_y")
	(void) st_addvar("double","sense_contour_z")
	
	for (i=1; i<=(grid_length*grid_length); i++){
		st_store(i,"sense_contour_x",contourGrid[i,1])
		st_store(i,"sense_contour_y",contourGrid[i,2])
		st_store(i,"sense_contour_z",contourGrid[i,3])
	}	

	(void) st_matrix("contourgrid",contourGrid)
	
	// Cuts and labels
	grid_values_cuts = rangen(lim_lb + ((lim_ub-lim_lb)*.05), lim_ub*.95, clines)
	cuts=J(clines,3,.)
	for (i=1; i<=clines; i++){
		cuts[i,1] = grid_values_cuts[i]
		cuts[i,2] = grid_values_cuts[i]
		if (tplot==1){
			cuts[i,3] = adjusted_t(estimate,se,dof,grid_values_cuts[i],grid_values_cuts[i],reduce,critical)
		} else {
			cuts[i,3] = adjusted_estimate(estimate,se,dof,grid_values_cuts[i],grid_values_cuts[i],reduce)
		}
	}

	(void) st_matrix("toprange",cuts)	

	// Find q label position along diagonal
	contourGrid=J(grid_length,3,.)
	for (i=1; i<=grid_length; i++){
		contourGrid[i,1] = grid_values[i]
		contourGrid[i,2] = grid_values[i]

		if (tplot==1){
			contourGrid[i,3] = abs(adjusted_t(estimate,se,dof,grid_values[i],grid_values[i],reduce,critical)-thresh)
		} else {
			contourGrid[i,3] = abs(adjusted_estimate(estimate,se,dof,grid_values[i],grid_values[i],reduce) - critical)
		}
	}
	(void) st_matrix("q_pos",select(contourGrid,contourGrid[,3]:==min(contourGrid[,3])))
}


end
