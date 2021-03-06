# vi: fdm=marker

#' @include BiodbEntry.R

# Class declaration {{{1
################################################################

XmlEntry <- methods::setRefClass("XmlEntry", contains = "BiodbEntry", fields = list())

# Constructor {{{1
################################################################

XmlEntry$methods( initialize = function(...) {

	callSuper(...)
	.self$.abstract.class('XmlEntry')
})

# Do parse content {{{1
################################################################

XmlEntry$methods( .doParseContent = function(content) {

	# Parse XML
	xml <-  XML::xmlInternalTreeParse(content, asText = TRUE)

	return(xml)
})

# Parse fields from expressions {{{1
################################################################

XmlEntry$methods( .parseFieldsFromExpr = function(parsed.content) {

	# Get parsing expressions
	parsing.expr <- .self$getParent()$.getParsingExpressions()

	# Set namespace
	xml.ns <- .self$getParent()$getXmlNs()
	ns <- if (is.null(xml.ns) || is.na(xml.ns)) XML::xmlNamespaceDefinitions(parsed.content, simplify = TRUE) else c(ns = xml.ns)

	# Loop on all parsing expressions
	for (field in names(parsing.expr)) {

		# Expression using only path
		if (is.character(parsing.expr[[field]])) {

			field.single.value <- .self$getBiodb()$getEntryFields()$get(field)$hasCardOne()
			value <- NULL

			# Loop on all expressions
			for (expr in parsing.expr[[field]]) {

				# Parse
				v <- XML::xpathSApply(parsed.content, expr, XML::xmlValue, namespaces = ns)

				# The field accepts only one value
				if (field.single.value) {
					value <- v
					if (length(value) > 0)
						break
				}

				# The field accepts more than one value
				else
					value <- c(value, v)
			}
		}

		# Expression using path and attribute
		else
			value <- XML::xpathSApply(parsed.content, parsing.expr[[field]]$path, XML::xmlGetAttr, parsing.expr[[field]]$attr, namespaces = ns)

		# Set value
		if (length(value) > 0)
			.self$setFieldValue(field, value)
	}
})
