# vi: fdm=marker

# Constants {{{1
################################################################

.BIODB.NCBI.GENE.PARSING.EXPR <- list(
	'accession'     = "//Gene-track_geneid",
	'uniprot.id'    = "//Gene-commentary_heading[text()='UniProtKB']/..//Dbtag_db[text()='UniProtKB/Swiss-Prot']/..//Object-id_str",
	'location'      = "//Gene-ref_maploc",
	'description'   = "//Gene-ref_desc",
	'symbol'        = "//Gene-ref_locus",
	'synonyms'      = "//Gene-ref_syn_E"
)

# Class declaration {{{1
################################################################

#' @include NcbiEntrezConn.R
#' @include CompounddbConn.R
NcbiGeneConn <- methods::setRefClass("NcbiGeneConn", contains = c('NcbiEntrezConn', 'CompounddbConn'))

# Constructor {{{1
################################################################

NcbiGeneConn$methods( initialize = function(...) {

	callSuper(entrez.name = 'gene', entrez.tag = 'Entrezgene', entrez.id.tag = 'Gene-track_geneid', ...)
})

# Get entry page url {{{1
################################################################

NcbiGeneConn$methods( getEntryPageUrl = function(id) {
	return(paste0(.self$getBaseUrl(), .self$.entrez.name, '/?term=', id))
})

# Get entry image url {{{1
################################################################

NcbiGeneConn$methods( getEntryImageUrl = function(id) {
	return(rep(NA_character_, length(id)))
})

# Search compound {{{1
################################################################

NcbiGeneConn$methods( searchCompound = function(name = NULL, mass = NULL, mass.field = NULL, mass.tol = 0.01, mass.tol.unit = 'plain', max.results = NA_integer_) {
		
	.self$.checkMassField(mass = mass, mass.field = mass.field)

	ids <- NULL

	# Search by name
	if ( ! is.null(name))
		term <- paste0('"', name, '"', '[Gene Name]')

	# Search by mass
	if ( ! is.null(mass.field))
		.self$message('caution', 'Search by mass is not possible.')

	# Set retmax
	if (is.na(max.results)) {
		xml <- .self$ws.esearch(term = term, retmax = 0, biodb.parse = TRUE)
		retmax <- as.integer(XML::xpathSApply(xml, "/eSearchResult/Count", XML::xmlValue))
		if (length(retmax) == 0)
			retmax = NA_integer_
	}
	else
		retmax <- max.results

	# Send request
	ids <- .self$ws.esearch(term = term, retmax = retmax, biodb.ids = TRUE)

	return(ids)
})

# Private methods {{{1
################################################################

# Get parsing expressions {{{2
################################################################

NcbiGeneConn$methods( .getParsingExpressions = function() {
	return(.BIODB.NCBI.GENE.PARSING.EXPR)
})
