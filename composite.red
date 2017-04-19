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
		err-val "If not none, return this instead of formed error information, if eval fails"
		/local res
	][
		either error? set/any 'res try [do expr][
			any [err-val  form reduce [" *** Error:" res/id "Where:" expr "*** "]]
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
		/err-val e "Use instead of formed error info from eval error"
		/local expr
	][
		data: either string? data [copy data] [read data]	; Don't modify the input
		parse data [
			any [
				end break
				| change [expr-beg= copy expr to expr-end= expr-end=] (eval expr e)
				| expr-beg= to end
				| to expr-beg=
			]
		]
		data
	]

]
