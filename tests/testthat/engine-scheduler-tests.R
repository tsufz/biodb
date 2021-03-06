# vi: fdm=marker

# Test right rule {{{1
################################################################

test.schedulerRightRule <- function(biodb, obs) {

	# Delete all connectors
	biodb$getFactory()$deleteAllConnectors()

	# Get scheduler
	scheduler <- biodb$getRequestScheduler()

	# Get ChEBI connector
	chebi <- biodb$getFactory()$getConn('chebi')

	# Get connector rule
	rules <- scheduler$.getConnectorRules(chebi)
	testthat::expect_is(rules, 'list')
	testthat::expect_length(rules, 1)
	testthat::expect_is(rules[[1]], 'BiodbRequestSchedulerRule')
	testthat::expect_length(rules[[1]]$getConnectors(), 1)
	testthat::expect_identical(rules[[1]]$getConnectors()[[1]], chebi)
	testthat::expect_equal(rules[[1]]$getN(), chebi$getSchedulerNParam())
	testthat::expect_equal(rules[[1]]$getT(), chebi$getSchedulerTParam())
}

# Test rule frequency {{{1
################################################################

test.schedulerRuleFrequency <- function(biodb, obs) {

	# Delete all connectors
	biodb$getFactory()$deleteAllConnectors()

	# Get scheduler
	scheduler <- biodb$getRequestScheduler()

	# Get ChEBI connector
	chebi <- biodb$getFactory()$getConn('chebi')
	chebi$setSchedulerNParam(3)
	chebi$setSchedulerTParam(1)

	# Get connector rule
	rules <- scheduler$.getConnectorRules(chebi)
	testthat::expect_is(rules, 'list')
	testthat::expect_length(rules, 1)
	rule <- rules[[1]]
	testthat::expect_is(rule, 'BiodbRequestSchedulerRule')
	testthat::expect_equal(rule$getN(), chebi$getSchedulerNParam())
	testthat::expect_equal(rule$getT(), chebi$getSchedulerTParam())

	# Create another ChEBI connector
	chebi.2 <- biodb$getFactory()$createConn('chebi', fail.if.exists = FALSE)
	testthat::expect_length(scheduler$.getConnectorRules(chebi.2), 1)
	testthat::expect_identical(rule, scheduler$.getConnectorRules(chebi.2)[[1]])
	testthat::expect_equal(rule$getN(), chebi$getSchedulerNParam())
	testthat::expect_equal(rule$getT(), chebi$getSchedulerTParam())

	# Change frequency of second connector
	n <- rule$getN()
	chebi.2$setSchedulerNParam(n + 1)
	testthat::expect_equal(rule$getN(), n)
	chebi.2$setSchedulerNParam(n - 1)
	testthat::expect_equal(rule$getN(), n - 1)
	chebi.2$setSchedulerNParam(n)
	testthat::expect_equal(rule$getN(), n)
	t <- rule$getT()
	chebi.2$setSchedulerTParam(t + 0.5)
	testthat::expect_equal(rule$getT(), t + 0.5)
	chebi.2$setSchedulerTParam(t - 0.5)
	testthat::expect_equal(rule$getT(), t)
	chebi.2$setSchedulerTParam(t * 2)
	chebi.2$setSchedulerNParam(n * 2)
	testthat::expect_equal(rule$getN(), n)
	testthat::expect_equal(rule$getT(), t)
}

# Test scheduler sleep time {{{1
################################################################

test.schedulerSleepTime <- function(biodb, obs) {

	n <- 3
	t <- 1.0

	# Delete all connectors
	biodb$getFactory()$deleteAllConnectors()

	# Get scheduler
	scheduler <- biodb$getRequestScheduler()

	# Get ChEBI connector
	chebi <- biodb$getFactory()$getConn('chebi')
	chebi$setSchedulerNParam(n)
	chebi$setSchedulerTParam(t)

	# Get connector rule
	rules <- scheduler$.getConnectorRules(chebi)
	testthat::expect_is(rules, 'list')
	testthat::expect_length(rules, 1)
	rule <- rules[[1]]
	testthat::expect_is(rule, 'BiodbRequestSchedulerRule')

	# Test sleep time
	cur.time <- Sys.time()
	for (i in seq(n)) {
		tt <- cur.time + (i - 1) * t / 10
		testthat::expect_equal(rule$computeSleepTime(tt), 0)
		rule$storeCurrentTime(tt)
	}
	testthat::expect_equal(rule$computeSleepTime(cur.time), t)
	testthat::expect_true(abs(rule$computeSleepTime(cur.time + t - 0.1) - 0.1) < 1e-6)
	testthat::expect_equal(rule$computeSleepTime(cur.time + t), 0)
	rule$storeCurrentTime(cur.time + t)
	testthat::expect_true(abs(rule$computeSleepTime(cur.time + t) - t / 10) < 1e-6)
}

# Run scheduler tests {{{1
################################################################

run.scheduler.tests <- function(biodb, obs) {

	set.test.context(biodb, "Test request scheduler")

	run.test.that.on.biodb.and.obs("Right rule is created.", 'test.schedulerRightRule', biodb, obs)
	run.test.that.on.biodb.and.obs("Frequency is updated correctly.", 'test.schedulerRuleFrequency', biodb, obs)
	run.test.that.on.biodb.and.obs("Sleep time is computed correctly.", 'test.schedulerSleepTime', biodb, obs)
}
