library(testthat)
library(nlmixr)

rxPermissive({
  context("Test all models")
  test_that("Models", {
    # Run all the models
    files <- list.files(path="models/", full.names=TRUE, pattern="^model*")
    run_duration <- c()
    for (current_file in files) {
      start_time <- Sys.time()
      old_names <-
        if (exists("fit")) {
          names(fit)
        } else {
          character(0)
        }
      message(current_file, " at ", as.character(start_time))
      source(current_file, chdir = TRUE)
      end_time <- Sys.time()
      run_duration[runno] <- difftime(end_time, start_time, units="secs")
      message("Took ", as.character(run_duration[runno]))
      if (runno %in% old_names) {
        stop("Duplicated runno: ", runno)
      }
      new_names <- names(fit)[!(names(fit) %in% old_names)];
      for (runno in new_names){
          # Test that results are correct for new runs
          z <- VarCorr(fit[[runno]])

          expect_equal(
              round(c(fit[[runno]]$logLik, AIC(fit[[runno]]), BIC(fit[[runno]])), 2),
              expected_values[[runno]]$lik,
              info=paste("Likelihood for", runno)
          )

          expect_equal(
              unname(fit[[runno]]$coefficients$fixed),
              expected_values[[runno]]$param,
              tol=1e-3,
              info=paste("Parameters for", runno)
          )

          expect_equal(
              unname(z[-nrow(z), "StdDev"]),
              expected_values[[runno]]$stdev_param,
              tol=1e-3,
              info=paste("Parameter stdev for", runno)
          )

          expect_equal(
              fit[[runno]]$sigma,
              expected_values[[runno]]$sigma,
              tol=1e-3,
              info=paste("Sigma for", runno)
          )
      }
    }
  })
}, on.validate="NLMIXR_VALIDATION_FULL",silent=TRUE)
