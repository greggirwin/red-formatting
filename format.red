Red [
	File:    %format.red
	Purpose: "Red formatting functions"
	Date:    "13-Apr-2017"
	Version: 0.0.1
	Author:  "Gregg Irwin"
	Notes: {
			
		When there are more arguments than positions in format, the format string is
		applied again to the remaining arguments. When there are fewer arguments than
		positions in the format string, printf fills the remaining positions with null-
		strings (character fields) or zeros (numeric fields).
			
		 Currency Display number with thousand separator, if appropriate;
		   display two digits to the right of the decimal separator.
		   Output is based on system locale settings.
		 Fixed Display at least one digit to the left and two digits to
		   the right of the decimal separator.
		 Standard Display number with thousand separator, at least one
		   digit to the left and two digits to the right of the decimal
		   separator.
		 Scientific Use standard scientific notation.
		
	}
	TBD: {
		- Decide on real func names. Very verbose and intentionally bad sometimes, right now.
		- short-format/printf (parser for actual spec largely done)
		- SCI E notation for scientific formatting in masks
		- ENG Engineering notation
		- 1.#INF and 1.#NaN support
		- Format style system
		- Decide if plain spaces are allowed as group separators
		- Decide if we need to allow ";" in multi-part format strings, e.g. in quotes or escaped
		
		- Far future: optimize. Terribly slow right now, what with all the special
		  case checks, and no concern for speed. R/S will be the way to go, but 
		  this version is all about the design of the interface, not speed. My old
		  R2 version is 3x faster, but has no concept of international strings,
		  control over group sep width, and such. Speed isn't an issue for a small
		  number of calls, but one of the possible uses is for spreadsheets.
		  Interactive speed and hundreds of cells are in play, there, so speed counts.
	}
]


formatting: context [
	e.g.: :comment
	
	; Generic support funcs (belong in more general mezzanine libs)
	
	abs: :absolute

	; This is a temp version of a split-at func, hence the different name.
	break-at: function [
		"Split the series at a position or value, returning the two halves, excluding delim."
		series [series!]
		delim  "Delimiting value, or index if an integer"
		/last  "Split at the last occurrence of value, from the tail"
		/local s
	][
		reduce either all [integer? delim  not last] [
			parse series [collect [keep delim skip  keep to end]]
		][
			if string? series [delim: form delim]
			if not find/only series delim [
				return reduce [copy series copy ""]
			]
			either last [
				reduce [
					copy/part series find/only/last series :delim
					copy find/only/last/tail series :delim
				]
			][
				; `copy s` is here because `keep to` doesn't collect anything if the
				; delim is the first thing in the string.
				parse series [collect [keep copy s to delim  delim  keep to end]]
			]
		]
	]
	;>> break-at "" "."
	;== ["" ""]
	;>> break-at "132" "."
	;== ["132" ""]
	;>> break-at "132." "."
	;== ["132" #"^@"]

	change-all: func [
		"Change each value in the series by applying a function to it"
		series  [series!]
		fn      [any-function!] "Function that takes one arg"
	][
		forall series [change series fn first series]
		series
	]

	; I've never liked the name of this func, but I'm including it here
	; because the behavior is handy for how I'm merging masks currently.
	first+: func [
		"Return first value in series, and increment the series index."
		'word [word! paren!] "Word must be a series."
	][
		if paren? :word [set/any 'word do :word]
		also  pick get word 1  set word next get word
	]

	form-if-char: func [val][either char? val [form val][:val]]

	; I have this here because some old format code I'm porting uses it.
	; It may all change to `rejoin`, but it gave me a reason to port `join`
	; to Red for real and think about object/map support. `Rejoin` doesn't
	; work for those. The question, then, is what value there is in a
	; uniform interface for copy+extend.
	join: func [
		"Concatenate values"
		a "Coerced to string if not a series, map, or object"
		b "Single value or block of values; reduced if a is not an object or map"
	][
		if all [block? :b  not object? :a  not map? :a] [b: reduce b]
		case [
			series? :a [append copy a :b]
			map?    :a [extend copy a :b]
			object? :a [make a :b]
			'else      [append form :a :b]
		]
	]
	e.g. [
		join 1 2
		join "a" 'b
		join %a #b
		join [a] 'b
		join 'a/b 'c
		join #(a: 1) [b: 2]
		join #(a: 1) #(b: 2)
		join context [a: 1] [b: 2]
	]
		
	;---------------------------------------------------------------------------

	set 'as-ordinal func [
		"Return the ordinal string for a number (1st, 2nd, 3rd, etc.)"
		val [integer!]
	][
		if negative? val [make error! "Ordinal doesn't support negative numbers"]
		append form val either all [val >= 10 val <= 20] ['th] [
			switch/default remainder val 10 [1 ['st] 2 ['nd] 3 ['rd]] ['th]
		]
	]

	set 'form-num-with-group-seps function [
		"Insert group separators into a numeric string"
		num [number! any-string!]
		/with sep [string! char!]
		/every ct [integer!]
	][
		num: form num							; Form strings, too, so they're not modified
		sep: any [sep #","]
		ct: negate abs any [ct 3]
		num: skip any [find num deci-char num  tail num] ct
		while [not head? num] [
			; We want to catch cases where the preceding char is not a digit, 
			; and *not* insert a sep if that's the case.
			if find digit pick num -1 [
				insert num sep
			]
			num: skip num ct
		]
		num
	]
	e.g. [
		form-num-with-group-seps 9
		form-num-with-group-seps 99
		form-num-with-group-seps 999
		form-num-with-group-seps 9999
		form-num-with-group-seps 99999
		form-num-with-group-seps 999999
		form-num-with-group-seps 9999999
		form-num-with-group-seps -9999999
		form-num-with-group-seps 9999999.9
		form-num-with-group-seps -9999999.9
		form-num-with-group-seps/with "-9999999,9" #"."
		form-num-with-group-seps/every 9          2
		form-num-with-group-seps/every 99         2
		form-num-with-group-seps/every 999        2
		form-num-with-group-seps/every 9999       2
		form-num-with-group-seps/every 99999      2
		form-num-with-group-seps/every 999999     2
		form-num-with-group-seps/every 9999999    2
		form-num-with-group-seps/every -9999999   2
		form-num-with-group-seps/every 9999999.9  2
		form-num-with-group-seps/every -9999999.9 2
		form-num-with-group-seps/with/every "-9999999,9" #"." 2
	]	

	pad-aligned: func [
		"Wrapper for `pad` to ease refinement propagation"
		str [string!] align [word!] wd [integer!] ch [char!]
	][
		switch align [
			left  [pad/with str wd ch]
			right [pad/with/left str wd ch]
		]
	]
	e.g. [
		pad-aligned "" 'left 10 #" "
		pad-aligned "" 'left 10 #"0"
		pad-aligned "x" 'left 10 #"."
		pad-aligned "x" 'right 10 #"."
		pad-aligned "x" 'right -10 #"."
		pad-aligned "xxxxxxxxx" 'right 10 #"."
		pad-aligned "xxxxxxxxxx" 'right 10 #"."
		pad-aligned "xxxxxxxxxxx" 'right 10 #"."
	]	
	
	;---------------------------------------------------------------------------

	; Credit to Gabriele Santilli for the idea this is based on.
	set 'format-bytes function [
		"Return a string containing the size and units, auto-scaled"
		size [number!]
		/to scale "How closely to round; default is 1" ; or should this be a target unit?
		/as unit [word!] {One of [bytes KB MB GB TB PB EB ZB YB]}
		/sep  ch [char! string!] "Separator to use between number and unit"
	][
		scale: any [scale 1]
		; 1 byte will come back as "1 bytes", unless we add it as a special case.
		units: [bytes KB MB GB TB PB EB ZB YB]
		either unit [
			if not find units unit [
				return make error! rejoin [mold unit " is not a valid unit for format-bytes"]
			]
			; Convert unit to a scaled power of 2 by finding the offset in
			; the list of units. e.g. KB = 2 ** 10, MB = 2 ** 20, etc.
			size: size / (2.0 ** (10 * subtract index? find units unit 1))
			rejoin [round/to size scale  any [ch ""]  unit]
		][
			while [size > 1024][
				size: size / 1024.0
				units: next units
			]
			if tail? units [return make error! "Number too large for format-bytes"]
			rejoin [round/to size scale  any [ch ""]  units/1]
		]
	]
	e.g. [
		format-bytes 1
		format-bytes 1500
		format-bytes/to 1500 .1
		format-bytes 2048
		format-bytes 9999
		format-bytes 99999
		format-bytes 999999
		format-bytes 9999999
		format-bytes 99999999
		format-bytes 999999999
		format-bytes 9999999999
		format-bytes 99999999999
		format-bytes 999999999999
		format-bytes 9999999999999
		format-bytes 99999999999999
		format-bytes 999999999999999
		format-bytes 9999999999999999
		format-bytes 99999999999999999
		format-bytes 999999999999999999
		format-bytes 9999999999999999999
		format-bytes 99999999999999999999
		format-bytes 999999999999999999999
		format-bytes 9999999999999999999999
		format-bytes 99999999999999999999999
		format-bytes 999999999999999999999999
		format-bytes 9999999999999999999999999
		format-bytes 99999999999999999999999999
		format-bytes 999999999999999999999999999
		format-bytes/to 999999999999999999999999999 .01
		format-bytes 99999999999999999999999999999
		
		format-bytes 999999999
		format-bytes/as 999999999 'GB
		format-bytes/as/to 999999999 'GB 1.0
		format-bytes/to 999999999 .01
		format-bytes/as/to 999999999 'GB .01
		format-bytes/to/as 1500 .1 'bytes
		format-bytes/to/as/sep 1500 .1 'bytes space
		format-bytes/to/as/sep 1500 .1 'bytes #"_"
	]
		
	; Should this also support integers, so format-number doesn't have to call this 
	; func? Really, it could support any value that can be converted to logic, but
	; is that more helpful to the user, or will it make things more confusing for
	; values like "" that convert to TRUE?
	set 'format-logic func [
		"Format a logic value as a string"
		value [logic!] "If a custom format is used, fmt/1 is for true, fmt/2 for false"
		fmt   [word! string! block!] "Custom format, or one of [true-false on-off yes-no TF YN]"
	][
		if word? fmt [
			; Named formats
			fmt: select [
				true-false ["True" "False"]
				on-off     ["On" "Off"]
				yes-no     ["Yes" "No"]
				TF         "TF"
				YN         "YN"
			] fmt
			if none? fmt [return make error! "Unknown named format passed to format-logic"]
		]
		form pick fmt value						; Form is used here to support custom values
	]
	e.g. [
		format-logic true  'true-false
		format-logic false 'true-false
		format-logic true  'on-off
		format-logic false 'on-off
		format-logic true  'yes-no
		format-logic false 'yes-no
		format-logic true  'TF
		format-logic false 'TF
		format-logic true  'YN
		format-logic false 'YN
		format-logic true  "+-"
		format-logic false "+-"
		format-logic true  [.t .f]
		format-logic false [.t .f]
		format-logic true  ""
		format-logic false ""
		format-logic true  []
		format-logic false []
		format-logic true  'xyz
	]
		
	;---------------------------------------------------------------------------
	; Parse rules
	
	nbsp: " "   ; char 160 - non-breaking space  alt syntax = #"^(A0)"
	thinsp: " " ; 8201 \u+2009 thin space
	narrow-nbsp: #" " ; 8239
	dot-above: #"˙"   ; 729
	digit: charset "0123456789"
	mask-digit: charset "0123456789#?"
	mask-group: charset "' ·_" ; group seps EXCLUDING ', and '.  Add nbsp thinsp
	mask-other: charset "+-()$%£¥€¢¤"
	not-point: charset [not #"."]
	not-comma: charset [not #","]
	not-dbl-quote: charset [not "^""]
	dbl-quote-str: [#"^"" any not-dbl-quote #"^""]
	; ×xeE   ×=char 215

	;---------------------------------------------------------------------------
	; Numeric formatting support funcs
	
	; Need to think about this, and refactor them into a generic func.
	; Another way to approach this will be to count the number of commas and
	; points, and mark the last position of each. That can drive a heuristic
	; to determine which is the group sep and which is the deci sep.
	deci-point?: function [
		"Returns true if . is the decimal separator"
		str [any-string!]
	][
		if not empty? str [
			to logic! any [
				parse str [
					some [mask-digit | mask-other | mask-group | dbl-quote-str | #","]
					#"." any [mask-digit | mask-group] any [dbl-quote-str | mask-other]
				]
				parse str [#"." some [mask-digit | mask-group] any [dbl-quote-str | mask-other]]
				;?? If there is no decimal mark at all, what should we do?
				(parse str [some [mask-digit | mask-other | dbl-quote-str]]  return false)
			]
		]
	]
	deci-comma?: function [
		"Returns true if , is the decimal separator"
		str [any-string!]
	][
		if not empty? str [
			to logic! any [
				parse str [
					some [mask-digit | mask-other | mask-group | dbl-quote-str | #"."]
					#"," any [mask-digit | mask-group] any [dbl-quote-str | mask-other]
				]
				parse str [#"," some [mask-digit | mask-group] any [dbl-quote-str | mask-other]]
				;?? If there is no decimal mark at all, what should we do?
				(parse str [some [mask-digit | mask-other | dbl-quote-str]]  return false)
			]
		]
	]
	deci-char: function [
		"Returns decimal separator for a mask string"
		mask [any-string!]
	][
		case [
			deci-point? mask [#"."]
			deci-comma? mask [#","]
			not find mask charset ",." [""]
			'else [""] ;[make error! form reduce ["Ambiguous or malformed format-number mask:" mask]]
		]
	]

	deci-char-tests: reduce [
		'deci-point? ""  		none
		'deci-point? "."  		false
		'deci-point? ".0" 		true
		'deci-point? "0." 		true
		'deci-point? "000" 		false
		'deci-point? "#,00.00" 	true
		'deci-point? "?,#,00.0" true
		'deci-point? "#,00,00" 	false
		'deci-point? "#.00,00" 	false
		'deci-point? "-$ #.00,00" 	false
		'deci-point? "-$ #,00.00" 	true
		'deci-point? {"kr"-#,00.00} 	true
		'deci-point? {-#.00,00"F"} 	false
		'deci-point? {-#,00.00" F"} true
		'deci-point? "($#,00.00)" 	true
		'deci-point? "($#.00,00)" 	false
		'deci-point? "-#'###'##0.0##'###'#" true
		'deci-point? "-#'###'##0,0##'###'#" false
		
		'deci-comma? ""  		none
		'deci-comma? ","  		false
		'deci-comma? ",0" 		true
		'deci-comma? "0," 		true
		'deci-comma? "000" 		false
		'deci-comma? "#.00,00" 	true
		'deci-comma? "?.#.00,0" true
		'deci-comma? "#.00.00" 	false
		'deci-comma? "#,00.00" 	false
		'deci-comma? "-$ #,00.00" 	false
		'deci-comma? "-$ #.00,00" 	true
		'deci-comma? {"kr"-#,00.00} false
		'deci-comma? {-#.00,00" F"} true		; MUST put spaces inside quotes
		'deci-comma? "($#,00.00)" 	false
		'deci-comma? "($#.00,00)" 	true
		'deci-comma? "-#'###'##0,0##'###'#" true
		'deci-comma? "-#'###'##0.0##'###'#" false
	]
	foreach [name str res] deci-char-tests [
		fn: get name
		if res <> act: fn str [print [name "FAILED!" mold str 'expected res 'got act]]
	]
	
	;!! Won't work for E notation numbers yet (>= 1.0e16, < 1e-5),
	;!! because we rely on FORM. We can trick things on the small
	;!! side, by adding 1 to them, forming, then treating the whole
	;!! part as zero. Ick. Hack.
	; This approach is not intended to be clever, efficient, elegant,
	; or Reddish. It's to help think through the combinations we need
	; to support.
	merge-number-mask: function [
		mask [string!]
		num  [string!] "Formed number"
		sign [integer!] "1, 0, -1"
		/whole "Merge from right to left"
		/frac  "Merge from left to right"
	][
		; We're going to process the whole part of our number from
		; least to most significant digit. Reversing them lets the
		; merge logic walk forward through them.
		if whole [
			reverse mask 
			reverse num
		]
		result: make string! length? mask
		while [any [not tail? mask  not tail? num]][
			new-ch: switch/default ch: first+ mask [
				#"^^" [first+ mask]									; escape, take the next char
				#"0" [any [first+ num  #"0"]]
				#"9" [any [first+ num  #" "]]
				#"?" [any [first+ num  #" "]]
				#"#" [any [first+ num  ""]]
				#[none] [first+ num]								; We ran out of mask chars
				#"(" [s?: yes  either negative? sign [#"("][""]]	; If we hit any sign char, set a flag
				#")" [s?: yes  either negative? sign [#")"][" "]]
				#"+" [s?: yes  either negative? sign [#"-"][#"+"]]
				#"-" [s?: yes  either negative? sign [#"-"][#" "]]
				#"^"" [
					while [dbl-quote <> str-ch: first+ mask][append result str-ch]
					"" ; Return empty string so we don't append anything else
				]
			][ch]
			;print [tab mold mask mold num mold ch mold new-ch]
			; If our mask is too short, we may have added a sign/special char already,
			; which means that any extra digits from the number will be appended
			; after it. When reversed, that puts the sign between some digits.
			; What we'll do is look at the last char we added. If it's a sign,
			; and if we have a digit to add, we'll step back one when adding it.
			;!! There is a case this will not catch. If "-" is used in the mask,
			;	but the number is positive, we'll end up with a space at the end
			;	and we have to decide if we should check for spaces, or if they're
			;	valid group separators.
			either all [not empty? result  find mask-other last result  find digit new-ch][
				insert back tail result new-ch
			][
				append result new-ch
			]
		]
		if all [not frac  not s?  negative? sign][append result #"-"]

		either whole [
			reverse mask 
			reverse num
			reverse result
		][result]
	]
	e.g. [
		; Remember when testing this to reverse the strings being merged.
		merge-number-mask "000" "123" 1
		merge-number-mask/whole "0000" "123" 1
		merge-number-mask "000?" "123" 1
		merge-number-mask "000" "" 0
		merge-number-mask "000#" "123" 1
		merge-number-mask "+000" "123" -1
		merge-number-mask "-000" "123" -1
		merge-number-mask "-000" "123" 1
		merge-number-mask "(000)" "123" -1
		merge-number-mask "(000)" "123" 1

		merge-number-mask/frac "(0.00)" "123" -1
		merge-number-mask/frac "-00" "123" -1
		merge-number-mask/frac "00" "123" -1

		merge-number-mask/whole "0,000" "123" 1
		merge-number-mask/whole "#,000" "123" 1
		merge-number-mask/whole "#,000" "12345" 1
		merge-number-mask/whole "## #0 00" "123" 1
		merge-number-mask/whole "## #0 00" "1234" 1
		merge-number-mask/whole "## #0 00" "12345" 1
		merge-number-mask/whole "## ## ## #0 00" "123456789" 1
		merge-number-mask/whole "00 00" "12345" 1
		merge-number-mask/whole "00 ^#00" "12345" 1
		merge-number-mask/whole {00 00 " text"} "12345" 1
		merge-number-mask/whole {####00" text"} "12345" 1
		merge-number-mask/whole {00 00 00" text"} "12345" 1
		merge-number-mask/whole {"text " 00 00} "12345" 1
			
		merge-number-mask/whole "#.##0,000" "12345" 1
	]
	
	;!! If we're going to remove extra group seps, we have to decide
	;	what to do about spaces. They should probably not be used as
	;	group seps, because we can't tell them from placeholder spaces.
	;	thinsp might be OK. nbsp, not sure.
	remove-leading-group-separators: function [str [string!] dec-ch [char! string!]][
		; If we include the space char here, it conflicts with using 9/?,
		; instead of #, because those spaces are intentional. Otherwise
		; we could just use 'mask-group here.
		sep: charset "'·_" ; group seps EXCLUDING ', and '.  Add nbsp thinsp

		; Add the standard group sep that is NOT the deci char they gave us.
		if all [string? dec-ch  empty? dec-ch] [dec-ch: #"."]
		append sep either #"." = dec-ch [#","][#"."]
		
		parse str [
			any [
				[[digit | dec-ch] to end]
				| remove sep
				| skip
			]
		]
		str
	]

	remove-trailing-group-separators: function [str [string!] dec-ch [char! string!]][
		reverse str
		remove-leading-group-separators str dec-ch
		reverse str
	]
	
	; These are here because things get tricky once we decide to break
	; up the mask and merge the whole and fractional parts separately.
	; The issue being whether the whole part merge should automatically
	; add a - for negative numbers where no sign sigil is given in the
	; mask. For international use, the sign may also go on the right.
	; See: https://msdn.microsoft.com/en-us/globalization/mt662322.aspx
	; If the sign is on the fraction in the mask, the whole part doesn't
	; know about that, and will erroneously add one. In that case, we 
	; need to use the absolute value of the number when formatting the
	; whole part. But if a sign sigil is in both mask parts, explicitly,
	; we should include it in both. That's also true for parens in 
	; accounting format, which need to be applied to both sides.
	sign-ch: charset "+-"
	acct-sign-ch: charset "()"
	whole-sign?: func [mask [block!] n [number!]][
		; If all these things are true, use the absolute value for the whole part.
		sign? either all [
			find mask/frac sign-ch
			not find mask/frac acct-sign-ch
			not find mask/whole sign-ch
			not find mask/whole acct-sign-ch
		][abs n][n]
	]
	; Don't need this yet
	;frac-sign?: func [mask [block!] n [number!]][]

	set 'format-number-with-mask function [
		"Return a formatted number, using a mask as a template"
		n [number!]
		mask [string!]
	][
		result: make string! length? mask

		; Convert number to string, removing standard type decorations,
		; then split it at the decimal mark.
		;!! We no NOT round when formatting. That's up to the caller.
		;!! We always break at #"." against a FORMed number, as Red
		;   will always use that as the default decimal separtaor.
		;!! Merge-number-mask can't handle E notation numbers, so we'll
		;   hack our way around that while experimenting, and trick FORM
		;   into giving us a non-scientific format. Currently, .1 is the
		;	lower limit where Red formats with E notation.
		either all [n > -0.1  n < .1  n <> 0  not percent? n][
			; Add 1 to the absolute value of the number, to trick FORM.
			num: form 1 + abs n
			; Now our first digit is 1, but we added that, so change it to 0.
			change num #"0"
		][
			num: form abs n 
			; Just in case Red changes the rules on us.
			if find num #"e" [return make error! rejoin ["format-number-with-mask doesn't like " n]]
		]
		num: break-at trim/with num "$%" "." 
		num: reduce ['whole num/1 'frac num/2]

		; Split the mask at the decimal mark. The mask is what defines
		; the decimal character, which we remember, so we can use it
		; when rebuilding the complete number.
		mask: break-at mask d-ch: deci-char mask
		mask: reduce ['whole mask/1 'frac mask/2]
		
		; If breaking the string produced single chars, instead of strings,
		; we need to form them for the merge processing to work.
		change-all num  :form-if-char
		change-all mask :form-if-char
		
		; It's a bit redundant to use /whole and /frac multiple times, but
		; if we pass the blocks with each part, then merge-number-mask has
		; a more demanding interface for independent use. This way it uses
		; plain strings.
		whole: merge-number-mask/whole mask/whole num/whole whole-sign? mask n
		frac: either empty? mask/frac [""][
			merge-number-mask/frac mask/frac num/frac sign? n
		]

		;prin mold reduce [whole d-ch frac]
		repend/only result [whole d-ch frac]	; d-ch = decimal char

		; Now we may have a group separator before any digits, which
		; we don't want. Other chars, like currency symbols and signs
		; are fine, but not group separators.
		remove-leading-group-separators result d-ch
		remove-trailing-group-separators result d-ch
		
		;set 'dbg reduce [num mask whole frac]
		result
	]

	tests: context [
		test: func [
			value
			fmt
		][
			print [mold value tab mold fmt tab mold format-number-with-mask value fmt]
		]
		specs: [
			[-12345.67    " ######"        ]
			[-12345.67    "-??????"        ]
			[-12345.67    " 999999"        ]		; Extra space before sign
			[-12345.67    "-000000"        ]
			[-12345.67    "-$000 000.000" ]
			[-12345.67    "-$999 999.999" ]
			[-12345.67    "-$9_99_999.999" ]
			[-12345.67    "$(999 999.999)" ]
			[-12345.67    "$(### ###.999)" ]
			[123456.78    "£+ 999,990.000"]
			[123456.78    "£ 999,990.000"]
			[-123456.78    "£ 999,990.000"]

			[-12345.67    "-###,##0.000" ]
			[-1234.67     "-###,##0.00?" ]
			[-123.45      "-###,##0.000" ]
			[-12345.67    "-#,##0.000" ]

			[-12345.67    "-##.##0,000" ]
			[-12345.67    "-#.##0,000" ]
			
			[12345.67    "-#,##0.000" ]			; FAIL! too-short masks are a problem
			[12345.67    "#,##0.000" ]			; FAIL! too-short masks are a problem
			[12345.67    "+#,##0.000" ]			; FAIL! too-short masks are a problem

			[-12345.6789    "-#,###,##0.0##,###,#" ]  ; These cause issues. Can we support group
			[-12345.6789    "-#.###.##0,0##.###.#" ]  ; seps in the fractional part with masks,
			[-12345.6789    "-# ### ##0.0## ### #" ]  ; without things getting really ugly? The
			[-12345.6789    "-#'###'##0.0##'###'#" ]  ; heuristics may not always win. Space and
													  ; tick seps are OK.

			[-12345.67    "-£##.##0,000"]
			[-12345.67    {-##.##0,000" F"}]
			[-12345.67    {"kr"-##.##0,000}]
			[-12345.67    "€ ##.##0,000-"]
			[-12345.67    "($##.##0,000)"]

			[-12345.67    "-£##.###.##0,000"]
			[-12345.67    {-##.###.##0,000" F"}]
			[-12345.67    {"kr"-##.###.##0,000}]
			[-12345.67    "€ ##.###.##0,000-"]
			[-12345.67    "($##.###.##0,000)"]

			[0.0001 "0"]
			[0.0001 ".00000"]
			[0.0001 "0.#"]
			[0.0001 ".#"]
			[0.0001 "0.#"]

			[0.00000001 ".00000"]
			[0.00000000000001 ".00000"]		; lower limit
			
	;		[-12345.67    "-£#.##0,000"]
	;		[-12345.67    "-#.##0,000 F"]
	;		[-12345.67    "kr-#.##0,000"]
	;		[-12345.67    "€ #.##0,000-"]
	;		[-12345.67    "($#.##0,000)"]

			[.00001%    "#.000%" ]
			[-.00001%    "#.000%" ]
			[.4567%    "#.000%" ]
			[-.4567%    "#.000%" ]
			[1.4567%    "##,##0.000%" ]
			[12.4567%    "##,##0.0#" ]
			[123.4567%    "##,##0.000%" ]
			[12345.6789%    "##,##0.000%" ]
			[-123.4567%   "#,##0.000%" ]
			[123.4567%    "##.##0,000%" ]
			[-123.4567%   "#.##0,000%" ]

		]
		run: does [
			print ""
			foreach spec specs [test spec/1 spec/2]
		]
	]
	tests/run

	; 'via instead of 'with to make it clearer that this is different, for now.
	set 'format-number-via-masks function [
		"Return a formatted number, selecting a mask as a template based on the number's value"
		n [number!]
		masks [string! block! map!] "Masks appplied based on the sign or special value of n"
	][
		; custom format
		either any-string? fmt [
			fmts: split fmt ";"
		][
			set-fmt: func [val] [change find fmts none val]
			; any-block?
			
			; If they give us a block with four items, having "0" as our first
			; element here messes us up. Instead, we'll set it later if need be.
			;fmts: reduce ["0" none none none] ; pos neg zero none
			fmts: reduce [none none none none] ; pos neg zero none
			
			parse fmt [
				some [
					set f string! (
						either find fmts none [set-fmt f] [
							print ["Too many formats specified," mold f "will be ignored"]
						]
					)
					| ['pos  | 'positive | 'positive?] set f string! (fmts/1: f)
					| ['neg  | 'negative | 'negative?] set f string! (fmts/2: f)
					| ['zero | 'zero?] set f string! (fmts/3: f)
					| ['none | 'none?] set f string! (fmts/4: f)
				]
			]
		]
		
		if empty? fmts [insert fmts "0"]
		if none? fmts/1 [fmts/1: "0"]
		;print ["fmts:" mold fmts]
		
		;#fmts
		; 1     1 - all vals
		; 2     1 - pos and zero, 2 - neg
		; 3     1 - pos, 2 - neg, 3 - zero
		; 4     1 - pos, 2 - neg, 3 - zero, 4 - none
		; missing fmts deault back to pos fmt
		fmt: case [
			; have to try NONE? first; NONE will choke the other funcs.
			; Formats are: [pos neg zero none]
			;none? value     [any [fmts/4 fmts/1]]
			none? value     [pick fmts 4]
			positive? value [fmts/1]
			negative? value [any [fmts/2 fmts/1]]
			zero? value     [any [fmts/3 fmts/1]]
		]
		;print ["fmt:" mold fmt]

		; A NONE value is a special case. We can't really format it as a number, so
		; we return the specified format string directly. If they didn't provide one,
		; should we fall back to fmts/1 as I did originally, or should we return a
		; known error value (e.g. #ERR)?
		;if none? value [return fmt]
		if none? value [return either fmt [fmt] [#ERR]]

		format-number-with-mask value fmt
	]

	
	num-to-bin-str: func [
		num [number!] "Rounded to integer before formatting"
		return: [string!]
	][
		;enbase/base debase/base to-hex to integer! round num 16 2
		enbase/base num-to-hex-bin num 2
	]
	num-to-hex-bin: func [
		num [number!] "Rounded to integer before conversion"
		return: [binary!]
	][
		;debase/base form to-hex to integer! round num 16 
		to binary! to integer! round num
	]
	
	set 'format-number-with-style function [
		"Return a formatted number, selecting a mask as a template based on the number's value"
		n [number!]
		name [word!] "Named or direct style" ; object! map!
	][
		r-sep: #"'"
		add-seps: :form-num-with-group-seps
		switch name [
			;The 'r- prefix stands for "round-trip/Ren/Redbol"
			r-general r-standard [add-seps/with n r-sep]	; #'##0.0#
			r-fixed    [add-seps/with format-number-by-width n 1 2 r-sep]  ; #'##0.00
			;r-currency [add-seps/with to money! n r-sep]                ; $#'##0.00
			;r-money    [add-seps/with to money! n r-sep]                ; $#'##0.00
			r-money r-currency [add-seps/with format-number-with-mask round/to n .01 "$#,##0.00" r-sep]                ; $#'##0.00  -$#'##0.00
			r-percent  [add-seps/with format-number-by-width to percent! n 1 2 r-sep]
			r-hex      [to-hex to integer! n]

			general standard [add-seps n]	; #,##0.0#
			fixed    [add-seps format-number-by-width n 1 2]          ; #,##0.00
			;currency [add-seps to money! n] ; $#,##0.00
			;money    [add-seps to money! n] ; $#,##0.00
			money currency [add-seps format-number-with-mask round/to n .01 "$#,##0.00"] ; $#,##0.00
			percent  [add-seps format-number-by-width to percent! n 1 2]
			;percent  [join add-seps next form to money! value * 100 #"%"]
			;E scientific []	;Use standard scientific notation.

			base-64  [enbase/base form n 64]
			hex      [form to-hex to integer! n]
			min-hex  [							; No leading zeros
				either zero? n [""] [
					find form to-hex to integer! n complement charset "0"]	; No leading zeros
				]
			C-hex    [join "0x" to-hex to integer! n]
			;VB-hex   [join "&H" to-hex to integer! n]
			;octal    [] ; maybe useful for things like `chmod 755` viz	; no enbase for octal yet
			bin      [num-to-bin-str n]
			binary   [num-to-bin-str n]
			min-bin  [							; No leading zeros
				either zero? n [""] [
					form find num-to-bin-str n complement charset "0"
				]
			]

			accounting [format-number-via-masks n [pos " #,##0.00 " neg "(#,##0.00)" zero "-" none ""]]
			
			;rel-days   [num-to-rel-date-time n 'rel-days]
			;rel-hours  [num-to-rel-date-time n 'rel-hours]
			;rel-time   [num-to-rel-date-time n 'rel-time]
			; throw error - unknown named format specified?
			;case else [either any-block? value [reform n] [form n]]
		]
	]
	e.g. [
		format-number-with-style 0 'r-general
		format-number-with-style 0 'r-standard
		format-number-with-style 0 'r-fixed
		format-number-with-style 0 'r-currency
		format-number-with-style 0 'r-money
		format-number-with-style 0 'r-percent

		format-number-with-style 0 'general
		format-number-with-style 0 'standard
		format-number-with-style 0 'fixed
		format-number-with-style 0 'currency
		format-number-with-style 0 'money
		format-number-with-style 0 'percent

		format-number-with-style 0 'hex
		format-number-with-style 0 'min-hex
		format-number-with-style 0 'C-hex
		format-number-with-style 0 'bin
		format-number-with-style 0 'min-bin
		
		format-number-with-style 0 'accounting

		format-number-with-style 12345.678 'r-general
		format-number-with-style 12345.678 'r-standard
		format-number-with-style 12345.678 'r-fixed
		format-number-with-style 12345.678 'r-currency
		format-number-with-style 12345.678 'r-money
		format-number-with-style 12345.678 'r-percent

		format-number-with-style 12345.678 'general
		format-number-with-style 12345.678 'standard
		format-number-with-style 12345.678 'fixed
		format-number-with-style 12345.678 'currency
		format-number-with-style 12345.678 'money
		format-number-with-style 12345.678 'percent

		format-number-with-style 32767 'hex
		format-number-with-style 32767 'min-hex
		format-number-with-style 32767 'C-hex
		format-number-with-style 32767 'bin
		format-number-with-style 32767 'min-bin

		format-number-with-style 12345.678 'accounting

		format-number-with-style -12345.678 'r-general
		format-number-with-style -12345.678 'r-standard
		format-number-with-style -12345.678 'r-fixed
		format-number-with-style -12345.678 'r-currency
		format-number-with-style -12345.678 'r-money
		format-number-with-style -12345.678 'r-percent

		format-number-with-style -12345.678 'general
		format-number-with-style -12345.678 'standard
		format-number-with-style -12345.678 'fixed
		format-number-with-style -12345.678 'currency
		format-number-with-style -12345.678 'money
		format-number-with-style -12345.678 'percent

		format-number-with-style -12345.678 'hex
		format-number-with-style -12345.678 'min-hex
		format-number-with-style -12345.678 'C-hex
		format-number-with-style -12345.678 'bin
		format-number-with-style -12345.678 'min-bin

		format-number-with-style -12345.678 'accounting
		
	]

	; The printf model of total.deci lengths is unintuitive. It seems more
	; natural to use whole.deci. The question is how much "discussion" that
	; will cause. 
	set 'format-number-by-width function [
		"Formats a decimal with a minimum number of digits on the left and a maximum number of digits on the right. No separators added."
		value   [number!]  "The value to format"
		tot-len [integer!] "Minimum total width. (right justified, never truncates)"
		dec-len [integer!] "Maximum digits to the right of the decimal point. (left justified, may round)"
		; Using left/right saves a param over [/align dir] and will catch more errors
		/left   "Left align"
		/right  "Right align (default)"
		/use+   "Include + sign for positive values"	
		/with
			ch  [char!]    "Alternate fill char (default is space)"
	][
    	ch:  any [ch #" "]
    	sign: case [
			negative? value ["-"]	; Always use - for negative
			use+  ["+"]				; Force the + sign on
			left  [" "]				; Reserve space to match +/-
			'else [""]				; Positive or right align, don't force +
    	]
    	if percent? value [dec-len: dec-len + 2]	; Percents look like whole values, but are scaled.
    	; It would be nice if we could just join the sign to the rest here,
    	; which I did first. The problem is that fill chars end up to the
    	; left of it. Fine for spaces, underscore, etc., not for 0.
		either ch = #"0" [
			value: mold round/to abs value 10 ** negate dec-len
			value: pad-aligned value either left ['left]['right] (tot-len - length? sign) ch
			head insert find value digit sign
		][
			value: join sign mold round/to abs value 10 ** negate dec-len
			pad-aligned value either left ['left]['right] tot-len ch
		]
	]
	e.g. [
		format-number-by-width 0 0 0
		format-number-by-width 1 0 0
		format-number-by-width 123.456 0 0
		format-number-by-width -123.456 0 0

		format-number-by-width 10.5% 0 0
		format-number-by-width -10.5% 0 0
		format-number-by-width/with -10.5% 8 2 #"0"

		format-number-by-width/with -10.5 8 2 #"0"
		format-number-by-width/with/use+ 10.5 8 2 #"0"
		format-number-by-width/with/left 10.5 8 2 #"0"
		format-number-by-width/with 10.5 8 2 #"0"

		format-number-by-width/with -10.5 8 2 #"0"
		format-number-by-width/with -10.5 8 2 #"_"
		format-number-by-width/with -10.5% 8 2 #"0"
		format-number-by-width/with/use+ 10.5 8 2 #"_"

		format-number-by-width 0 5 0
		format-number-by-width 1 5 0
		format-number-by-width 123.456 5 0
		format-number-by-width -123.456 5 0
		format-number-by-width 123.456 5 2
		format-number-by-width -123.456 5 2

		format-number-by-width 123.456 10 0
		format-number-by-width -123.456 10 0
		format-number-by-width/left 123.456 10 2
		format-number-by-width/right -123.456 10 2
		
		format-number-by-width/left/use+ 123.456 10 2
		format-number-by-width/right/use+ 123.456 10 2
		
	]
	
] ; end of formatting context

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

halt


;-------------------------------------------------------------------------------

; The VB format$ function has a somewhat obscure behavior that allows you to
; put two group separators next to each other in the format string to indicate
; a scaling operation, kind of like format-bytes does.

;1.#INF
;-1.#INF
;1.NaN
;percents

is-named-logic-format?: func [fmt][find [YN TF yes-no on-off true-false] fmt]

format-number: function [
	value [number!]
	fmt   [word! string! block!] "Named or custom format"
][
	
	case [
		is-named-logic-format? fmt [format-logic not zero? value fmt]	; to logic! 0 == true in Red.
		block?  fmt [format-number-via-masks  value fmt]
		string? fmt [format-number-via-masks  value fmt]
		word?   fmt [format-number-with-style value fmt]
	]	
]

format-string: func [
	value [any-string!]
	fmt   [word! string! block!] "Named or custom format"
	/local fmts
		   
][
	either word? fmt [
		; Named formats. Can't use AA/aa/Aa because switch isn't case sensitive.
		; Need to use something else to do that here.
		switch fmt [
			;general [value]
			upper uppercase all-caps [uppercase value]
			lower lowercase [lowercase value]
			cap capitalize [uppercase/part lowercase value 1]
			;proper  [uppercase/part lowercase value 1]
			;camel
			; throw error - unknown named format specified?
			;case else [either any-block? value [reform value] [form value]]
		]
	][
		; custom format
		either block? fmt [
			use [
				align= wd= fill= rules 
				=align =wd =fill  mod res
			][
				align=: [opt 'align set =align ['left | 'center | 'right]] ;  opt 'align set =align
				; 'size or 'pad  keywods for width?
				wd=:    [opt ['width | 'wd] set =wd integer! (if negative? =wd [=wd: abs =wd  align: 'right])]
				fill=:  [opt ['filler | 'fill opt 'with] set =fill [char! | string!]]
				rules:  [
					(
						=align: 'left 
						=fill: #" " 
						=wd: 0
					)
					; Case change rules have to come first, before alignment rules.
					; Will that confuse people?
					opt [
						['upper | 'uppercase]   (uppercase value)
						| ['lower | 'lowercase] (lowercase value)
						| ['cap | 'capitalize]  (uppercase/part lowercase value 1)
					]
					any [align= | wd= | fill=] (
						res: do reduce [
							to path! compose [justify (=align) with] value =wd =fill
						]
					)
				]
				either parse fmt rules [res] [#ERR]
			]
		][
			; TBD - string format?
			; @&<>! ; specials
			; aa   - lower
			; AA   - upper
			; Aa   - capitalize
			; AaAa - camel
			; left center right  < ^ >
			; ... ; show ellipsis if truncated
			; width (left justify)
			; negative width (right justify)
			
			; What do we do for an as-is format? i.e. strings in a block that
			; they don't want formatted?
		]
	]
]



;-------------------------------------------------------------------------------
;
; Capitalization  (still very much experimental and incomplete)
;
;   http://en.wikipedia.org/wiki/Capitalization
;   http://individed.com/code/to-title-case/
;   http://individed.com/code/to-title-case/tests.html
;   http://daringfireball.net/2008/08/title_case_update
;   http://www.heikniemi.net/hardcoded/2004/10/propercase-for-c/
;   http://blogs.msdn.com/b/michkap/archive/2005/03/04/384927.aspx

; Title Case - the first letter of each word is capitalized, the rest are lower case. 
; In some cases short articles, prepositions, and conjunctions are not capitalized.
;
; Proper Case - Used for proper nouns, the first letter of each word is capitalized.
;
; CamelCase - First letter of each word capitalized, spaces and punctuation removed. 

; "Q&A" "R&D" "AT&T"

; http://www.sti.nasa.gov/sp7084/ch4.html
capitalization-ctx: context [
	ch-whitespace=: charset " ^/^-" 

	ch-digit=:    charset "1234567890" 
	;ch-hexdigit=: charset "1234567890abcdefABCDEF" 
	
	ch-lower=:    charset [#"a" - #"z"] 
	ch-upper=:    charset [#"A" - #"Z"] 
	ch-alpha=:    union ch-lower= ch-upper=
	ch-alphanum=: union ch-alpha= ch-digit=
	;ch-ascii=:    charset [#"^(00)" - #"^(7F)"] 
	;ch-low-ascii=:  charset [#"^(00)" - #"^(1F)"] 
	;ch-high-ascii=: charset [#"^(80)" - #"^(FF)"] 

	ch-word=: ch-alphanum= 
	;ch-word=: union ch-alphanum= charset "_" ;?
	ch-non-word=: complement ch-word=

	;auxilliaries: ["is" "am" "are" "was" "be" "has" "had" "do" "did"]
	articles:     ["the" "a" "an"]
	prepositions: ["of" "to" "in" "for" "with" "on"]
	conjunctions: ["for" "and" "nor" "but" "or" "yet" "so"]  ; "either" "not" "neither" "both" "whether"

	foreign-particles: [
		"von"   ; German - don't cap
		"van" "de" "der" "ter" ; Dutch - "Van der" only cap first, cap only if no given name
	]
	
	;medial-prefixes: ["Mc" "Mc'" "Mac" "Mac'" "O'" "M'"]
	medial-prefixes: ["Mc"] ; "Mac"?

	word=: [
		copy =word some ch-word=
		;copy =word to ch-non-word=    
	]   
	 
	def-dict: compose/deep [
		lower [(union union articles prepositions conjunctions)]
		upper [
			"NW" "SW" "NE" "SE" "SSW" "SSE" "NNW" "NNE"
			;"Q&A" "R&D" "AT&T" ; & is a break char right now, so we need to consider how best to do this.
			"UK" "USA"
		]  
		fixed ["MHz"]
	]
	
	; U.S.A. is a tricky one, because the dot is seen as a break and the 'a is
	; seen as an article, which is then converted to lowercase. So we end up 
	; parsing it as three separate, single-letter words with breaks.
	
	; uppercase/part 1
	;    
	; last-break: :this-break
	; this-break: Look for word break
	; If last-word (last-break to this-break) is
	;   acronym [no change]
	;   small word [lowercase it]
	;   starts with o' and is > 3 chars [uppercase/part 3]
	;   ? starts with mc  [uppercase/part 1  at str 3 uppercase/part 1]
	;   ? starts with mac [uppercase/part 1  at str 4 uppercase/part 1]
	;  [van von der ] [lowercase it]
	;  ? should 
	set 'capitalize func [
		string [any-string!]
		/name "Don't use dict for special processing"
		/address "Don't use dict for special processing"
		/camel "Non-word chars are removed"
		;/break-at non-word-chars [bitset!]
		/with dict [block!]  {[lower ["a" "an" "the"] upper ["AT&T"] fixed ["MacLeod"]}
		/show "Show words and their offsets as they are found"
	] [
		if empty? string [return string]

		dict: any [dict def-dict]
		
		; cap: func [
		;     string [any-string!]
		; ] [
		;     uppercase/part lowercase string 1
		; ]
		; 
		; cap-it?: func [
		;     string [any-string!]
		; ] [
		;     if any [name address] [return true]
		; ]
		; 
		; uppercase?: func [
		;     "Returns true if the string is all caps."
		;     string [any-string!]
		; ][
		;     parse string [some [ch-upper=]]
		; ]
		; 
		; lowercase?: func [
		;     "Returns true if the string is all lowercase chars."
		;     string [any-string!]
		; ][
		;     parse string [some [ch-lower=]]
		; ]
		
		
		w-start: none
		w-end:   none
		
		lower-wd: does [
			change/part w-start lowercase/part w-start w-end w-end 
		]
		upper-wd: does [
			change/part w-start uppercase/part w-start w-end w-end 
		]
		cap-wd: does [
			change/part w-start uppercase/part w-start 1 w-end 
		]
		chg-wd: func [new-wd [string!]] [
			change/part w-start new-wd w-end 
		]
		
		parse/all string [
			some [
				w-start: word= w-end: (
					if show [print [=word index? w-start index? w-end]]
					case [
						
						find dict/fixed =word [
							chg-wd pick dict/fixed index? find dict/fixed =word
						]
						
						any [
							find foreign-particles =word
							find dict/lower =word
						]  [lower-wd]

						; Need to determine what to do about & breaking words, which these may be.                        
						find dict/upper =word [upper-wd]

						; Medial prefixes - make this dynamic for different prefixes
						"Mc" = copy/part =word 2 [
							lower-wd
							cap-wd
							change/part next next w-start w-end  uppercase/part next next w-start 1
						]
						
						; End of a contraction of possesive
						all [
							find ["T" "S"] =word
							#"'" = attempt [first back w-start]
						] [lower-wd]
						
						
						; Standard word to capitalize
						'else [lower-wd cap-wd]
					]
				) :w-end
				| skip
			]
		]

		; This does NOT strip leading digits from the word.        
		if camel [
			parse/all string [
				some [
					mark: ch-non-word= (mark: remove mark) :mark
					| skip
				]
			]
		]
		
		; Always capitalize the first letter.
		; Should fixed words override this?
		uppercase/part string 1
		
	]
	
]

comment {
	capitalize-tests: [
"ALONZO-MEDRANO"
"URDANETA-ROSARIO"

"MIGUEL" "BENAVIDESAQUILLILA" "5559 Gatlin Av # G" "Orlando"
"JOSE" "FELICIANODELGADO" "114 Sandy Point Way" "Clermont"
"YOANDRIS" "ALVAREZ GUTIERREZ" "70 E 55TH ST" 
"11120 SW 196TH ST  402 B"
"mccray"
"mckinzie"
"Mcleod"
"Macleod"
"o'Brien"
"O'reilly"

"von helsing"
"van der meer"

"500mhz"
"500 mhz"

"u.s.a"
	]
	
	foreach str capitalize-tests [
		print [mold str tab mold capitalize copy str]
	]
}

;-------------------------------------------------------------------------------


set 'format-value func [
	value [number! money! none! date! time! logic! any-string!]
	fmt   [word! string! block!] "Named or custom format"
	/local type
] [
	type: type?/word value
	;print ['xxx type mold value mold :fmt]
	case [
		; not sure what to do with NONE values.
		find [integer! decimal! money! none!] type [format-number value fmt]
		find [date! time!] type [format-date-time value fmt]
		type = 'logic!          [format-logic  value fmt]
		any-string? value       [format-string value fmt]
	]
]

set 'format function [
	value [any-type!]
	fmt   [word! string! block! function! object! map!] "Named or custom format"
][
	;type: type?/word value
	;print ['xxx type mold value mold :fmt]
	case [
		none? :value []	; dispatch based on fmt
		find [integer! decimal! money!] type [format-number value fmt]
		;find [date! time!] type [format-date-time value fmt]
		logic? :value      [format-logic  value fmt]
		any-string? :value [format-string value fmt]
		block? :value      []
	]
]

; Rather than having these REFORM the result, if they just return the block of
; formatted values, the caller can choose to rejoin, reform, delimit, etc.
; We also need to make sure we add value over what PRINT does by default.

set 'reformat func [input [block!]] [
	reform collect item [
		foreach val input [
			item: either block? :val [format val/1 val/2] [form val]
		]
	]
]

set 'reformat-b func [data [block!] template [block!] /local res] [
	reform collect item [
		foreach val template [
			item: either all [block? :val not empty? val] [
				res: format data/1 val/1
				data: next data
				res
			] [form val]
		]
	]
]
