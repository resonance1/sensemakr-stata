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
{synopt:{opt kd(numlist)}}specify strength of confounder relative to treatment. Defaults to (1 2 3) {p_end}
{synopt:{opt ky(numlist)}}specify strength of confounder relative to  outcome. Defaults to kd. ky and kd must be the same length{p_end}
{synopt:{opt noreduce}}assume that confounders increase the estimate, rather than reduce the estimate{p_end}
{synopt:{opt q(real)}}specify what fraction of the effect estimate would have to be explained away to be problematic. {p_end}
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

    Load example data
{p 4 8 2}{stata "use darfur.dta, clear":. use darfur.dta, clear}{p_end}

    {stata sensemakr peacefactor directlyharmed age farmer_dar herder_dar pastvoted hhsize_darfur female i.village_factor, treat(directlyharmed) benchmark(female): Basic Syntax}

    {stata sensemakr peacefactor directlyharmed age farmer_dar herder_dar pastvoted hhsize_darfur female i.village_factor, treat(directlyharmed) benchmark(female) contourplot tcontourplot extremeplot: Basic Graphing}

    {stata sensemakr peacefactor directlyharmed age farmer_dar herder_dar pastvoted hhsize_darfur female i.village_factor, treat(directlyharmed) benchmark(female) gbenchmark(age farmer_dar herder_dar pastvoted hhsize_darfur female) gname(all): Combining individual and grouped benchmarks}

    {stata sensemakr peacefactor directlyharmed age farmer_dar herder_dar pastvoted hhsize_darfur female i.village_factor, treat(directlyharmed) benchmark(pastvoted female) kd(4 5) ky(3 3): Altering default bounds}

{title:Saved results}

{p 4 8 2}
By default, {cmd:sensemakr}  ereturns the following results, which can be displayed by typing {cmd: ereturn list} after
{cmd:sensemakr} is finished.

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(treat_coef)}}  the original treatment coefficient{p_end}
{synopt:{cmd:e(r2yd_x)}}  r2yd.x{p_end}
{synopt:{cmd:e(rv_q)}}  the robustness value given q{p_end}
{synopt:{cmd:e(rv_qa)}}  the robustness value given q and alpha{p_end}
{synopt:{cmd:e(rv_critical)}} the null hypothesis{p_end}
{synopt:{cmd:e(q)}} the value of q {p_end}
{synopt:{cmd:e(dof)}} degrees of freedom{p_end}
{synopt:{cmd:e(alpha)}} the significance level{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:e(bench)}}  a list of benchmark variables {p_end}
{synopt:{cmd:e(gbench)}}  a list of variables included in the group benchmark {p_end}
{synopt:{cmd:e(treatment)}}  the treatment variable{p_end}
{synopt:{cmd:e(outcome)}}  the dependent variables{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd: e(bounds)}} bounds table in matrix form {p_end}
{synopt:{cmd: e(extreme)}} extreme bounds table in matrix form {p_end}
{synopt:{cmd: e(contourgrid)}} matrix of values used to construct contour plots {p_end}

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
