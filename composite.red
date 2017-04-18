Red [
	Author: "Gregg Irwin"
	Purpose: "COMPOSE for strings"
	Notes: {
		TBD: Security model for eval'ing expressions
	}
]

composite-ctx: context [

	eval: func [
		"Evaluate expr and return the result"
		expr [string!] "Valid Red, as a string expression"
		hide-err [logic!] "Return empty string instead of error information"
		/local res
	][
		either error? set/any 'res try [do expr][
			either hide-err [""][
				form reduce [" *** Error:" res/id "Where:" expr "*** "]
			]
		][
			either unset? get/any 'res [""][:res]
		]
	]

	; Putting the colons on the outside gives you a clean paren expression
	; on the inside.
	expr-beg=: ":("
	expr-end=: "):"
	
	; One of the big questions is what to do if there are mismatched expr
	; markers. We can treat them as errors, or just pass through them, so
	; they will be visible in the output. We can support both behaviors
	; with a refinement, and then just have to choose the default.
	set 'composite func [
		"Replace :( ... ): sections with their evaluated results."
		data [string! file! url!]
		/hide-errors "Suppress error output"
		/local expr
	][
		data: either string? data [copy data] [read data]	; Don't modify the input
		parse data [
			any [
				end break
				| change [expr-beg= copy expr to expr-end= expr-end=] (eval expr hide-errors)
				| expr-beg= to end
				| to expr-beg=
			]
		]
		data
	]

]

test-composite: func [input][
	print [mold input "==" mold composite input]
]
test-composite-no-err: func [input][
	print [mold input "==" mold composite/hide-errors input]
]
