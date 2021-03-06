% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nlmixr.R
\name{nlmixr_fit}
\alias{nlmixr_fit}
\title{Fit a nlmixr model}
\usage{
nlmixr_fit(uif, data, est = NULL, control = list(), ...,
  sum.prod = FALSE, table = tableControl())
}
\arguments{
\item{uif}{Parsed nlmixr model (by \code{nlmixr(mod.fn)}).}

\item{data}{Dataset to estimate.  Needs to be RxODE compatible in
EVIDs.}

\item{est}{Estimation method}

\item{control}{Estimation control options.  They could be
\code{\link[nlme]{nlmeControl}}, \code{\link{saemControl}} or
\code{\link{foceiControl}}}

\item{...}{Parameters passed to estimation method.}

\item{sum.prod}{Take the RxODE model and use more precise
products/sums.  Increases solving accuracy and solving time.}

\item{table}{A list controlling the table options (i.e. CWRES,
NPDE etc).  See \code{\link{tableControl}}.}
}
\value{
nlmixr fit object
}
\description{
Fit a nlmixr model
}
\author{
Matthew L. Fidler
}
