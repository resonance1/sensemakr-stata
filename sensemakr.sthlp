{smcl}
{* *! version 1.0 16april2020}

{cmd:help sensemakr}
{hline}

{title:Title}

{p2colset 5 15 22 2}{...}
{p2col :{hi:sensemakr} {hline 2} sensitivity tools for OLS}{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 18 2}
{cmdab:sensemakr} [{it:{help varname:depvar}}] {it:{help varlist:covar}}
{ifin}
[{cmd:,}
treatment({help varlist:treatvar}) {it:options}]

{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Main}
{synopt:{opt benchmark(varlist)}}specify a list of benchmark covariates{p_end}
{synopt:{opt gbenchmark(varlist)}}specify a list of covariates to be used to construct a grouped benchmark{p_end}
{synopt:{opt gname(string)}}specify a custom name for the grouped benchmark{p_end}
{synopt:{opt suppress}}suppress verbose description of sensitivity statistics{p_end}
{synopt:{opt latex(filename)}}save minimal reporting statistics in a named latex file{p_end}

{syntab:Graphing}
{synopt:{opt contourplot}}generates a contour plot for the estimate{p_end}
{synopt:{opt tcontourplot}}generates a contour plot for t(H0) {p_end}
{synopt:{opt extremeplot}}generates an extreme scenario plot {p_end}
{synopt:{opt clines(real)}}sets the number of contour lines to draw on contour plots{p_end}
{synopt:{opt clim(numlist)}}sets the upper and lower limits of the x- and y- axes on contour plots{p_end}
{synopt:{opt elim(numlist)}}sets the upper and lower limits of the x-axis on the extreme scenario plot{p_end}

{syntab:Advanced}
{synopt:{opt alpha(real)}}the significance level. Defaults to 0.05{p_end}
{synopt:{opt kd(numlist)}}specify strength of confounder relative to benchmark in explaining the treatment. Defaults to (1 2 3) {p_end}
{synopt:{opt ky(numlist)}}specify strength of confounder  relative to benchmark in explaining the outcome. Defaults to kd. ky and kd must be the same length{p_end}
{synopt:{opt noreduce}}assume that confounders increase the estimate, rather than reduce the estimate{p_end}
{synopt:{opt q(real)}}specify what fraction of the effect estimate would have to be explained away to be problematic. Defaults to 1. {p_end}
{synopt:{opt r2yz(numlist)}}modify r2yz values for the extreme bounds table and extreme scenario plot. Maximum of 4 values. {p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
  {it:{help varlist: covar}} is a {it:{help varlist}} that may include factor variables, see {help fvvarlist}.
  {p_end}

{title:Description}

{pstd}
{opt sensemakr} implements sensitivity analysis to omitted variables, as described in Cinelli and Hazlett (2019).{p_end}

{title:Required}

{phang}
{cmd:depvar} {it:{help varname}} that specifies the dependent variable.

{phang}
{cmd:covar} {it:{help varlist}} that specifies the covariates, including the treatment variable. Unordered.

{phang}
{cmd:treatment({it:{help varname})}} designates the treatment variable (binary).

{title:Examples}

{pstd}Load example data{p_end}
{phang2}{cmd:. use darfur.dta, clear}{p_end}
{phang2}{stata "use darfur.dta, clear":Run}{p_end}

{pstd}Basic syntax{p_end}
{phang2}{cmd:. sensemakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///}{p_end}
{phang2}{cmd:.   treat(directlyharmed) benchmark(female)}{p_end}
{phang2}{stata sensemakr peacefactor directlyharmed age farmer_dar herder_dar pastvoted hhsize_darfur female i.village_factor, treat(directlyharmed) benchmark(female):Run}{p_end}

{pstd}Contour plots{p_end}
{phang2}{cmd:. sensemakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///}{p_end}
{phang2}{cmd:.   treat(directlyharmed) benchmark(female) contourplot tcontourplot}{p_end}
{phang2}{stata sensemakr peacefactor directlyharmed age farmer_dar herder_dar pastvoted hhsize_darfur female i.village_factor, treat(directlyharmed) benchmark(female) contourplot tcontourplot:Run}{p_end}

{pstd}Extreme scenario plot{p_end}
{phang2}{cmd:. sensemakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///}{p_end}
{phang2}{cmd:.   treat(directlyharmed) benchmark(female) extremeplot}{p_end}
{phang2}{stata sensemakr peacefactor directlyharmed age farmer_dar herder_dar pastvoted hhsize_darfur female i.village_factor, treat(directlyharmed) benchmark(female) extremeplot:Run}{p_end}

{pstd}Changing extreme scenarios{p_end}
{phang2}{cmd:. sensemakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///}{p_end}
{phang2}{cmd:.   treat(directlyharmed) benchmark(female) r2yz(.5 .6 .7 .8) extremeplot}{p_end}
{phang2}{stata sensemakr peacefactor directlyharmed age farmer_dar herder_dar pastvoted hhsize_darfur female i.village_factor, treat(directlyharmed) benchmark(female) r2yz(.5 .6 .7 .8) extremeplot:Run}{p_end}

{pstd}Grouped benchmarks{p_end}
{phang2}{cmd:. sensemakr peacefactor directlyharmed age far herder pastv hhsize female i.village_f, ///}{p_end}
{phang2}{cmd:.   treat(directlyharmed) gbenchmark(age farmer herder pastv hhsize female) gname(all)}{p_end}
{phang2}{stata sensemakr peacefactor directlyharmed age far herder pastv hhsize female i.village_f, treat(directlyharmed) gbenchmark(age farmer herder pastvoted hhsize female) gname(all):Run}{p_end}

{pstd}Altering default bounds{p_end}
{phang2}{cmd:. sensemakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, ///}{p_end}
{phang2}{cmd:.   treat(directlyharmed) benchmark(pastv female) kd(4 5) ky(1 1)}{p_end}
{phang2}{stata sensemakr peacefactor directlyharmed age farmer herder pastv hhsize female i.village_f, treat(directlyharmed) benchmark(pastv female) kd(4 5) ky(1 1):Run}{p_end}

{title:Saved results}

{p 4 8 2}
By default, {cmd:sensemakr}  ereturns the following results, which can be displayed by typing {cmd: ereturn list} after
{cmd:sensemakr} is finished.

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(treat_coef)}}  the original treatment coefficient{p_end}
{synopt:{cmd:e(r2yd_x)}}  partial r2 of treatment with outcome{p_end}
{synopt:{cmd:e(rv_q)}}  the robustness value given q{p_end}
{synopt:{cmd:e(rv_qa)}}  the robustness value given q and alpha{p_end}
{synopt:{cmd:e(rv_critical)}} the null hypothesis (H0){p_end}
{synopt:{cmd:e(q)}} the value of q {p_end}
{synopt:{cmd:e(dof)}} degrees of freedom{p_end}
{synopt:{cmd:e(alpha)}} the significance level{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:e(bench)}}  a list of variables used as benchmarks{p_end}
{synopt:{cmd:e(gbench)}}  a list of variables included in the group benchmark {p_end}
{synopt:{cmd:e(treatment)}}  the treatment variable{p_end}
{synopt:{cmd:e(outcome)}}  the dependent variable{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd: e(bounds)}} bounds table in matrix form {p_end}
{synopt:{cmd: e(extreme)}} extreme bounds table in matrix form {p_end}
{synopt:{cmd: e(contourgrid)}} matrix of values used to construct contour plot {p_end}
{synopt:{cmd: e(tcontourgrid)}} matrix of values used to construct t-contour plot {p_end}

{title:References}

{p 4 8 2}
Cinelli, Carlos, and Chad Hazlett. "Making sense of sensitivity: Extending omitted variable bias." Journal of the Royal Statistical Society: Series B (Statistical Methodology) 82.1 (2020): 39-67.

{title:Authors}

      Carlos Cinelli
      UCLA

      Jeremy Ferwerda, jeremy.a.ferwerda@dartmouth.edu
      Dartmouth College

      Chad Hazlett
      UCLA
