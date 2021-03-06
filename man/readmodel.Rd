\name{readmodel}
\alias{readmodel}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
%%  ~~function to do ... ~~
read MOMENT model
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
create lp from lists generated from MATLAB MOMENT model.
}
\usage{
readmodel(mat, mets, rxns, rbnds, cbnds, solver = "glpkAPI")
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{mat}{
%%     ~~Describe \code{mat} here~~
contain the constraints matrix
}
  \item{mets}{
%%     ~~Describe \code{mets} here~~
list of metabolites
}
  \item{rxns}{
%%     ~~Describe \code{rxns} here~~
list of reactions and their bounds
}
  \item{rbnds}{
%%     ~~Describe \code{rbnds} here~~
bounds of rows of constraint matrix
}
  \item{cbnds}{
%%     ~~Describe \code{cbnds} here~~
bounds of columns of constraint matrix

}
  \item{solver}{
%%     ~~Describe \code{solver} here~~
solver used to solve the lp, can be glpkAPI or cplexAPI
}
}

\value{
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of 'comp1'}
%%  \item{comp2 }{Description of 'comp2'}
%% ...
return fluxes obtained using the lp.
}
\references{Adadi, R., Volkmer, B., Milo, R., Heinemann, M., & Shlomi, T. (2012). 
Prediction of Microbial Growth Rate versus Biomass Yield by a Metabolic Network 
with Kinetic Parameters, 8(7). doi:10.1371/journal.pcbi.1002575}

\author{Abdelmoneim Amer Desouki}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
\code{\link{cfba_moment}}
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or do  help(data=index)  for the standard data sets.

## The function is currently defined as
function (mat, mets, rxns, rbnds, cbnds, solver = "glpkAPI") 
{
    nr = 6705
    nc = 4991
    nf = 3234
    nm = 1674
    LHS <- Matrix::Matrix(0, nrow = nr, ncol = nc)
    for (i in c(1:length(mat[, 1]))) {
        LHS[mat[i, 1], mat[i, 2]] = mat[i, 3]
    }
    cobj = c(rxns[, "ocf"], rep(0, nc - nf))
    if (solver == "cplexAPI") {
        prob <- cplexAPI::openProbCPLEX()
        out <- cplexAPI::setIntParmCPLEX(prob$env, cplexAPI::CPX_PARAM_SCRIND, 
            cplexAPI::CPX_OFF)
        cplexAPI::chgProbNameCPLEX(prob$env, prob$lp, "Moment cplex")
        rtype <- c(rep("E", nm), rep("L", nr - nm))
        cplexAPI::setObjDirCPLEX(prob$env, prob$lp, cplexAPI::CPX_MAX)
        rupper = c(rbnds[1:nm, 1], rbnds[c((nm + 1):nr), 2])
        rupper[nr] = 0.27
        cplexAPI::newRowsCPLEX(prob$env, prob$lp, nrows = nr, 
            rhs = rupper, sense = rtype)
        upper = cbnds[, 2]
        lower = cbnds[, 1]
        upper[2609] = 0
        upper[2729] = 1000
        upper[2835] = 0
        upper[2705] = 0
        upper[2774] = 0
        cplexAPI::newColsCPLEX(prob$env, prob$lp, nc, obj = cobj, 
            lb = lower, ub = upper)
        print(sprintf("\%s : step 2: nzijr....", format(Sys.time(), 
            "\%d-\%m-\%Y \%X")))
        TMPmat <- as(LHS, "TsparseMatrix")
        cplexAPI::chgCoefListCPLEX(prob$env, prob$lp, nnz = length(TMPmat@x), 
            ia = TMPmat@i, ja = TMPmat@j, ra = TMPmat@x)
        fname = format(Sys.time(), "Cplex_moment_\%Y\%m\%d_\%H\%M.lp")
        print(sprintf("Writing problem to file: \%s/\%s  ...", 
            getwd(), fname))
        cplexAPI::writeProbCPLEX(prob$env, prob$lp, fname)
        lp_ok <- cplexAPI::lpoptCPLEX(prob$env, prob$lp)
        print(lp_ok)
        sol = cplexAPI::solutionCPLEX(prob$env, prob$lp)
        print(sprintf("GLC upt=\%f, AC=\%f Pyr=\%f fruc=\%f Lac=\%f", 
            sol$x[2729], sol$x[2609], sol$x[2835], sol$x[2705], 
            sol$x[2774]))
        colst = sol$x
    }
    else {
        prob <- glpkAPI::initProbGLPK()
        glpkAPI::addRowsGLPK(prob, nrows = nr)
        outj <- glpkAPI::addColsGLPK(prob, ncols = nc)
        glpkAPI::setObjDirGLPK(prob, glpkAPI::GLP_MAX)
        rtype <- c(rep(glpkAPI::GLP_FX, nm), rep(glpkAPI::GLP_UP, 
            nr - nm))
        rlower = c(rbnds[1:nm, 1], rbnds[(nm + 1):nr, 2])
        rupper = rbnds[1:nr, 2]
        rupper[nr] = 0.27
        glpkAPI::setRowsBndsGLPK(prob, c(1:nr), lb = rlower, 
            ub = rupper, type = rtype)
        upper = cbnds[, 2]
        lower = cbnds[, 1]
        cc <- glpkAPI::setColsBndsObjCoefsGLPK(prob, c(1:nc), 
            lower, upper, cobj)
        TMPmat <- as(LHS, "TsparseMatrix")
        cc <- glpkAPI::loadMatrixGLPK(prob, length(TMPmat@x), 
            ia = TMPmat@i + 1, ja = TMPmat@j + 1, ra = TMPmat@x)
        fname = format(Sys.time(), "glpk_eFBA_\%Y\%m\%d_\%H\%M.lp")
        print(sprintf("Writing problem to file: \%s/\%s ...", getwd(), 
            fname))
        glpkAPI::writeLPGLPK(prob, fname)
        print(format(Sys.time(), "Testing time : \%Y\%m\%d \%X Solving..."))
        lp_ok = glpkAPI::solveSimplexGLPK(prob)
        glpkAPI::return_codeGLPK(lp_ok)
        lp_stat = glpkAPI::getSolStatGLPK(prob)
        glpkAPI::status_codeGLPK(lp_stat)
        lp_obj = glpkAPI::getObjValGLPK(prob)
        colst = glpkAPI::getColsPrimGLPK(prob)
        newFlux = colst
        print(sprintf("GLC upt=\%f, AC=\%f Pyr=\%f fruc=\%f Lac=\%f galt=\%f", 
            colst[2729], colst[2609], colst[2835], colst[2705], 
            colst[2774], colst[2723]))
    }
    return(colst)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
