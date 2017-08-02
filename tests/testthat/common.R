# vi: fdm=marker

# Constants {{{1
################################################################

TEST.DIR <- file.path(getwd(), '..')
OUTPUT.DIR <- file.path(TEST.DIR, 'output')
RES.DIR  <- file.path(TEST.DIR, 'res')
REF.FILES.DIR <- file.path(RES.DIR, 'ref-files')
OFFLINE.CACHE.DIR <- file.path(RES.DIR, 'offline-cache')
ONLINE.CACHE.DIR <- file.path(TEST.DIR, 'cache')
LOG.FILE.PATH <- file.path(TEST.DIR, 'test.log')
USERAGENT <- 'biodb.test ; pierrick.rogermele@icloud.com'

MASSFILEDB.URL <- file.path(RES.DIR, 'mass.csv.file.tsv')

# Create output directory
if ( ! file.exists(OUTPUT.DIR))
	dir.create(OUTPUT.DIR)

# Set databases to test {{{1
################################################################

DATABASES.ALL <- 'all'
DATABASES.NONE <- 'none'

env <- Sys.getenv()
TEST.DATABASES <- biodb::Biodb$new(logger = FALSE)$getDbsInfo()$getIds()
if ('DATABASES' %in% names(env) && nchar(env[['DATABASES']]) > 0) {
	if (env[['DATABASES']] == DATABASES.NONE)
		TEST.DATABASES <- character(0)
	else if (env[['DATABASES']] == DATABASES.ALL)
		TEST.DATABASES <- biodb::Biodb$new(logger = FALSE)$getDbsInfo()$getIds()
	else {
		TEST.DATABASES <- strsplit(env[['DATABASES']], ',')[[1]]
		db.exists <- vapply(TEST.DATABASES, function(x) biodb::Biodb$new(logger = FALSE)$getDbsInfo()$isDefined(x), FUN.VALUE = TRUE)
		if ( ! all(db.exists)) {
			wrong.dbs <- TEST.DATABASES[ ! db.exists]
			stop(paste('Unknown testing database(s) ', paste(wrong.dbs, collapse = ', ')), '.', sep = '')
		}
	}
}

# Set testing modes {{{1
################################################################

MODE.OFFLINE <- 'offline'
MODE.ONLINE <- 'online'
MODE.QUICK.ONLINE <- 'quick.online'
MODE.ALL <- 'all'
MODE.FULL <- 'full'
DEFAULT.MODES <- MODE.OFFLINE
ALLOWED.MODES <- c(MODE.ONLINE, MODE.QUICK.ONLINE, MODE.OFFLINE)
if ('MODES' %in% names(env) && nchar(env[['MODES']]) > 0) {
	if (env[['MODES']] %in% c(MODE.ALL, MODE.FULL))
		TEST.MODES <- ALLOWED.MODES
	else {
		TEST.MODES <- strsplit(env[['MODES']], ',')[[1]]
		mode.exists <- TEST.MODES %in% ALLOWED.MODES
		if ( ! all(mode.exists)) {
			wrong.modes <- TEST.MODES[ ! mode.exists]
			stop(paste('Unknown testing mode(s) ', paste(wrong.modes, collapse = ', ')), '.', sep = '')
		}
	}
} else {
	TEST.MODES <- DEFAULT.MODES
}

# Set test functions {{{1
################################################################

FUNCTION.ALL <- 'all'
if ('FUNCTIONS' %in% names(env)) {
	TEST.FUNCTIONS <- env[['FUNCTIONS']]
} else {
	TEST.FUNCTIONS <- FUNCTION.ALL
}

# Create Biodb instance {{{1
################################################################

create.biodb.instance <- function() {

	# Create instance
	biodb <- Biodb$new(logger = FALSE, observers = BiodbLogger$new(file = LOG.FILE.PATH, mode = 'a'))

	# Set user agent
	biodb$getConfig()$set('useragent', USERAGENT)

	# Set Peakforest URL and token
	if ('BIODB_PEAKFOREST_ALPHA_TOKEN' %in% names(env))
		for (db in c('peakforest.mass', 'peakforest.compound')) {
			biodb$getDbsInfo()$get(db)$setBaseUrl('https://peakforest-alpha.inra.fr/rest/')
			biodb$getDbsInfo()$get(db)$setToken(env[['BIODB_PEAKFOREST_ALPHA_TOKEN']])
		}

	return(biodb)
}
# Set test context {{{1
################################################################

set.test.context <- function(biodb, text) {

	# Set testthat context
	context(text)

	# Print banner in log file
	biodb$message(MSG.INFO, "")
	biodb$message(MSG.INFO, "****************************************************************")
	biodb$message(MSG.INFO, paste("Test context", text, sep = " - "))
	biodb$message(MSG.INFO, "****************************************************************")
	biodb$message(MSG.INFO, "")
}

# Set mode {{{1
################################################################

set.mode <- function(biodb, mode) {

	# Online
	if (mode == MODE.ONLINE) {
		biodb$getConfig()$set('cache.directory', ONLINE.CACHE.DIR)
		biodb$getConfig()$disable('cache.read.only')
		biodb$getConfig()$enable('allow.huge.downloads')
		biodb$getConfig()$disable('offline')
		biodb$getConfig()$enable('cache.subfolders')
	}

	# Quick online
	else if (mode == MODE.QUICK.ONLINE) {
		biodb$getConfig()$set('cache.directory', ONLINE.CACHE.DIR)
		biodb$getConfig()$disable('cache.read.only')
		biodb$getConfig()$disable('allow.huge.downloads')
		biodb$getConfig()$disable('offline')
		biodb$getConfig()$enable('cache.subfolders')
	}

	# Offline
	else if (mode == MODE.OFFLINE) {
		biodb$getConfig()$set('cache.directory', OFFLINE.CACHE.DIR)
		biodb$getConfig()$enable('cache.read.only')
		biodb$getConfig()$disable('allow.huge.downloads')
		biodb$getConfig()$enable('offline')
		biodb$getConfig()$disable('cache.subfolders')
	}

	# Unknown mode
	else {
		stop(paste("Unknown mode \"", mode, "\".", sep = "."))
	}
}

# Load reference entries {{{1
################################################################

load.ref.entries <- function(db) {

	# Define reference file
	entries.file <- file.path(RES.DIR, paste0(db, '-entries.txt'))
	expect_true(file.exists(entries.file), info = paste0("Cannot find file \"", entries.file, "\"."))

	# Load reference contents from file
	entries.desc <- read.table(entries.file, stringsAsFactors = FALSE, header = TRUE)
	expect_true(nrow(entries.desc) > 0, info = paste0("No reference entries found in file \"", entries.file, "\" in test.entry.fields()."))

	return(entries.desc)
}

# Initialize MassCsvFile db {{{1
################################################################

init.mass.csv.file.db <- function(biodb) {
	db.instance <- biodb$getFactory()$createConn(BIODB.MASS.CSV.FILE, url = MASSFILEDB.URL)
	db.instance$setField('accession', c('compound.id', 'ms.mode', 'chrom.col', 'chrom.col.rt'))
}

# Run database test {{{1
################################################################

run.db.test <- function(msg, fct, db) {
	if (TEST.FUNCTIONS == FUNCTION.ALL || TEST.FUNCTIONS == fct)
		test_that(msg, do.call(fct, list(db)))
}