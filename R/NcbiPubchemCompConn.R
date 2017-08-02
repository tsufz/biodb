# vi: fdm=marker

# Class declaration {{{1
################################################################

#' @include NcbiPubchemConn.R
NcbiPubchemCompConn <- methods::setRefClass("NcbiPubchemCompConn", contains = "NcbiPubchemConn")

# Constructor {{{1
################################################################

NcbiPubchemCompConn$methods( initialize = function(...) {
	callSuper(content.type = BIODB.XML, db.name = 'compound', id.xmltag = 'PC-CompoundType_id_cid', entry.xmltag = 'PC-Compound', id.urlfield = 'cid', ...)
})

# Get entry ids {{{1
################################################################

NcbiPubchemCompConn$methods( getEntryIds = function(max.results = NA_integer_) {
	.self$message(MSG.CAUTION, "No method implemented for computing list of IDs.")
	return(NULL)
})