# vi: fdm=marker

# Class declaration {{{1
################################################################

#' A class for handling file caching.
#'
#' This class manages a cache system for saving downloaded files and request results. It is designed for internal use, but you can still access some of the read-only methods if you wish.
#'
#' @param content       A \code{character vector} containing contents to save.
#' @param conn.id       The ID of a database. The list of IDs can be obtained from the class \code{\link{BiodbDbsInfo}}.
#' @param ext           The extension of the file, without the dot: 'html', 'xml', etc.
#' @param extract.name  Instead of returning the file paths, returns the list of names used to construct the file name: [cache_folder]/[subfolder]/[connid]-[name].[ext].
#' @param name          The name of the file or the marker. Vector of characters. Length can be greater than one.
#' @param output.vector Force output to be a \code{vector} instead of a \code{list}. Where the list contains a \code{NULL}, the \code{vector} will contain a \code{NA} value.
#' @param subfolder     The subfolder inside the cache system. Supported values are: 'shortterm' and 'longterm'. The 'shortterm' folder contains individual entry files. The 'longterm' folder contains zip files of whole databases.
#'
#' @seealso \code{\link{Biodb}}.
#'
#' @examples
#' # Create an instance with default settings:
#' mybiodb <- biodb::Biodb()
#'
#' # Get the cache instance:
#' cache <- mybiodb$getCache()
#'
#' # Get list of files inside the cache:
#' files <- cache$listFiles('chebi', 'shortterm')
#'
#' # Delete files inside the cache:
#' cache$deleteFiles('chebi', 'shortterm')
#'
#' @import methods
#' @include ChildObject.R
#' @export BiodbCache
#' @exportClass BiodbCache
BiodbCache <- methods::setRefClass("BiodbCache", contains = 'ChildObject')

# Constructor {{{1
################################################################

BiodbCache$methods( initialize = function(...) {

	callSuper(...)
})

# Get directory {{{1
################################################################

BiodbCache$methods( getDir = function() {
	":\n\nGet the absolute path to the cache directory."

	cachedir <- .self$getBiodb()$getConfig()$get('cache.directory')

	# Create cache dir if needed
	if ( ! is.na(cachedir) && ! file.exists(cachedir))
		dir.create(cachedir)

	return(cachedir)
})

# Is readable {{{1
################################################################

BiodbCache$methods( isReadable = function() {
	":\n\nReturns TRUE if the cache system is readable."

	return( .self$getBiodb()$getConfig()$isEnabled('cache.system') && ! is.na(.self$getDir()))
})

# Is writable {{{1
################################################################

BiodbCache$methods( isWritable = function() {
	":\n\nReturns TRUE if the cache system is writable."

	return( .self$getBiodb()$getConfig()$isEnabled('cache.system') && ! is.na(.self$getDir()) && ! .self$getBiodb()$getConfig()$get('cache.read.only'))
})

# File exists {{{1
################################################################

BiodbCache$methods( fileExist = function(conn.id, subfolder, name, ext) {
	":\n\nTest if files exist in the cache."

	exists <- file.exists(.self$getFilePath(conn.id, subfolder, name, ext))

	return(exists)
})

# Marker exists {{{1
################################################################

BiodbCache$methods( markerExist = function(conn.id, subfolder, name) {
	":\n\nTest if markers exist in the cache. Markers are used, for instance, by biodb to remember that a downloaded zip file from a database has been extracted correctly."

	return(.self$fileExist(conn.id = conn.id, subfolder = subfolder, name = name, ext = 'marker'))
})

# Set marker {{{1
################################################################

BiodbCache$methods( setMarker = function(conn.id, subfolder, name) {
	":\n\nSet a marker."

	marker.path <- .self$getFilePath(conn.id = conn.id, subfolder = subfolder, name = name, ext = 'marker')

	writeChar('', marker.path)
})

# Get file paths {{{1
################################################################

BiodbCache$methods( getFilePath = function(conn.id, subfolder, name, ext) {
	":\n\nGet path of file in cache system."

	# Set file path
	filepaths <- file.path(.self$getSubFolderPath(subfolder), paste(conn.id, '-', name, '.', ext, sep = ''))

	# Set NA values
	filepaths[is.na(name)] <- NA_character_

	return(filepaths)
})

# Load file content {{{1
################################################################

BiodbCache$methods( loadFileContent = function(conn.id, subfolder, name, ext, output.vector = FALSE) {
	":\n\nLoad content of files from the cache."

	if ( ! .self$isReadable())
		.self$message('error', paste("Attempt to read from non-readable cache \"", .self$getDir(), "\".", sep = ''))

	content <- NULL

	# Read contents from files
	file.paths <- .self$getFilePath(conn.id, subfolder, name, ext)
	.self$message('debug', paste("Trying to load from cache \"", paste(if (length(file.paths) > 10) c(file.paths[1:10], '...') else file.paths, collapse = ", ") ,"\".", sep = ''))
	content <- lapply(file.paths, function(x) { if (is.na(x)) NA_character_ else ( if (file.exists(x)) readChar(x, file.info(x)$size, useBytes = TRUE) else NULL )} )
	files.read <- file.paths[ ! vapply(content, is.null, FUN.VALUE = T)]
	if (length(files.read) == 0)
		.self$message('debug', "No files loaded from cache.")
	else
		.self$message('debug', paste("Loaded from cache \"", paste(if (length(files.read) > 10) c(files.read[1:10], '...') else files.read, collapse = ", ") ,"\".", sep = ''))

	# Check that the read content is not conflicting with the current locale
	for (i in seq(content)) {
		n <- tryCatch(nchar(content[[i]]), error = function(e) NULL)
		if (is.null(n)) {
			.self$message('caution', paste("Error when reading content of file \"", file.paths[[i]], "\". The function `nchar` returned an error on the content. The file may be written in a unexpected encoding. Trying latin-1...", sep = ''))
			# The encoding may be wrong, try another one. Maybe LATIN-1
			content[[i]] <- iconv(content[[i]], "iso8859-1")
			n <- tryCatch(nchar(content[[i]]), error = function(e) NULL)
			if (is.null(n))
				.self$message('error', paste("Impossible to handle correctly the content of file \"", file.paths[[i]], "\". The encoding of this file is unknown.", sep = ''))
		}
	}

	# Set to NA
	content[content == 'NA' | content == "NA\n"] <- NA_character_

	# Vector ?
	if (output.vector)
		content <- vapply(content, function(x) if (is.null(x)) NA_character_ else x, FUN.VALUE = '')

	return(content)
})

# Save content into file {{{1
################################################################

BiodbCache$methods( saveContentToFile = function(content, conn.id, subfolder, name, ext) {
	":\n\nSave content to files into the cache."

	if ( ! .self$isWritable())
		.self$message('error', paste("Attempt to write into non-writable cache. \"", .self$getDir(), "\".", sep = ''))

	# Get file paths
	file.paths <- .self$getFilePath(conn.id, subfolder, name, ext)

	# Check that we have the same number of content and file paths
	if (length(file.paths) != length(content))
		.self$message('error', paste("The number of content to save (", length(content), ") is different from the number of paths (", length(file.paths), ").", sep = ''))

	# Replace NA values with 'NA' string
	content[is.na(content)] <- 'NA'

	# Write content to files
	.self$message('debug', paste("Saving to cache \"", paste(if (length(file.paths) > 10) c(file.paths[1:10], '...') else file.paths, collapse = ", ") ,"\".", sep = ''))
	mapply(function(c, f) { if ( ! is.null(c)) cat(c, file = f) }, content, file.paths) # Use cat instead of writeChar, because writeChar was not working with some unicode string (wrong string length).
})

# Get subfolder path {{{1
################################################################

BiodbCache$methods( getSubFolderPath = function(subfolder) {
	":\n\nGet the absolute path of a subfolder inside the cache system."

	folder.path <- .self$.get.subfolder.path(subfolder)

	# Create folder if needed
	if ( ! is.na(folder.path) && ! file.exists(folder.path))
		dir.create(folder.path)

	return(folder.path)
})

# Erase folder {{{1
################################################################

BiodbCache$methods( eraseFolder = function(subfolder = NA_character_) {

	# Erase whole cache				    
	if (is.na(subfolder) || ! .self$getBiodb()$getConfig()$isEnabled('cache.subfolders'))
		folder.to.erase <- .self$getDir()

 	# Erase subfolder
	else
		folder.to.erase <- .self$.get.subfolder.path(subfolder)

	# Erase
	.self$message('info', paste("Erasing cache folder ", folder.to.erase, ".", sep = ''))
	unlink(folder.to.erase, recursive = TRUE)
})

# Delete files {{{1
################################################################

BiodbCache$methods( deleteFiles = function(conn.id, subfolder, ext = NA_character_) {
	":\n\nDelete files inside the cache system."

	files <- paste(conn.id, '*',sep = '-')
	if ( ! is.na(ext))
		files <- paste(files, ext, sep = '.')

	unlink(file.path(.self$getSubFolderPath(subfolder), files))
})

# List files {{{1
################################################################

BiodbCache$methods( listFiles = function(conn.id, subfolder, ext = NA_character_, extract.name = FALSE) {
	":\n\nList files present in the cache system."

	# Pattern
	pattern <- paste('^', conn.id, '-.*', sep = '')
	if ( ! is.na(ext))
		pattern <- paste(pattern, ext, sep = '\\.')
	pattern <- paste(pattern, '$', sep = '')

	# List files
	dir <- .self$getSubFolderPath(subfolder)
	.self$message('debug', paste("List files in", dir, "using pattern ", pattern))
	files <- list.files(path = dir, pattern = pattern)

	# Extract only the name part
	if (extract.name) {
		pattern <- paste('^', conn.id, '-(.*)', sep = '')
		if ( ! is.na(ext))
			pattern <- paste(pattern, ext, sep = '\\.')
		pattern <- paste(pattern, '$', sep = '')
		files <- sub(pattern, '\\1', files, perl = TRUE)
	}

	return(files)
})

# Show {{{1
################################################################

BiodbCache$methods( show = function() {
	cat("Biodb cache system instance.\n")
	cat("  The cache is ", (if (.self$isReadable()) "" else "not "), "readable.\n", sep = '')
	cat("  The cache is ", (if (.self$isWritable()) "" else "not "), "writable.\n", sep = '')
})

# PRIVATE METHODS {{{1
################################################################

BiodbCache$methods( .get.subfolder.path = function(subfolder) {

	cfg.subfolder.key <- paste(subfolder, 'cache', 'subfolder', sep = '.')

	# Check subfolder
	if ( ! .self$getBiodb()$getConfig()$isDefined(cfg.subfolder.key))
		.self$message('error', paste("Unknown cache folder \"", folder, "\".", sep = ''))

	# Get subfolder path
	if (.self$getBiodb()$getConfig()$isEnabled('cache.subfolders'))
		folder.path <- file.path(.self$getDir(), .self$getBiodb()$getConfig()$get(cfg.subfolder.key))
	else
		folder.path <- .self$getDir()
})

# DEPRECATED METHODS {{{1
################################################################

# Enabled {{{2
################################################################

BiodbCache$methods( enabled = function() {

	.self$.deprecated.method("BiodbConfig::isEnabled('cache.system')")

	return(.self$getBiodb()$getConfig()$isEnabled('cache.system'))
})

# Enable {{{2
################################################################

BiodbCache$methods( enable = function() {

	.self$.deprecated.method("BiodbConfig::enable('cache.system')")
	
	.self$getBiodb()$getConfig()$enable('cache.system')
})

# Disable {{{2
################################################################

BiodbCache$methods( disable = function() {

	.self$.deprecated.method("BiodbConfig::disable('cache.system')")
	
	.self$getBiodb()$getConfig()$disable('cache.system')
})
