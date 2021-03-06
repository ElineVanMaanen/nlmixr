source("helper-prep_fit.R")
context("NLME42: two-compartment bolus Michaelis-Menten, multiple-dose")
runno <- "N042_ode"

datr <-Bolus_2CPTMM
datr$EVID <- ifelse(datr$EVID == 1, 101, datr$EVID)
datr <- datr[datr$EVID != 2,]

ode2MM <- "
d/dt(centr)  = K21*periph-K12*centr-(VM*centr/V)/(KM+centr/V);
d/dt(periph) =-K21*periph+K12*centr;
"

mypar7 <- function(lVM, lKM, lV, lCLD, lVT)
{
  VM <- exp(lVM)
  KM <- exp(lKM)
  V <- exp(lV)
  CLD  <- exp(lCLD)
  VT <- exp(lVT)
  K12 <- CLD / V
  K21 <- CLD / VT
}
specs7 <-
  list(
    fixed = lVM + lKM + lV + lCLD + lVT ~ 1,
    random = pdDiag(lVM + lKM + lV + lCLD + lVT ~ 1),
    start = c(
      lVM = 7,
      lKM = 6,
      lV = 4,
      lCLD = 1.5,
      lVT = 4
    )
  )

dat <- datr

fit[[runno]] <-
  nlme_ode(
    dat,
    model = ode2MM,
    par_model = specs7,
    par_trans = mypar7,
    response = "centr",
    response.scaler = "V",
    weight = varPower(fixed = c(1)),
    verbose = verbose_minimization,
    control = default_control
  )

# Generate this with generate_expected_values(fit[[runno]])
expected_values[[runno]] <-
  list(
    lik=c(-41573.85, 83169.7, 83245.02),
    param=c(6.9099, 5.4486, 4.2566, 1.3745, 3.8736),
    stdev_param=c(1.3962, 1.4822, 1.4159, 0.0019563, 1.4901),
    sigma=c(0.20436)
  )
