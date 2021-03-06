# vi: fdm=marker

# Class declaration {{{1
################################################################

#' An abstract class (more like an interface) to model a writable database.
#'
#' A database class that implements this interface must allow the addition of new entries.
#'
#' @param entry An entry instance.
#'
#' @import methods
#' @include BiodbObject.R
#' @export BiodbWritable
#' @exportClass BiodbWritable
BiodbWritable <- methods::setRefClass("BiodbWritable", contains = 'BiodbObject', fields = list(.writing.allowed = 'logical'))

# Constructor {{{1
################################################################

BiodbWritable$methods( initialize = function(...) {

	callSuper(...)
	.self$.abstract.class('BiodbWritable')

	# This constructor is never called, because this class is used as an interface (i.e.: it is declared in the "contains" field of another class, in second position or greater. Only the constructor of the first declared "contained" class is called.).
})

# Writing is allowed {{{1
################################################################

BiodbWritable$methods( writingIsAllowed = function() {
	":\n\nReturns TRUE if writing is allowed for this database."
	
	.self$.initWritable()

	return(.self$.writing.allowed)
})

# Allow writing {{{1
################################################################

BiodbWritable$methods( allowWriting = function() {
	":\n\nAllow writing for this database."

	.self$setWritingAllowed(TRUE)
})

# Disallow writing {{{1
################################################################

BiodbWritable$methods( disallowWriting = function() {
	":\n\nDisallow writing for this database."
	
	.self$setWritingAllowed(FALSE)
})

# Set writing allowed {{{1
################################################################

BiodbWritable$methods( setWritingAllowed = function(allow) {
	":\n\nAllow or disallow writing for this database."
	
	.self$.assert.is(allow, 'logical')
	.writing.allowed <<- allow
})

# Write {{{1
################################################################

BiodbWritable$methods( write = function() {
	":\n\nWrite the database. All modifications made to the database since the last time write() was called will be saved."

	.self$.checkWritingIsAllowed()
	.self$.doWrite()

	# Unset "new" flag for all entries
	for (e in .self$.entries)
		e$.setAsNew(FALSE)
})

# Private methods {{{1
################################################################

# Check that writing is allowed {{{2
################################################################

BiodbWritable$methods( .checkWritingIsAllowed = function() {
	
	.self$.initWritable()
	
	if ( ! .self$.writing.allowed)
		.self$message('error', 'Writing is not enabled for this database. However this database type is writable. Please call allowWriting() method to enable writing.')
})

# Do write {{{2
################################################################

BiodbWritable$methods( .doWrite = function() {
	.self$.abstract.method()
})

# Init parameters {{{2
################################################################

BiodbWritable$methods( .initWritable = function() {
	if (length(.self$.writing.allowed) == 0)
		.self$setWritingAllowed(FALSE)
})
