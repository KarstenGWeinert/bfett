#' @import data.table
.onLoad <- function(libname, pkgname) {
  .datatable.aware <<- TRUE # seems not necessary
}
