# vi: fdm=marker

# Class declaration {{{1
################################################################

#' An interface for all compound databases.
#'
#' This interface must be inherited by all compound databases. It declares method headers specific to compound databases.
#'
#' @param name              The name of a compound.
#' @param mass              The searched mass.
#' @param mass.field        The mass field to use for the search. For instance: 'molecular.mass', 'monoisotopic.mass', 'average.mass'.
#' @param mass.tol          The tolerance on the molecular mass.
#' @param mass.tol.unit     The unit used for molecular mass tolerance. Either 'plain' or 'ppm'.
#' @param max.results       The maximum number of matches wanted.
#'
#' @seealso \code{\link{BiodbConn}}.
#'
#' @examples
#' # Create an instance with default settings:
#' mybiodb <- biodb::Biodb()
#'
#' # Get the connector of a compound database
#' uniprot <- mybiodb$getFactory()$createConn('uniprot')
#'
#' # Search for compounds
#' uniprot$searchCompound(name = 'prion protein', max.results = 10)
#'
#' @include BiodbConn.R
#' @export CompounddbConn
#' @exportClass CompounddbConn
CompounddbConn <- methods::setRefClass("CompounddbConn", contains = "BiodbConn")

# Constructor {{{1
################################################################

CompounddbConn$methods( initialize = function(...) {

	callSuper(...)
	.self$.abstract.class('CompounddbConn')
})

# Search compound {{{1
################################################################

CompounddbConn$methods( searchCompound = function(name = NULL, mass = NULL, mass.field = NULL, mass.tol = 0.01, mass.tol.unit = 'plain', max.results = NA_integer_) {
	":\n\nSearch for compounds by name and/or by mass. For searching by mass, you must indicate a mass field to use ('monoisotopic.mass', 'molecular.mass', ...)"

	.self$.abstract.method()
})

# PRIVATE {{{1
################################################################

# Check mass field {{{2
################################################################

CompounddbConn$methods( .checkMassField = function(mass, mass.field) {

	if ( ! is.null(mass)) {
		.self$.assert.is(mass, c('integer', 'numeric'))
		.self$.assert.not.null(mass.field)
		.self$.assert.is(mass.field, 'character')
		.self$.assert.in(mass.field, .self$getBiodb()$getEntryFields()$getFieldNames(type = 'mass'))
	}
})
