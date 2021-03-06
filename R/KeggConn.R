# vi: fdm=marker

# Class declaration {{{1
################################################################

#' The connector abstract class to KEGG databases.
#'
#' This is the mother class of all KEGG connectors. It defines code common to all KEGG connectors.
#'
#' @param query The query to send to the database web service.
#'
#' @seealso \code{\link{BiodbFactory}}, \code{\link{RemotedbConn}}.
#'
#' @examples
#' # Create an instance with default settings:
#' mybiodb <- biodb::Biodb()
#'
#' # Create a connector to a KEGG database
#' conn <- mybiodb$getFactory()$createConn('kegg.compound')
#' 
#' # Search for an entry
#' conn$ws.find.df('NADPH')
#'
#' @include RemotedbConn.R
#' @export KeggConn
#' @exportClass KeggConn
KeggConn <- methods::setRefClass("KeggConn", contains = "RemotedbConn", fields = list(.db.name = "character", .db.abbrev = "character"))

# Constructor {{{1
################################################################

KeggConn$methods( initialize = function(db.name = NA_character_, db.abbrev = NA_character_, ...) {

	callSuper(...)
	.self$.abstract.class('KeggConn')

	# Set name
	if (is.null(db.name) || is.na(db.name))
		.self$message('error', "You must set a name for this KEGG database.")
	.db.name <<- db.name

	# Set abbreviation
	if (is.null(db.abbrev) || is.na(db.abbrev))
		.self$message('error', "You must set an abbreviation for this KEGG database.")
	.db.abbrev <<- db.abbrev
})

# Complete entry id {{{1
################################################################

KeggConn$methods( .complete.entry.id = function(id) {
	return(paste(.self$.db.abbrev, id, sep = ':'))
})

# Get entry content url {{{1
################################################################

KeggConn$methods( .doGetEntryContentUrl = function(id, concatenate = TRUE) {
	return(paste(.self$getWsUrl(), 'get/', .self$.complete.entry.id(id), sep = ''))
})

# Get entry page url {{{1
################################################################

KeggConn$methods( getEntryPageUrl = function(id) {
	return(paste('https://www.genome.jp/dbget-bin/www_bget?', .self$.complete.entry.id(id), sep = ''))
})


# Get entry ids {{{1
################################################################

KeggConn$methods( getEntryIds = function(max.results = NA_integer_) {

	# Get IDs
	ids <- .self$.get.url(paste(.self$getWsUrl(), 'list/', .self$.db.name, sep = ''))

	# Extract IDs
	ids <- strsplit(ids, "\n")[[1]]
	#ids <- sub('^[^:]+:([^\\s]+)\\s.*$', '\\1', ids, perl = TRUE)
	ids <- sub('^[^:]+:([^\\s]+)\\s.*$', '\\1', ids, perl = TRUE)

	# Cut results
	if ( ! is.na(max.results) && max.results > 0)
		ids <- ids[1:max.results]

	return(ids)
})

# Web service find {{{1
################################################################

KeggConn$methods( ws.find = function(query) {
	":\n\nSearch for entries. See http://www.kegg.jp/kegg/docs/keggapi.html for details."

	url <- paste(.self$getWsUrl(), 'find/', .self$.db.name, '/', query, sep = '')

	result <- .self$.getUrlScheduler()$getUrl(url)

	return(result)
})

# Web service find DF {{{1
################################################################

KeggConn$methods( ws.find.df = function(...) {
	":\n\nCalls ws.find() and returns a data frame."

	results <- .self$ws.find(...)

	readtc <- textConnection(results, "r", local = TRUE)
	df <- read.table(readtc, sep = "\t", quote = '', stringsAsFactors = FALSE)

	return(df)
})

# Web service find IDs {{{1
################################################################

KeggConn$methods( ws.find.ids = function(...) {
	":\n\nCalls ws.find() but only for getting IDs. Returns the IDs as a character vector."

	df <- .self$ws.find.df(...)

	return(df[[1]])
})
