source("helper-prep_fit.R")
context("NLME35: two-compartment oral, multiple-dose")
runno <- "N035_ode"

datr <- Bolus_2CPT
datr$EVID <- ifelse(datr$EVID == 1, 101, datr$EVID)
datr <- datr[datr$EVID != 2,]

ode2 <- "
d/dt(centr)  = K21*periph-K12*centr-K10*centr;
d/dt(periph) =-K21*periph+K12*centr;
"

mypar6 <- function(lCL, lV, lCLD, lVT)
{
  CL <- exp(lCL)
  V  <- exp(lV)
  CLD <- exp(lCLD)
  VT <- exp(lVT)
  K10 <- CL / V
  K12 <- CLD / V
  K21 <- CLD / VT
}

specs6 <-
  list(
    fixed = lCL + lV + lCLD + lVT ~ 1,
    random = pdDiag(lCL + lV + lCLD + lVT ~ 1),
    start = c(
      lCL = 1.3,
      lV = 4.19,
      lCLD = 1.5,
      lVT = 3.9
    )
  )

dat <- datr

fit[[runno]] <-
  nlme_ode(
    dat,
    model = ode2,
    par_model = specs6,
    par_trans = mypar6,
    response = "centr",
    response.scaler = "V",
    weight = varPower(fixed = c(1)),
    verbose = verbose_minimization,
    control = default_control
  )

# Generate this with generate_expected_values(fit[[runno]])
expected_values[[runno]] <-
  list(
    lik=c(-39312.89, 78643.79, 78705.42),
    param=c(1.3428, 4.1969, 1.3023, 3.8958),
    stdev_param=c(1.6698, 1.5403, 0.0026543, 1.502),
    sigma=c(0.20288)
  )
