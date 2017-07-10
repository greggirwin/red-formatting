Red [
	File:    %string-formatting.red
	Purpose: "Red string formatting functions"
	Date:    "13-Apr-2017"
	Version: 0.0.1
	Author:  "Gregg Irwin"
	Notes: {
	}
	TBD: {
	}
]


string-formatting: context [
	e.g.: :comment
	
	; Generic support funcs (belong in more general mezzanine libs)
	
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

	set 'align function [
		{Justify the given string to the specified width and direction}
		s  [any-string!]  "The string to justify"
		wd [integer!] "The target width, in characters"
		/left	"Left align the string (default)"
		/center "Center align the string" 
;			{Center justify the string. If the total length of the padding
;			is an odd number of characters, the extra character will be on
;			the right.}
		/right	"Right align the string"
		/with "Fill with something other than space" 
;			{Allows you to specify filler other than space. If you specify a
;			string more than 1 character in length, it will be repeated as
;			many times as necessary.}
			filler [any-string! char!] "The character, or string, to use as filler"
	][
		if 0 >= pad-len: (wd - length? s) [return s]	; Never truncate
		filler: form any [filler space]
		result: head insert/dup make string! wd filler (wd / length? filler)
		; If they gave us a multi-char filler, and it isn't evenly multiplied
		; into the desired width, we have to add some extra chars at the end
		; to make up for the difference.
		if wd > length? result [
			append result copy/part filler (wd - length? result)
		]
		pos: either center [
			add 1 to integer! divide pad-len 2
		][
			either right [add 1 pad-len] [1]
		]
		head change/part at result pos s length? s
	]
	e.g. [
		align "a" 10
		align/center "a" 10
		align/right "a" 10
		align/with "a" 10 #"*"
		align/center/with "a" 10 #"*"
		align/right/with "a" 10 #"*"
		align/with "a" 10 "._"
		align/center/with "a" 10 "._"
		align/right/with "a" 10 "._"
		align/with "a" 10 "+________+"
		align/center/with "a" 10 "+________+"
		align/right/with "a" 10 "+________+"
		template: "+________+"
		align/with "abcd" length? template template
		align/center/with "abcd" length? template template
		align/right/with "abcd" length? template template
	]

	fill: function [
		"Fill part of a template string with a formed value"
		str [any-string!] "Template string"
		align [word!] "[left center right]"
		val "(formed) Value to insert in template string"
		;/trunc "Truncate val if longer than str" ;?? make ellipsis last char if truncated?
	][
		str: copy str							; Don't modify template string
		;if not any-string? val [val: form val]	; Prep the value
		val: form val							; Prep val; always copy as we may return it
		diff: (length? str) - (length? val)		; How much longer is the template than the value
		if not positive? diff [return val]		; Never truncate the formed value
		pos: switch/default align [
			left   [1]
			center [add 1 to integer! divide diff 2]
			right  [add 1 diff]
		][1]
		head change at str pos val
	]
	e.g. [
		template: "+________+"
		fill template 'left   ""
		fill template 'right  ""
		fill template 'center ""
		fill template 'left   "abc"
		fill template 'right  "abc"
		fill template 'center "abc"
		fill template 'left   "abcd"
		fill template 'right  "abcd"
		fill template 'center "abcd"
		fill template 'left   "abcdefghi"
		fill template 'right  "abcdefghi"
		fill template 'center "abcdefghi"
		fill template 'left   "abcdefghij"
		fill template 'right  "abcdefghij"
		fill template 'center "abcdefghij"
		fill template 'left   "abcdefghijk"
		fill template 'right  "abcdefghijk"
		fill template 'center "abcdefghijk"
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
				context [
					align=: wd=: fill=:  rules:
					=align: =wd: =fill:  mod: res:
						none

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



] ; end of string-formatting context

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
		
		parse string [
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
			parse string [
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
	
