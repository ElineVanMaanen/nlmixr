.onAttach <- function(libname, pkgname){ ## nocov start
    ## Setup RxODE.prefer.tbl
    nlmixrSetupMemoize()
    options(keep.source=TRUE)
}

nlmixrSetupMemoize <- function(){
    reSlow <- rex::rex(".slow", end)
    f <- sys.function(-1)
    ns <- environment(f)
    .slow <- ls(pattern=reSlow,envir=ns);
    for (slow in .slow){
        fast <- sub(reSlow, "", slow);
        if (!memoise::is.memoised(get(fast, envir=ns)) && is.null(get(slow, envir=ns))){
            utils::assignInMyNamespace(slow, get(fast, envir=ns))
            utils::assignInMyNamespace(fast, memoise::memoise(get(slow, envir=ns)))
        }
    }
}

##' Clear memoise cache for nlmixr
##'
##' @author Matthew L. Fidler
##' @keywords internal
##' @export
nlmixrForget <- function(){
    reSlow <- rex::rex(".slow",end)
    f <- sys.function(-1)
    ns <- environment(f)
    .slow <- ls(pattern=reSlow,envir=ns);
    for (slow in .slow){
        fast <- sub(reSlow, "", slow);
        memoise::forget(get(fast, envir=ns));
    }
}


##' @importFrom stats predict logLik na.fail pchisq
##' @importFrom n1qn1 n1qn1
##' @importFrom brew brew
##' @importFrom lattice xyplot
##' @importFrom lattice trellis.par.get
##' @importFrom nlme nlme fixed.effects random.effects
##' @importFrom nlme groupedData
##' @importFrom nlme getData
##' @importFrom nlme pdDiag
##' @importFrom RxODE RxODE
##' @importFrom graphics abline lines matplot plot points title
##' @importFrom stats as.formula nlminb optimHess rnorm terms predict anova optim sd var AIC BIC asOneSidedFormula coef end fitted resid setNames start simulate nobs qnorm quantile time
##' @importFrom utils assignInMyNamespace getFromNamespace head stack sessionInfo tail str
##' @importFrom parallel mclapply
##' @importFrom lbfgs lbfgs
##' @importFrom methods is
##' @importFrom Rcpp evalCpp
##' @importFrom dparser dparse
##' @importFrom vpc vpc
##' @importFrom ggplot2 ggplot aes geom_point facet_wrap geom_line geom_abline xlab geom_smooth
##' @importFrom RcppArmadillo armadillo_version
##' @useDynLib nlmixr, .registration=TRUE


rex::register_shortcuts("nlmixr");
## GGplot use and other issues...
utils::globalVariables(c("DV", "ID", "IPRED", "IRES", "PRED", "TIME", "grp", "initCondition", "values", "nlmixr_pred", "iter", "val", "EVID"));

nlmixr.logo <- "         _             _             \n        | | %9s (_) %s\n  _ __  | | _ __ ___   _ __  __ _ __\n | '_ \\ | || '_ ` _ \\ | |\\ \\/ /| '__|\n | | | || || | | | | || | >  < | |\n |_| |_||_||_| |_| |_||_|/_/\\_\\|_|\n"

##' Messages the nlmixr logo...
##'
##' @param str String to print
##' @param version Version information (by default use package version)
##' @author Matthew L. Fidler
nlmixrLogo <- function(str="", version=sessionInfo()$otherPkgs$nlmixr$Version){
    message(sprintf(nlmixr.logo, str, version));
}
##' Dispaly nlmixr's version
##'
##' @author Matthew L. Fidler
##' @export
nlmixrVersion <- function(){
    nlmixrLogo()
}

armaVersion <- function(){
    nlmixrLogo(str="RcppArmadiilo", RcppArmadillo::armadillo_version())
}

##' nlmixr fits population PK and PKPD non-linear mixed effects models.
##'
##' nlmixr is an R package for fitting population pharmacokinetic (PK)
##' and pharmacokinetic-pharmacodynamic (PKPD) models.
##'
##' The nlmixr generalized function allows common access to the nlmixr
##' estimation routines.
##'
##' @template uif
##'
##' @param object Fitted object or function specifying the model.
##' @inheritParams nlmixr_fit
##' @param ... Other parameters
##' @return Either a nlmixr model or a nlmixr fit object
##' @author Matthew L. Fidler, Rik Schoemaker
##' @export
nlmixr <- function(object, data, est=NULL, control=list(),
                   table=tableControl(), ...){
    UseMethod("nlmixr")
}

##' @rdname nlmixr
##' @export
nlmixr.function <- function(object, data, est=NULL, control=list(), table=tableControl(), ...){
    .args <- as.list(match.call(expand.dots=TRUE))[-1]
    .uif <- nlmixrUI(object);
    class(.uif) <- "list";
    .uif$nmodel$model.name <- deparse(substitute(object))
    if (missing(data) && missing(est)){
        class(.uif) <- "nlmixrUI"
        return(.uif)
    } else {
        .uif$nmodel$data.name <- deparse(substitute(data))
        class(.uif) <- "nlmixrUI"
        .args$data <- data;
        .args <- c(list(uif=.uif), .args[-1]);
        return(do.call(nlmixr_fit, .args))
    }
}

##'@rdname nlmixr
##'@export
nlmixr.nlmixrFitCore <- function(object, data, est=NULL, control=list(), table=tableControl(), ...){
    .uif <- object$uif;
    if (missing(data)){
        data <- getData(object);
    }
    .args <- as.list(match.call(expand.dots=TRUE))[-1]
    .args$data <- data;
    .args <- c(list(uif=.uif), .args[-1]);
    return(do.call(nlmixr_fit, .args))
}

##' @rdname nlmixr
##' @export
nlmixr.nlmixrUI <- function(object, data, est=NULL, control=list(), ...){
    .args <- as.list(match.call(expand.dots=TRUE))[-1]
    .uif <- object
    if (missing(data) && missing(est)){
        return(.uif)
    } else {
        .args <- c(list(uif=.uif), .args[-1]);
        .uif$nmodel$data.name <- deparse(substitute(data))
        .args$data <- data;
        return(do.call(nlmixr_fit, .args));
    }
}

##' Convert/Format the data appropriately for nlmixr
##'
##' @param data is the name of the data to convert.  Can be a csv file
##'     as well.
##' @return Appropriately formatted data
##' @author Matthew L. Fidler
##' @keywords internal
##' @export
nlmixrData <- function(data){
    UseMethod("nlmixrData");
}
##' @export
##' @rdname nlmixrData
nlmixrData.character <- function(data){
    if (!file.exists(data)){
        stop(sprintf("%s does not exist.", data))
    }
    if (regexpr(rex::rex(".csv", end), data) != -1){
        return(nlmixrData.default(utils::read.csv(data, na.strings=c(".", "NA", "na", ""))))
    } else {
        stop(sprintf("Do not know how to read in %s", data));
    }
}
##' @export
##' @rdname nlmixrData
nlmixrData.default <- function(data){
    dat <- as.data.frame(data);
    nm1 <- toupper(names(dat));
    for (n in c("ID", "EVID", "TIME", "DV", "AMT")){
        w <- which(nm1 == n)
        if (length(w) == 1L){
            names(dat)[w] <- n;
        } else if (length(w) == 0L){
            stop(sprintf("Need '%s' data item in dataset.", n))
        } else {
            stop(sprintf("Multiple '%s' columns in dataset.", n))
        }
    }
    if (is(dat$ID, "factor")){
        dat$ID <- paste(dat$ID);
    }
    idSort <- .Call(`_nlmixr_chkSortIDTime`, as.integer(dat$ID), as.double(dat$TIME), as.integer(dat$EVID));
    if (idSort == 3L){
        dat <- dat[.Call(`_nlmixr_allDose`, as.integer(dat$EVID), as.integer(dat$ID)), ]
        ## warning("NONMEM-style data converted to nlmixr/RxODE-style data.");
        return(nlmixrData.default(nmDataConvert(dat)));
    }
    backSort <- c()
    backSort2 <- c();
    if (is(dat$ID, "character")){
        ## Character need to sort first
        lvl <- unique(dat$ID);
        lab <- paste(lvl)
        dat$ID <- factor(dat$ID, levels=lvl, labels=lab);
        dat <- dat[.Call(`_nlmixr_allDose`, as.integer(dat$EVID), as.integer(dat$ID)), ];
        ## Dropped some IDs?  Need to make sure they are still sequential
        dat$ID <- factor(dat$ID, levels=lvl, labels=lab);
        ## Get new factor level
        dat$ID <- paste(dat$ID);
        lvl <- unique(dat$ID);
        lab <- paste(lvl)
        dat$ID <- factor(dat$ID, levels=lvl, labels=lab);
        backSort <- levels(dat$ID);
        backSort2 <- seq_along(backSort)
        dat$ID <- as.integer(dat$ID);
    } else {
        if (idSort == 2L){
            dat <- dat[.Call(`_nlmixr_allDose`, as.integer(dat$EVID), as.integer(dat$ID)), ];
            lvl <- unique(dat$ID);
            lab <- paste(lvl)
            dat$ID <- factor(dat$ID, levels=lvl, labels=lab);
            backSort <- levels(dat$ID);
            backSort2 <- seq_along(backSort)
            dat$ID <- as.integer(dat$ID);
        } else if (idSort == 0L){
            warning("Sorted by ID, TIME, -EVID (ie doses before observations)")
            dat <- dat[order(dat$ID, dat$TIME,-dat$EVID), ];
            dat <- dat[.Call(`_nlmixr_allDose`, as.integer(dat$EVID), as.integer(dat$ID)), ]
            lvl <- unique(dat$ID);
            lab <- paste(lvl)
            dat$ID <- factor(dat$ID, levels=lvl, labels=lab);
            backSort <- levels(dat$ID);
            backSort2 <- seq_along(backSort)
            dat$ID <- as.integer(dat$ID);
        }
    }
    attr(dat, "backSort") <- backSort;
    attr(dat, "backSort2") <- backSort2;
    return(dat);
}

##' Fit a nlmixr model
##'
##' @param uif Parsed nlmixr model (by \code{nlmixr(mod.fn)}).
##' @param data Dataset to estimate.  Needs to be RxODE compatible in
##'     EVIDs.
##' @param est Estimation method
##' @param control Estimation control options.  They could be
##'     \code{\link[nlme]{nlmeControl}}, \code{\link{saemControl}} or
##'     \code{\link{foceiControl}}
##' @param ... Parameters passed to estimation method.
##' @param sum.prod Take the RxODE model and use more precise
##'     products/sums.  Increases solving accuracy and solving time.
##' @param table A list controlling the table options (i.e. CWRES,
##'     NPDE etc).  See \code{\link{tableControl}}.
##' @return nlmixr fit object
##' @author Matthew L. Fidler
##' @export
nlmixr_fit <- function(uif, data, est=NULL, control=list(), ...,
                       sum.prod=FALSE, table=tableControl()){
    .meta <- uif$meta
    .missingEst <- is.null(est);
    if (.missingEst & exists("est", envir=.meta)){
        est <- .meta$est
    }
    if (.missingEst & missing(control) & exists("control", envir=.meta)){
        control <- .meta$control
        if (is(control, "foceiControl")){
            est <- "focei"
            if (.missingEst && est != "focei"){
                warning(sprintf("Using focei instead of %s since focei controls were specified.", est))
            }
        } else if (is(control, "saemControl")){
            est <- "saem"
            if (.missingEst && est != "saem"){
                warning(sprintf("Using saem instead of %s since saem controls were specified.", est))
            }
        }
    }
    if (missing(table) && exists("table", envir=.meta)){
        table <- .meta$table
    }
    start.time <- Sys.time();
    if (!is(table, "tableControl")){
        table <- do.call(tableControl, table);
    }
    dat <- nlmixrData(data);
    up.covs <- toupper(uif$all.covs);
    up.names <- toupper(names(dat))
    for (i in seq_along(up.covs)){
        w <- which(up.covs[i] == up.names)
        if (length(w) == 1){
            names(dat)[w] = uif$all.covs[i];
        }
    }
    backSort <- attr(dat, "backSort");
    backSort2 <- attr(dat, "backSort2");
    attr(dat, "backSort") <- NULL;
    attr(dat, "backSort2") <- NULL;
    uif$env$infusion <- .Call(`_nlmixr_chkSolvedInf`, as.double(dat$EVID), as.integer(!is.null(uif$nmodel$lin.solved)));
    bad.focei <- "Problem calculating residuals, returning fit without residuals.";
    fix.dat <- function(x){
        if (length(backSort) > 0){
            cls <- class(x);
            class(x) <- "data.frame";
            x$ID <- factor(x$ID, backSort2, labels=backSort);
            class(x) <- cls;
        }
        .uif <- x$uif;
        .thetas <- x$theta;
        for (.n in names(.thetas)){
            .uif$ini$est[.uif$ini$name == .n] <- .thetas[.n];
        }
        .omega <- x$omega;
        for (.i in seq_along(.uif$ini$neta1)){
            if (!is.na(.uif$ini$neta1[.i])){
                .uif$ini$est[.i] <- .omega[.uif$ini$neta1[.i], .uif$ini$neta2[.i]];
            }
        }
        .env <- x$env
        .env$uif <- .uif;
        .predDf <- .uif$predDf;
        if (any(.predDf$cond != "") & any(names(x) == "CMT")){
            .cls <- class(x);
            class(x) <- "data.frame";
            x$CMT <- factor(x$CMT, levels=.predDf$cmt, labels=.predDf$cond)
            class(x) <- .cls;
        }
        return(x);
    }
    .addNpde <- function(x){
        .doIt <- table$npde;
        if (is.null(.doIt)){
            if (est == "saem"){
                .doIt <- table$saemNPDE
            } else if (est == "focei"){
                .doIt <- table$foceiNPDE
            } else if (est == "foce"){
                .doIt <- table$foceNPDE
            } else if (est == "nlme"){
                .doIt <- table$nlmeNPDE
            } else {
                .doIt <- FALSE;
            }
        }
        if (!is.logical(.doIt)) return(x);
        if (is.na(.doIt)) return(x);
        if (!.doIt) return (x);
        .ret <- try(addNpde(x,nsim=table$nsim, ties=table$ties, seed=table$seed, updateObject=FALSE), silent=TRUE);
        if (inherits(.ret, "try-error")) return(x);
        return(.ret);
    }
    calc.resid <- table$cwres;
    if (is.null(calc.resid)){
        if (est == "saem"){
            calc.resid <- table$saemCWRES
        } else if (est == "nlme"){
            calc.resid <- table$nlmeCWRES
        }
    }
    if (est == "saem"){
        pt <- proc.time()
        args <- as.list(match.call(expand.dots=TRUE))[-1]
        default <- saemControl();
        if (any(names(args) == "mcmc")){
            mcmc <- args$mcmc;
        } else if (any(names(control) == "mcmc")){
            mcmc <- control$mcmc;
        } else {
            mcmc <- default$mcmc;
        }
        if (any(names(args) == "ODEopt")){
            ODEopt <- args$ODEopt;
        } else if (any(names(control) == "ODEopt")){
            ODEopt <- control$ODEopt;
        } else {
            ODEopt <- default$ODEopt;
        }
        if (any(names(args) == "seed")){
            seed <- args$seed;
        } else if (any(names(control) == "seed")){
            seed <- control$seed;
        } else {
            seed <- default$seed;
        }
        if (any(names(args) == "print")){
            print <- args$print;
        } else if (any(names(control) == "print")){
            print <- control$print;
        } else {
            print <- default$print;
        }
        if (any(names(args) == "DEBUG")){
            DEBUG <- args$DEBUG;
        } else if (any(names(control) == "DEBUG")){
            DEBUG <- control$DEBUG;
        } else {
            DEBUG <- default$DEBUG;
        }
        if (any(names(args) == "covMethod")){
            covMethod <- args$covMethod;
        } else if (any(names(control) == "covMethod")){
            covMethod <- control$covMethod;
        } else {
            covMethod <- default$covMethod;
        }
        if (any(names(control) == "logLik")){
            .logLik <- control$logLik
        } else {
            .logLik <- default$logLik
        }
        if (any(names(control) == "optExpression")){
            uif$env$optExpression <- control$optExpression
        } else {
            uif$env$optExpression <- default$optExpression
        }

        if (is.null(uif$nlme.fun.mu)){
            stop("SAEM requires all ETAS to be mu-referenced")
        }
        .low <- uif$ini$lower;
        .low <- .low[!is.na(.low)]
        .up <- uif$ini$upper;
        .up <- .up[!is.na(.up)]
        if (any(.low != -Inf) | any(.up != Inf)){
            warning("Bounds are ignored in SAEM")
        }
        if (any(paste(uif$ini$name[uif$ini$fix]) %in% unlist(uif$mu.ref))){
            stop("Fixed thetas cannot be associated with an ETA in SAEM")
        }
        uif$env$mcmc <- mcmc;
        uif$env$ODEopt <- ODEopt;
        uif$env$sum.prod <- sum.prod
        uif$env$covMethod <- covMethod
        .dist <- uif$saem.distribution
        model <- uif$saem.model
        cfg <- configsaem(model=model, data=dat, inits=uif$saem.init,
                          mcmc=mcmc, ODEopt=ODEopt, seed=seed, fixed=uif$saem.fixed,
                          distribution=.dist, DEBUG=DEBUG);
        if (print > 1){
            cfg$print <- as.integer(print)
        }
        .fit <- model$saem_mod(cfg);
        .ret <- as.focei.saemFit(.fit, uif, pt, data=dat, calcResid=calc.resid, obf=.logLik);
        if (inherits(.ret, "nlmixrFitData")){
            .ret <- fix.dat(.ret);
            .ret <- .addNpde(.ret);
        }
        if (inherits(.ret, "nlmixrFitCore")){
            .env <- .ret$env
            assign("startTime", start.time, .env);
            assign("est", est, .env);
            assign("stopTime", Sys.time(), .env);
        }
        return(.ret);
    } else if (est == "nlme" || est == "nlme.mu" || est == "nlme.mu.cov" || est == "nlme.free"){
        if (length(uif$predDf$cond) > 1) stop("nlmixr nlme does not support multiple endpoints.")
        pt <- proc.time()
        est.type <- est;
        if (est == "nlme.free"){
            fun <- uif$nlme.fun;
            specs <- uif$nlme.specs;
        } else if (est == "nlme.mu"){
            fun <- uif$nlme.fun.mu;
            specs <- uif$nlme.specs.mu;
        } else if (est == "nlme.mu.cov"){
            fun <- uif$nlme.fun.mu.cov
            specs <- uif$nlme.specs.mu.cov;
        } else {
            if (!is.null(uif$nlme.fun.mu.cov)){
                est.type <- "nlme.mu.cov"
                fun <- uif$nlme.fun.mu.cov
                specs <- uif$nlme.specs.mu.cov;
            } else if (!is.null(uif$nlme.fun.mu)){
                est.type <- "nlme.mu"
                fun <- uif$nlme.fun.mu
                specs <- uif$nlme.specs.mu;
            } else {
                est.type <- "nlme.free"
                fun <- uif$nlme.fun
                specs <- uif$nlme.fun.specs;
            }
        }
        grp.fn <- uif$grp.fn;
        dat$nlmixr.grp <- factor(apply(dat, 1, function(x){
            cur <- x;
            names(cur) <- names(dat);
            with(as.list(cur), {
                return(grp.fn())
            })
        }));
        dat$nlmixr.num <- seq_along(dat$nlmixr.grp)
        weight <- uif$nlme.var
        if (!is.null(uif$nmodel$lin.solved)){
            fit <- nlme_lin_cmpt(dat, par_model=specs,
                                 ncmt=uif$nmodel$lin.solved$ncmt,
                                 oral=uif$nmodel$lin.solved$oral,
                                 tlag=uif$nmodel$lin.solved$tlag,
                                 infusion=uif$env$infusion,
                                 parameterization=uif$nmodel$lin.solved$parameterization,
                                 par_trans=fun,
                                 weight=weight,
                                 verbose=TRUE,
                                 control=control,
                                 ...);
        } else {
            if (sum.prod){
                rxode <- RxODE::rxSumProdModel(uif$rxode.pred);
            } else {
                rxode <- uif$rxode.pred;
            }
            .atol <- 1e-8
            if (!is.null(control$atol)) .atol <- control$atol
            .rtol <- 1e-8
            if (!is.null(control$rtol)) .rtol <- control$rtol
            fit <- nlme_ode(dat,
                            model=rxode,
                            par_model=specs,
                            par_trans=fun,
                            response="nlmixr_pred",
                            weight=weight,
                            verbose=TRUE,
                            control=control,
                            atol=.atol,
                            rtol=.rtol,
                            ...);
        }
        class(fit) <- c(est.type, class(fit));
        .ret <- as.focei.nlmixrNlme(fit, uif, pt, data=dat, calcResid=calc.resid);
        if (inherits(.ret, "nlmixrFitData")){
            .ret <- fix.dat(.ret);
            .ret <- .addNpde(.ret);
        }
        if (inherits(.ret, "nlmixrFitCore")){
            .env <- .ret$env
            assign("startTime", start.time, .env);
            assign("est", est, .env);
            assign("stopTime", Sys.time(), .env);
        }
        return(.ret)
    } else if (any(est == c("foce", "focei", "fo", "foi"))){
        if (any(est == c("foce", "fo"))){
            control$interaction <- FALSE;
        }
        env <- new.env(parent=emptyenv());
        env$uif <- uif;
        if (any(est == c("fo", "foi"))){
            control$maxInnerIterations <- 0
            control$fo <-TRUE;
            control$boundTol <- 0;
            env$skipTable <- TRUE;
        }
        fit <- foceiFit(dat,
                        inits=uif$focei.inits,
                        PKpars=uif$theta.pars,
                        ## par_trans=fun,
                        model=uif$rxode.pred,
                        pred=function(){return(nlmixr_pred)},
                        err=uif$error,
                        lower=uif$focei.lower,
                        upper=uif$focei.upper,
                        fixed=uif$focei.fixed,
                        thetaNames=uif$focei.names,
                        etaNames=uif$eta.names,
                        control=control,
                        env=env,
                        ...);
        if (any(est == c("fo", "foi"))){
            ## Add posthoc.
            .default <- foceiControl();
            control$maxInnerIterations <- .default$maxInnerIterations
            control$maxOuterIterations <- 0L;
            control$covMethod <- 0L;
            control$fo <- 0L
            .uif <- fit$uif;
            .thetas <- fit$theta;
            for (.n in names(.thetas)){
                .uif$ini$est[.uif$ini$name == .n] <- .thetas[.n];
            }
            .omega <- fit$omega;
            for (.i in seq_along(.uif$ini$neta1)){
                if (!is.na(.uif$ini$neta1[.i])){
                    .uif$ini$est[.i] <- .omega[.uif$ini$neta1[.i], .uif$ini$neta2[.i]];
                }
            }
            .time <- fit$time;
            .objDf <- fit$objDf;
            .message <- fit$env$message
            .time <- fit$time
            env <- new.env(parent=emptyenv());
            for (.w in c("cov", "covR", "covS", "covMethod")){
                if (exists(.w, fit$env)){
                    assign(.w, get(.w, envir=fit$env), envir=env);
                }
            }
            env$time2 <- time;
            env$uif <- .uif;
            env$method <- "FO";
            fit <- foceiFit(dat,
                            inits=.uif$focei.inits,
                            PKpars=.uif$theta.pars,
                            ## par_trans=fun,
                            model=.uif$rxode.pred,
                            pred=function(){return(nlmixr_pred)},
                            err=.uif$error,
                            lower=.uif$focei.lower,
                            upper=.uif$focei.upper,
                            fixed=.uif$focei.fixed,
                            thetaNames=.uif$focei.names,
                            etaNames=.uif$eta.names,
                            control=control,
                            env=env,
                            ...);
            assign("message2", fit$env$message, env);
            assign("message", .message, env);
            .tmp1 <- env$objDf;
            if (any(names(.objDf) == "Condition Number")) .tmp1 <- data.frame(.tmp1, "Condition Number"=NA, check.names=FALSE);
            if (any(names(.tmp1) == "Condition Number")) .objDf <- data.frame(.objDf, "Condition Number"=NA, check.names=FALSE);
            env$objDf <- rbind(.tmp1, .objDf);
            row.names(env$objDf) <- c(ifelse(est == "fo", "FOCE", "FOCEi"), "FO");
            .tmp1 <- env$time;
            .tmp1$optimize <- .time$optimize
            .tmp1$covariance <- .time$covariance
            assign("time", .tmp1, envir=env)
            env$objDf <- env$objDf[, c("OBJF", "AIC", "BIC", "Log-likelihood", "Condition Number")]
            setOfv(env, "fo")
        }
        fit <- fix.dat(fit);
        fit <- .addNpde(fit);
        assign("start.time", start.time, env);
        assign("est", est, env);
        assign("stop.time", Sys.time(), env);
        return(fit);
    } else if (est == "posthoc"){
        control <- do.call(nlmixr::foceiControl, control);
        control$covMethod <- 0L
        control$maxOuterIterations <- 0L;
        fit <- foceiFit(dat,
                        inits=uif$focei.inits,
                        PKpars=uif$theta.pars,
                        ## par_trans=fun,
                        model=uif$rxode.pred,
                        pred=function(){return(nlmixr_pred)},
                        err=uif$error,
                        lower=uif$focei.lower,
                        upper=uif$focei.upper,
                        thetaNames=uif$focei.names,
                        etaNames=uif$eta.names,
                        control=control,
                        ...)
        assign("uif", uif, fit$env)
        ## assign("start.time", start.time, env);
        ## assign("est", est, env);
        ## assign("stop.time", Sys.time(), env);
        ## assign("start.time", start.time, env);
        ## assign("est", est, env);
        ## assign("stop.time", Sys.time(), env);
        assign("origControl",control,fit$env);
        return(fit);
    }
}
##' Control Options for SAEM
##'
##' @param seed Random Seed for SAEM step.  (Needs to be set for
##'     reproducibility.)  By default this is 99.
##'
##' @param nBurn Number of iterations in the Stochastic Approximation
##'     (SA), or burn-in step. This is equivalent to Monolix's \code{K_0} or \code{K_b}.
##'
##' @param nEm Number of iterations in the Expectation-Maximization
##'     (EM) Step. This is equivalent to Monolix's \code{K_1}.
##'
##' @param nmc Number of Markov Chains. By default this is 3.  When
##'     you increase the number of chains the numerical integration by
##'     MC method will be more accurate at the cost of more
##'     computation.  In Monolix this is equivalent to \code{L}
##'
##' @param nu This is a vector of 3 integers. They represent the
##'     numbers of transitions of the three different kernels used in
##'     the Hasting-Metropolis algorithm.  The default value is \code{c(2,2,2)},
##'     representing 40 for each transition initially (each value is
##'     multiplied by 20).
##'
##'     The first value represents the initial number of multi-variate
##'     Gibbs samples are taken from a normal distribution.
##'
##'     The second value represents the number of uni-variate, or multi-
##'     dimensional random walk Gibbs samples are taken.
##'
##'     The third value represents the number of bootstrap/reshuffling or
##'     uni-dimensional random samples are taken.
##'
##' @param print The number it iterations that are completed before
##'     anything is printed to the console.  By default, this is 1.
##'
##' @param covMethod  Method for calculating covariance.  In this
##'     discussion, R is the Hessian matrix of the objective
##'     function. The S matrix is the sum of each individual's
##'     gradient cross-product (evaluated at the individual empirical
##'     Bayes estimates).
##'
##'  "\code{fim}" Use the SAEM-calculated Fisher Information Matrix to calculate the covariance.
##'
##'  "\code{r,s}" Uses the sandwich matrix to calculate the covariance, that is: \eqn{R^-1 \times S \times R^-1}
##'
##'  "\code{r}" Uses the Hessian matrix to calculate the covariance as \eqn{2\times R^-1}
##'
##'  "\code{s}" Uses the crossproduct matrix to calculate the covariance as \eqn{4\times S^-1}
##'
##'  "" Does not calculate the covariance step.
##' @param logLik boolean indicating that log-likelihood should be
##'     calculate by Gaussian quadrature.
##' @param trace An integer indicating if you want to trace(1) the
##'     SAEM algorithm process.  Useful for debugging, but not for
##'     typical fitting.
##' @param ... Other arguments to control SAEM.
##' @inheritParams RxODE::rxSolve
##' @inheritParams foceiControl
##' @return List of options to be used in \code{\link{nlmixr}} fit for
##'     SAEM.
##' @author Wenping Wang & Matthew L. Fidler
##' @export
saemControl <- function(seed=99,
                        nBurn=200, nEm=300,
                        nmc=3,
                        nu=c(2, 2, 2),
                        atol = 1e-06,
                        rtol = 1e-04,
                        stiff = TRUE,
                        transitAbs = FALSE,
                        print=1,
                        trace=0,
                        covMethod=c("fim", "r,s", "r", "s"),
                        logLik=FALSE,
                        optExpression=TRUE,
                        ...){
    .xtra <- list(...);
    .rm <- c();
    if (missing(transitAbs) && !is.null(.xtra$transit_abs)){
        transitAbs <- .xtra$transit_abs;
        .rm <- c(.rm, "transit_abs")
    }
    if (missing(nBurn) && !is.null(.xtra$n.burn)){
        nBurn <- .xtra$n.burn;
        .rm <- c(.rm, "n.burn")
    }
    if (missing(nEm) && !is.null(.xtra$n.em)){
        nEm <- .xtra$n.em;
        .rm <- c(.rm, "n.em")
    }
    .ret <- list(mcmc=list(niter=c(nBurn, nEm), nmc=nmc, nu=nu),
         ODEopt=list(atol=atol, rtol=rtol,
                     stiff=as.integer(stiff),
                     transitAbs = as.integer(transitAbs)),
         seed=seed,
         print=print,
         DEBUG=trace,
         optExpression=optExpression, ...)
    if (length(.rm) > 0){
        .ret <- .ret[!(names(.ret) %in% .rm)]
    }
    .ret[["covMethod"]] <- match.arg(covMethod);
    .ret[["logLik"]] <- logLik;
    class(.ret) <- "saemControl"
    .ret
}

##' Add CWRES
##'
##' This returns a new fit object with CWRES attached
##'
##' @param fit nlmixr fit without WRES/CWRES
##' @param updateObject Boolean indicating if the original fit object should be updated. By default this is true.
##' @return fit with CWRES
##' @author Matthew L. Fidler
##' @export
addCwres <- function(fit, updateObject=TRUE){
    .objName <- substitute(fit);
    if(any(names(fit) == "CWRES")){
        warning("Already contains CWRES");
        return(fit)
    }
    .uif <- fit$uif;
    .saem <- fit$saem
    if (!is.null(.saem)){
        .newFit <- as.focei.saemFit(.saem, .uif, data=getData(fit), calcResid = TRUE, obf=fit$objDf["SAEMg","OBJF"]);
        .df <- .newFit[, c("WRES", "CRES", "CWRES", "CPRED")];
        .new <- cbind(fit, .df);
    }
    .nlme <- fit$nlme
    if (!is.null(.nlme)){
        .newFit <- as.focei(.nlme, .uif, data=getData(fit), calcResid = TRUE);
        .df <- .newFit[, c("WRES", "CRES", "CWRES", "CPRED")];
        .new <- cbind(fit, .df);
    }
    class(.new) <- class(.newFit)
    if (updateObject){
        .parent <- parent.frame(2);
        .bound <- do.call("c", lapply(ls(.parent, all.names=TRUE), function(.cur){
                                   if (.cur == .objName && identical(.parent[[.cur]], fit)){
                                       return(.cur)
                                   }
                                   return(NULL);
                               }))
        if (length(.bound) == 1){
            if (exists(.bound, envir=.parent)){
                assign(.bound, .new, envir=.parent)
            }
        }
    }
    return(.new);
}
