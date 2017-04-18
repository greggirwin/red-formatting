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

	pad-aligned: func [
		"Wrapper for `pad` to ease refinement propagation"
		str [string!] align [word!] wd [integer!] ch [char!]
	][
		switch align [
			left  [pad/with str wd ch]
			right [pad/with/left str wd ch]
		]
	]
	
	;---------------------------------------------------------------------------

	set 'format-bytes function [
		"Return a string containing the size and units, auto-scaled"
		size [number!]
		/to scale "Rounding precision; default is 1"
		/as unit [word!] "One of [bytes KB MB GB TB PB EB ZB YB]"
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
			; Credit to Gabriele Santilli for the idea this is based on.
			while [size > 1024][
				size: size / 1024.0
				units: next units
			]
			if tail? units [return make error! "Number too large for format-bytes"]
			rejoin [round/to size scale  any [ch ""]  units/1]
		]
	]
		
	; Should this also support integers, so format-number doesn't have to call this 
	; func? Really, it could support any value that can be converted to logic, but
	; is that more helpful to the user, or will it make things more confusing for
	; values like "" that convert to TRUE?
	set 'format-logic function [
		"Format a logic value as a string"
		value [logic!] "If a custom format is used, fmt/1 is for true, fmt/2 for false"
		fmt   [word! string! block!] "Custom format, or one of [true-false on-off yes-no TF YN]"
	][
		fmts: [
			true-false ["True" "False"]
			on-off     ["On" "Off"]
			yes-no     ["Yes" "No"]
			TF         "TF"
			YN         "YN"
		]
		if word? fmt [							; Named formats
			if not find/skip fmts fmt 2 [
				return make error! rejoin ["Unknown named format passed to format-logic: " fmt]
			]
			fmt: fmts/:fmt
		]
		if 2 <> length? fmt [
			return make error! rejoin ["Format must contain 2 values: " fmt]
		]
		form pick fmt value						; Form is used here to support custom values
	]

	set 'mold-logic function [
		"Return a logic value as a word"
		value [logic!]
		/true-false "(default)"
		/on-off
		/yes-no
	][
		pick case [
			on-off [[on off]]
			yes-no [[yes no]]
			'else  [[true false]]
		] value
	]
		
	;---------------------------------------------------------------------------
	; Mask formatting parse rules
	
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
			r-general
			r-standard [add-seps/with n r-sep]	; #'##0.0#
			r-fixed    [add-seps/with format-number-by-width n 1 2 r-sep]  ; #'##0.00
			;r-currency [add-seps/with to money! n r-sep]                ; $#'##0.00
			;r-money    [add-seps/with to money! n r-sep]                ; $#'##0.00
			r-money
			r-currency [add-seps/with format-number-with-mask round/to n .01 "$#,##0.00" r-sep]                ; $#'##0.00  -$#'##0.00
			r-percent  [add-seps/with format-number-by-width to percent! n 1 2 r-sep]
			r-hex      [to-hex to integer! n]

			general
			standard [add-seps n]	; #,##0.0#
			fixed    [add-seps format-number-by-width n 1 2]          ; #,##0.00
			;currency [add-seps to money! n] ; $#,##0.00
			;money    [add-seps to money! n] ; $#,##0.00
			money
			currency [add-seps format-number-with-mask round/to n .01 "$#,##0.00"] ; $#,##0.00
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
	
] ; end of formatting context

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

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


;-------------------------------------------------------------------------------

set 'format-value func [
	value [number! none! time! logic! any-string!] ; money! date! 
	fmt   [word! string! block!] "Named or custom format"
	/local type
] [
	type: type?/word value
	;print ['xxx type mold value mold :fmt]
	case [
		; not sure what to do with NONE values.
		find [integer! float! percent! none!] type [format-number value fmt] ; decimal! money! 
		find [time!] type [format-date-time value fmt] ; date!
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
		find [integer! float! percent!] type [format-number value fmt] ; decimal! money!
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
