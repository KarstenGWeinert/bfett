#' Runs tests
#' 
#'
#' @param fn file name(s) of the tests to run. Default (NULL) runs all tests.
#' @param which character, either "summary" (default, aggregates the results),
#'              "fails" (returns tests that failed), or "all"
#' @param verbose FALSE (default) silent, TRUE diagnostic messages
#' @return a data.frame
#' @export
test_bfett <- function(fn=NULL, which=c("summary", "fails", "all"), verbose=FALSE) {
	stopifnot(requireNamespace("tinytest"))
	if(length(which)>1) which <- which[1]
	if(!is.null(fn)) for (f in fn) {
		full_fn <- system.file(paste0("/tinytest/test_", fn, ".R"), package="bfett")
		stopifnot(file.exists(full_fn))
		out <- tinytest::run_test_file(full_fn, verbose=verbose)
	} else {
		out <- tinytest::run_test_dir(system.file("tinytest", package="bfett"), verbose=verbose)
	}
	if(which=="summary")
		return(summary(out))
	else {
		out <- as.data.frame(out)
		if(which=="fails") out <- subset(out, !result)
		return(out)
	}
		
	
}

	
