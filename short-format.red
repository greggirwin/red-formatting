Red []

short-format-ctx: context [

	; I've never liked the name of this func, but I'm including it here
	; because the behavior is handy for how I'm merging masks currently.
	first+: func [		; first+next
		"Return first value in series, and increment the series index."
		'word [word! paren!] "Word must be a series."
	][
		if paren? :word [set/any 'word do :word]
		also  pick get word 1  set word next get word
	]

	;---------------------------------------------------------------------------
	;-- Short-Form Field Parser
	
	; TBD:
	; A|a flags for upper/lower case
	; Aa for mixed case (but it's not a single char flag)
	; Named formats
	format-proto: context [
		key:	; No key means take the next value; /n means pick by index if int or key if not int; 
		flags:	; 0 or more of "<>_+0Zº$¤"
		width:	; Minimum TOTAL field width
		prec:   ; Maximum number of decimal places (may be less, not zero padded on right)
		style:	; Named format
			none
	]

	=key:
	=flags:
	=width:
	=prec:
	=style:
	=plain:
	=parts:
		none
			
	digit=:     charset "0123456789"
	flag-char=: charset "_+0<>Zzº$¤"			; º=186=ordinal  ¤=164=currency
	key-sigil=: #"/"
	fmt-sigil=: #":"	; _=&@!
	sty-sigil=: #"'"
	sigil=: [key-sigil= | fmt-sigil=]
	esc-sigil=: ["^^" [#":" (append =parts ":") | "/" (append =parts "/")]]
	flags=: [copy =flags some flag-char=]
	width=: [#"*" (=width: none) | copy =width some digit= (=width: to integer! =width)]
	prec=:  [#"." [#"*" (=prec: none) | copy =prec some digit= (=prec: to integer! =prec)]]
	end-key=:   [#":" | #" " | end]
	end-style=: [#":" | #" " | #"/" | end]
	style=: [sty-sigil= copy =style to end-style= (=style: to lit-word! =style)]
	key=: [
		key-sigil= [
			[copy =key some digit= (=key: to integer! =key)]			; produce int index
			; TBD: Think about security. DOing parens is great, until you
			; get some untrusted data being used. We could easily limit
			; the length or have a secure mode lock on by default though.
			| [copy =key [#"(" thru #")"] (=key: load =key)]			; produce paren!
			| [copy =key to [end-key= skip  | end] (=key: load =key)]	; produce other key	(word, path, etc.)
		]	
	]
	
	; `/[key][:[flags][width][.precision]]['style]`
	; `:[flags][width][.precision]['style]`
	; `:[flags]['style]`
	; there may be (in this order) zero or more flags, an optional minimum 
	; field width, an optional precision and an optional length modifier.
	fmt=: [fmt-sigil= opt flags= opt width= opt prec= opt style=]
	
	field=: [
		(=flags: =width: =prec: =key: =style: none)
		[key= opt fmt= | fmt=] (
			;if find =flags #"º" [=style: quote 'ordinal]
			if find =flags charset "$¤" [=style: quote 'money]
			append/only =parts make format-proto compose [
				key: :=key flags: (=flags) width: (=width) prec: (=prec) style: (=style)
			]
		)
	]
	;TBD: support :// as plain text for urls.
	plain=: [(=plain: none) copy =plain to [sigil= | #"^^" | end] (append =parts =plain)]
	;plain=: [(=plain: none) copy =plain some [not sigil=] (append =parts =plain)]
	format=: [
		(
			=parts: copy []
			=plain: none
		)
		any [
			end break
			| esc-sigil=
			| field=
			| plain=
		]
	]
	
	;---------------------------------------------------------------------------
	;-- Internal
	
	do-paren: func [val [paren!] /local res] [
		either error? set/any 'res try [do val][
			form reduce ["*** Error:" res/id "Where:" val]
		][
			either unset? get/any 'res [""][:res]
		]
	]

	flag?: func [spec [block! object!] flag [char!]][find spec/flags flag]

	get-path-key: function [
		"Return a value for a path/key, either in data or the global context"
		data [block! object! map!]
		key [path!]
	][
		; First, try to find the key in the data we were given.
		; Failing that, try to get it from the global context.
		; That may also fail. Now/time is a special failure case,
		; but we may also get a 'no-value error. If that happens
		; when trying to GET it, there's no point in DOing it.
		val: try [get append to path! 'data key]
		if all [error? val  find [bad-path-type invalid-path no-value] val/id] [
			val: try [get key]					; now/time, e.g., fails here
			if all [error? val  val/id = 'invalid-path-get][
				val: try [do key]
			]
		]
		val
	]
	
	one-spec?: func [data [block!]][all [1 = length? data  object? data/1]]
	
	pad-aligned: func [str [string!] align [word!] wd [integer!] ch][
		switch align [
			left  [pad/with str wd ch]
			right [pad/with/left str wd ch]
		]
	]

	sign-from-flags: func [
		spec [object! block! map!]
		value
	][
		either negative? value ["-"][			; always use "-" for negative
			any [
				all [flag? spec #"+"  #"+"]		; + forces + sign
				all [flag? spec #"_"  #" "]		; _ reserves space for +/-
				""								; no sign flag = no space for sign on pos num
			]
		]
	]
	
	struct-data?:   func [data][any [block? :data  object? :data  map? :data]]
	unstruct-data?: func [data][not struct-data? :data]

	;---------------------------------------------------------------------------
	;-- Public
	
	apply-format-style: func [v style][mold :v]	; TBD
	
	set 'apply-short-format function [
		"Apply a format spec to a single value"
		spec  [block! object!] "Must support [flags width prec] keys"
		value
		return: [string!]
	][
		; Prep
		if number? value [
			if integer? prec: spec/prec [							; If we have a precision...
				if percent? value [prec: add prec 2]				; Scale precision for percent! values
				value: round/to value 10 ** negate prec				; Round the number so we can just mold it
			]
		]
		; Form
		value: case [
			spec/style [apply-format-style value spec/style]		; A named format style was used
			not number? value [form any [:value ""]]				; Coerce none to ""; form to prevent arg modifcation
			'else [
				suffix: either all [integer? value  flag? spec #"º"] [ordinal-suffix value][""]
				sign-ch: sign-from-flags spec value							; Sign is always left justified with this approach
				rejoin [sign-ch mold absolute value suffix]			; Note: absolute; no sign here
			]
		]
		; Pad
		fill-ch: either any [flag? spec #"0" flag? spec #"Z"] [#"0"][#" "]	;TBD 0 or Z?
		align:   either flag? spec #"<" ['left]['right]
		either none? spec/width [value][pad-aligned value align spec/width fill-ch]
	]

	set 'looks-like-short-format? function [
		"Return true if input looks like it contains short-format commands"
		input [string!] 
	][
		to logic! all [
			res: parse-as-short-format input
			any [object? res  find res object!]		; single object or block that has at least one object
		]
	]

	set 'parse-as-short-format func [
		"Parse input, returning block of literal string and field spec blocks"
		input [string!] 
	][
		if parse input format= [
			; If there was only a short-format in the input, return just
			; that spec directly.
			either one-spec? =parts [=parts/1][=parts]
		]
	]

	set 'short-form function [
		"Format and substitute values into a template string"
		string [string!] "Template string containing `/value:format` fields and literal data"
		data "Value(s) to apply to template fields"
	][
		result: clear ""
		if none? spec: parse-as-short-format string [return none]	; Bail if the format string wasn't valid
		if object? spec [return apply-short-format spec data]		; We got a single format spec
		collect/into [
			foreach item spec [
				keep either string? item [item][					; literal data from template string
					; If we allow objects and maps to be used, so you can select by
					; key, they won't work for format-only fields or numeric index
					; access.
					; If we get a scalar value, but more than one format placeholder,
					; does it make sense to apply to value to every placeholder?
					apply-short-format item either unstruct-data? data [data][
						; Something interesting to consider here is whether key lookups
						; should always start at the head of the series, as it may have
						; been advanced. This gets especially tricky, because you might
						; have advanced an odd/unknown number of values. We might also
						; then want a way to skip to a new index in the values.
						case [
							none?    item/key [first+ data]			; unkeyed field, take sequentially from data
							integer? item/key [pick data item/key]	; index key
							paren?   item/key [do-paren item/key]	; expression to evaluate
							path?    item/key [get-path-key data item/key]	; deep key
							'else [									; simple key name
								;?? Do we want to allow functions? I'm not so sure.
								val: select data item/key
								either any-function? :val [val][val]
							]
						]
						
					]
				]
			]
		] result
	]
	
]

