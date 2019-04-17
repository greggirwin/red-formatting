Red [
	Author: [@greggirwin @endo @toomasv @hiiamboris]
	Purpose: "COMPOSE for strings"
	Notes: {
		TBD: Security model for eval'ing expressions
		TBD: Decide if support for custom marker and eval contexts are worthwhile
		TBD: Finalize refinement names
		TBD: Decide if suport for function contexts is worthwhile
		TBD: Make it a macro?
	}
]

composite-ctx: context [

	eval: func [
		"Evaluate expr and return the result"
		expr [string!] "Valid Red, as a string expression"
		err-val "If not none, return this instead of formed error information, if eval fails"
		ctx [none! object! function!] "Evaluate expr in the given context; none means use global context"
		/local res
	][
		if error? set/any 'res try [expr: load expr][
			;return any [err-val  form reduce [" *** Error: Invalid expression Where:" expr "*** "]]
			cause-error 'syntax 'invalid [arg1: 'composite-expression arg2: expr]
		]
		; If they used a literal string, return it.
		if string? :expr [return expr]
		; If expression evaluates to a non-block value that is anything other than a 
		; word, we can't bind it. And if ctx is a function, we have to reassign the
		; rebound expr, so we do it in every case, as it's harmless for objects.
		if all [:ctx  any [block? :expr  word? :expr]][expr: bind expr :ctx]
		either error? set/any 'res try [do expr][
			any [err-val  form reduce [" *** Error:" res/id "Where:" expr "*** "]]
		][
			either unset? get/any 'res [""][:res]
		]
	]

	; One of the big questions is what to do if there are mismatched expr
	; markers. We can treat them as errors, or just pass through them, so
	; they will be visible in the output. We can support both behaviors
	; with a refinement, and then just have to choose the default.
	; Putting the colons on the outside gives you a clean paren expression
	; on the inside.
	; `Compose` could be extended, to work as-is for blocks, but add support for
	; this behavior for strings. The extra refinements are an issue, though.
	; They don't conflict with the existing `compose` refinements, but we
	; have to see how they might cause confusion given the different behaviors.
	set 'composite func [
		"Returns a copy of a string, evaluating :( ... ): sections"
		;"Replace :( ... ): sections in a string with their evaluated results"
		;"Returns a copy of a string, replacing :( ... ): sections with their evaluated results"
		data [string! file! url!]
		/marks markers [block!] "Use custom expression markers in place of :( and ):"
		/with ctx [object! function!] "Evaluate the expressions in the given context"
		/err-val e "Use instead of formed error info from eval error"
		; /into might be useful, but it also complicates things, given the current implementation.
		; Need to weigh the value. If we always create or use the out buffer, rather than changing
		; the input data in place, it won't add much complexity.
		;/into "Put results in `out`, instead of creating a new string"
		;	out [string!] "Target for results, when /into is used"
		/local expr expr-beg= expr-end= pos
	][
		if all [marks  not parse markers [2 [char! | string! | tag!]]][
			cause-error 'script 'invalid-arg [arg1: markers]
			;cause-error 'script 'invalid-data [arg1: markers]
			;return make error! "Markers must be a block containing two char/string/tag values"
		]
		set [expr-beg= expr-end=] either marks [markers][ [":(" "):"] ]
		data: either string? data [copy data][read data]    ; Don't modify the input
		parse data [
			; If we take out the cause-error actions here, mismatched expression markers
			; will pass through unscathed. That would adhere to Postel's Law
			; (https://en.wikipedia.org/wiki/Robustness_principle), but I think that's a
			; bad criteria when we're evaluating expressions. R2's build-markup treats
			; an unterminated expression as a full expression to the end of input, and 
			; an uninitiated expression as data thru the expr-end marker.
			any [
				end break
				| change [expr-beg= copy expr to expr-end= expr-end=] (eval expr e :ctx)
				| expr-beg= pos: to end (cause-error 'syntax 'missing [arg1: expr-end= arg2: pos])
				| to expr-beg= ; find the next expression
				| pos: to expr-end= (cause-error 'syntax 'missing [arg1: expr-beg= arg2: pos])
			]
		]
		data
	]

]

;composite/marks {Some [probe "interesting"] Red expressions like 3 + 2 = [3 + 2]} ["[" "]"]
;composite/marks {Some (probe "curious") Red expressions like 3 + 2 = (3 + 2)} ["(" ")"]
;composite {Some :(probe "curious"): Red expressions like 3 + 2 = :(3 + 2):}
;o: object [a: 1 b: 2]
;composite/with {Some :(probe "curious"): Red expressions like a + b = :(a + b):} o
;composite {Some Red expressions like :(":(3 + 2):"): = :(3 + 2):}
;composite {Some Red expressions like :(":():"): = :(3 + 2):}

	
;composite-ctx: context [
;
;	eval: func [
;		"Evaluate expr and return the result"
;		expr [string!] "Valid Red, as a string expression"
;		err-val "If not none, return this instead of formed error information, if eval fails"
;		/local res
;	][
;		either error? set/any 'res try [do expr][
;			any [err-val  form reduce [" *** Error:" res/id "Where:" expr "*** "]]
;		][
;			either unset? get/any 'res [""][:res]
;		]
;	]
;
;	; Putting the colons on the outside gives you a clean paren expression
;	; on the inside.
;	expr-beg=: ":("
;	expr-end=: "):"
;	
;	; One of the big questions is what to do if there are mismatched expr
;	; markers. We can treat them as errors, or just pass through them, so
;	; they will be visible in the output. We can support both behaviors
;	; with a refinement, and then just have to choose the default.
;	set 'composite func [
;		"Replace :( ... ): sections in a string with their evaluated results."
;		data [string! file! url!]
;		/err-val e "Use instead of formed error info from eval error"
;		/local expr
;	][
;		data: either string? data [copy data] [read data]	; Don't modify the input
;		parse data [
;			any [
;				end break
;				| change [expr-beg= copy expr to expr-end= expr-end=] (eval expr e)
;				| expr-beg= to end
;				| to expr-beg=
;			]
;		]
;		data
;	]
;
;]
