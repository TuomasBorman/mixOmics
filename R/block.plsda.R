# ==============================================================================
# block.plsda: perform a horizontal PLS-DA on a combination of datasets,
#   input as a list in X
#   this function is a particular setting of internal_mint.block,
#   the formatting of the input is checked in internal_wrapper.mint.block
# ==============================================================================

#' N-integration with Projection to Latent Structures models (PLS) with
#' Discriminant Analysis
#' 
#' Integration of multiple data sets measured on the same samples or
#' observations to classify a discrete outcome, ie. N-integration with
#' Discriminant Analysis. The method is partly based on Generalised Canonical
#' Correlation Analysis.
#' 
#' \code{block.plsda} function fits a horizontal integration PLS-DA model with
#' a specified number of components per block). A factor indicating the
#' discrete outcome needs to be provided, either by \code{Y} or by its position
#' \code{indY} in the list of blocks \code{X}.
#'
#' \code{X} can contain missing values. Missing values are handled by being
#' disregarded during the cross product computations in the algorithm
#' \code{block.pls} without having to delete rows with missing data.
#' Alternatively, missing data can be imputed prior using the
#' \code{\link{impute.nipals}} function.
#' 
#' The type of algorithm to use is specified with the \code{mode} argument.
#' Four PLS algorithms are available: PLS regression \code{("regression")}, PLS
#' canonical analysis \code{("canonical")}, redundancy analysis
#' \code{("invariant")} and the classical PLS algorithm \code{("classic")} (see
#' References and \code{?pls} for more details).
#' 
#' Note that our method is partly based on Generalised Canonical Correlation
#' Analysis and differs from the MB-PLS approaches proposed by Kowalski et al.,
#' 1989, J Chemom 3(1) and Westerhuis et al., 1998, J Chemom, 12(5).
#' 
#' @inheritParams block.pls
#' @param Y a factor or a class vector for the discrete outcome.
#' @return \code{block.plsda} returns an object of class
#' \code{"block.plsda","block.pls"}, a list that contains the following
#' components:
#' 
#' \item{X}{the centered and standardized original predictor matrix.}
#' \item{indY}{the position of the outcome Y in the output list X.}
#' \item{ncomp}{the number of components included in the model for each block.}
#' \item{mode}{the algorithm used to fit the model.} \item{variates}{list
#' containing the variates of each block of X.} \item{loadings}{list containing
#' the estimated loadings for the variates.} \item{names}{list containing the
#' names to be used for individuals and variables.} \item{nzv}{list containing
#' the zero- or near-zero predictors information.} \item{iter}{Number of
#' iterations of the algorithm for each component}
#' \item{prop_expl_var}{Percentage of explained variance for each
#' component and each block}
#' \item{call}{if \code{verbose.call = FALSE}, then just the function call is returned.
#' If \code{verbose.call = TRUE} then all the inputted values are accessable via
#' this component}
#' Note that the argument 'scheme' has now been hardcoded to 'horst' and 'init' to 'svd.single'. 
#' @author Florian Rohart, Benoit Gautier, Kim-Anh Lê Cao, Al J Abadi
#' @seealso \code{\link{plotIndiv}}, \code{\link{plotArrow}},
#' \code{\link{plotLoadings}}, \code{\link{plotVar}}, \code{\link{predict}},
#' \code{\link{perf}}, \code{\link{selectVar}}, \code{\link{block.pls}},
#' \code{\link{block.splsda}} and http://www.mixOmics.org for more details.
#' @references On PLSDA:
#' 
#' Barker M and Rayens W (2003). Partial least squares for discrimination.
#' \emph{Journal of Chemometrics} \bold{17}(3), 166-173. Perez-Enciso, M. and
#' Tenenhaus, M. (2003). Prediction of clinical outcome with microarray data: a
#' partial least squares discriminant analysis (PLS-DA) approach. \emph{Human
#' Genetics} \bold{112}, 581-592. Nguyen, D. V. and Rocke, D. M. (2002). Tumor
#' classification by partial least squares using microarray gene expression
#' data. \emph{Bioinformatics} \bold{18}, 39-50.
#' 
#' On multiple integration with PLS-DA: Gunther O., Shin H., Ng R. T. ,
#' McMaster W. R., McManus B. M. , Keown P. A. , Tebbutt S.J. , Lê Cao K-A. ,
#' (2014) Novel multivariate methods for integration of genomics and proteomics
#' data: Applications in a kidney transplant rejection study, OMICS: A journal
#' of integrative biology, 18(11), 682-95.
#' 
#' On multiple integration with sPLS-DA and 4 data blocks:
#' 
#' Singh A., Gautier B., Shannon C., Vacher M., Rohart F., Tebbutt S. and Lê
#' Cao K.A. (2016). DIABLO: multi omics integration for biomarker discovery.
#' BioRxiv available here:
#' \url{http://biorxiv.org/content/early/2016/08/03/067611}
#' 
#' mixOmics article:
#' 
#' Rohart F, Gautier B, Singh A, Lê Cao K-A. mixOmics: an R package for 'omics
#' feature selection and multiple data integration. PLoS Comput Biol 13(11):
#' e1005752
#' @keywords regression multivariate
#' @example ./examples/block.plsda-examples.R
#' @export
block.plsda <- function(X,
                        Y,
                        indY,
                        ncomp = 2,
                        design,
                        scale = TRUE,
                        tol = 1e-06,
                        max.iter = 100,
                        near.zero.var = FALSE,
                        all.outputs = TRUE,
                        verbose.call = FALSE)

{
    # check inpuy 'Y' and transformation in a dummy matrix
    if (!missing(Y))
    {
        if (is.null(dim(Y))) {
            Y = factor(Y)
        } 
        else {
            stop("'Y' should be a factor or a class vector.")
        }
        
        if (nlevels(Y) == 1)
            stop("'Y' should be a factor with more than one level")
        
        Y.input = Y
        Y = unmap(Y)
        colnames(Y) = levels(Y.input)
        rownames(Y) = rownames(X[[1]])
    } else if (!missing(indY)) {
        temp = X[[indY]]
        #not called Y to not be an input of the wrapper.sparse.mint.block
        if (is.null(dim(temp)))
        {
            temp = factor(temp)
        } else {
            stop("'Y' should be a factor or a class vector.")
        }
        
        if (nlevels(temp) == 1)
            stop("'X[[indY]]' should be a factor with more than one level")
        
        Y.input = temp
        X[[indY]] = unmap(temp)
        colnames(X[[indY]]) = levels(Y.input)
        rownames(X[[indY]]) = rownames(X[[ifelse(indY == 1, 2, 1)]])
        
    } else if (missing(indY)) {
        stop("Either 'Y' or 'indY' is needed")
    }
    
    # call to 'internal_wrapper.mint.block'
    result = internal_wrapper.mint.block(
        X = X,
        Y = Y,
        indY = indY,
        ncomp = ncomp,
        design = design,
        scheme = "horst",
        mode = 'regression',
        scale = scale,
        init = "svd.single",
        tol = tol,
        max.iter = max.iter,
        near.zero.var = near.zero.var,
        all.outputs = all.outputs,
        DA = TRUE
    )
    
    # calculate weights for each dataset
    weights = get.weights(result$variates, indY = result$indY)
    
    # choose the desired output from 'result'
    out = list(
        call = match.call(),
        X = result$A[-result$indY],
        Y = Y.input,
        ind.mat = result$A[result$indY][[1]],
        ncomp = result$ncomp,
        mode = result$mode,
        variates = result$variates,
        loadings = result$loadings,
        crit = result$crit,
        AVE = result$AVE,
        names = result$names,
        init = result$init,
        tol = result$tol,
        iter = result$iter,
        max.iter = result$max.iter,
        nzv = result$nzv,
        scale = result$scale,
        design = result$design,
        scheme = result$scheme,
        indY = result$indY,
        weights = weights,
        prop_expl_var = result$prop_expl_var
    )#[-result$indY])
    
    if (verbose.call) {
        c <- out$call
        out$call <- mget(names(formals()))
        out$call <- append(c, out$call)
        names(out$call)[1] <- "simple.call"
    }
    
    # give a class
    class(out) = c("block.plsda", "block.pls", "sgccda", "sgcca", "DA")
    return(invisible(out))
}



