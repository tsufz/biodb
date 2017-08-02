# vi: fdm=marker

# Class declaration {{{1
################################################################

MirbaseConn <- methods::setRefClass("MirbaseConn", contains = "RemotedbConn")

# Constructor {{{1
################################################################

MirbaseConn$methods( initialize = function(...) {
	callSuper(base.url = "http://www.mirbase.org/", ...)
})

# Get nb entries {{{1
################################################################

MirbaseConn$methods( getNbEntries = function(count = FALSE) {

	n <- NA_integer_

	ids <- .self$getEntryIds()
	if ( ! is.null(ids))
		n <- length(ids)

	return(n)
})