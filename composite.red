Red [
	Author: "Gregg Irwin"
	Purpose: "COMPOSE for strings"
	Notes: {
		TBD: Security model for eval'ing expressions
	}
]

; The name of the function (`composite`) is tricky. Rebol calls this
; `build-markup`, which isn't bad, but defines a more limited view of its 
; use. We want a word that says it operates on a single argument, so things
; like `intersperse` or `interject` don't read as well to me. It sounds like
; the take something(s) to insert. `Inset` is too close to `insert`. Another
; option is a neologism, like `interform`, which implies both putting a thing
; in a place, and `form`ing it. `Composite` is generally used as a term
; related to image processing, which is a possible point of confusion.

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
		"Replace (: ... :) sections with their evaluated results."
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

print mold composite ""
print mold composite ":(1):"
print mold composite ":(pi):"
print mold composite ":(rejoin ['a 'b]):"
print mold composite "a:('--):b"
print mold composite "a:('--):"
print mold composite ":('--):b"
print mold composite "ax:(1 / 0):xb"
print mold composite/hide-errors "ax:(1 / 0):xb"
print mold composite ":("
print mold composite ":('end"
print mold composite "):"
print mold composite ")::("


halt
