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

	; TBD:
	; A|a flags for upper/lower case
	; Aa for mixed case (but it's not a single char flag)
	; Named formats
	format-proto: context [
		key:	; No key means take the next value; /n means pick by index if int or key if not int; 
		flags:	; 0 or more of "<>_+0Z"
		width:	; Minimum total field width
		prec:   ; Maximum number of decimal places (may be less, not zero padded on right)
			none
	]

	=key:
	=flags:
	=width:
	=prec:
	=plain:
	=parts:
		none
			
	digit=:     charset "0123456789"
	flag-char=: charset "_+0<>Zz"
	key-sigil=: #"/"
	fmt-sigil=: #":"	; _=&@!
	sigil=: [key-sigil= | fmt-sigil=]
	esc-sigil=: ["^^" [#":" (append =parts ":") | "/" (append =parts "/")]]
	flags=:  [copy =flags some flag-char=]
	width=: [#"*" (=width: none) | copy =width some digit= (=width: to integer! =width)]
	prec=:  [#"." [#"*" (=prec: none) | copy =prec some digit= (=prec: to integer! =prec)]]
	end-key=: [#":" | #" "]
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
	
	; `/[key][:[flags][width][.precision]]`
	; `:[flags][width][.precision]`
	; there may be (in this order) zero or more flags, an optional minimum 
	; field width, an optional precision and an optional length modifier.
	fmt=: [fmt-sigil= opt flags= opt width= opt prec=]
	
	field=: [
		(=flags: =width: =prec: =key: none)
		[key= opt fmt= | fmt=] (
			append/only =parts make format-proto compose [
				key: :=key flags: (=flags) width: (=width) prec: (=prec)
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
	
	set 'parse-as-short-format func [
		"Parse input, returning block of literal string and printf spec blocks"
		input [string!] 
	][
		if parse input format= [
			; If there was only a short-format in the input, return just
			; that spec directly.
			either all [1 = length? =parts  block? =parts/1] [=parts/1][=parts]
		]
	]

	set 'looks-like-short-format? function [
		"Return true if input looks like it contains printf commands"
		input [string!] 
	][
		to logic! all [
			res: parse-as-short-format input
			find res block!
		]
	]

	do-paren: func [val [paren!] /local res] [
		either error? set/any 'res try [do val][
			form reduce ["*** Error:" res/id "Where:" val]
		][
			either unset? get/any 'res [""][:res]
		]
	]
	
	set 'short-form function [
		format [string!]
		values
	][
		result: clear ""
		if spec: parse-as-short-format format [
			either object? spec [apply-short-format spec value][
				collect/into [
					foreach item spec [
						keep either string? item [item] [
							; If we allow objects and maps to be used, so you can select by
							; key, they won't work for format-only fields or numeric index
							; access.
							apply-short-format item either all [
								not block? values 
								not object? values
								not map? values
							][
								; If we get a scalar value, but more than one format placeholder,
								; does it make sense to apply to value to every placeholder?
								values
							][
								; Something interesting to consider here is whether key lookups
								; should always start at the head of the series, as it may have
								; been advanced. This gets especially tricky, because you might
								; have advanced an odd/unknown number of values. We might also
								; then want a way to skip to a new index in the values.
								case [
									none? item/key [first+ values]
									integer? item/key [pick values item/key]
									path? item/key [
										; First, try to find the key in the data we were given.
										; Failing that, try to get it from the global context.
										; That may also fail. now/time is a special failure case,
										; but we may also get a 'no-value error. If that happens
										; when trying to GET it, there's no point in DOing it.
										val: try [get append to path! 'values item/key]
										if all [error? val  val/id = 'invalid-path][
											val: try [get item/key]	; 'now/time is an example of something that fails here.
											if all [error? val  val/id = 'invalid-path-get][
												val: try [do item/key]
											]
										]
										val
									]
									paren?   item/key [do-paren item/key]
									'else [
										;?? Do we want to allow functions? I'm not so sure.
										val: select values item/key
										either any-function? :val [val][val]
									]
								]
								
							]
						]
					]
				] result
			]
		]
		result
	]

	flag?: func [spec [block! object!] flag [char!]][find spec/flags flag]

	pad-aligned: func [str [string!] align [word!] wd [integer!] ch][
		switch align [
			left  [pad/with str wd ch]
			right [pad/with/left str wd ch]
		]
	]
	
	set 'apply-short-format function [
		spec  [block! object!] "Must support [flags width prec] keys"
		value
	][
		fill-ch: either any [flag? spec #"0" flag? spec #"Z"][#"0"][#" "]	;TBD 0 or Z?
		align: either flag? spec #"<" ['left]['right]
		either not number? value [
			value: case [
				none? :value [""]
				any-string? :value [value]
				'else [form :value]
			]
			either none? spec/width [value][pad-aligned value align spec/width fill-ch] 
		][
			rejoin [
				; The sign is always left justified with this approach.
				either negative? value ["-"] [				; always use "-" for negative
					any [
						all [flag? spec #"+"  #"+"]			; + forces + sign
						all [flag? spec #"_"  #" "]			; _ reserves space for +/-
						""									; no sign flag = no space for sign on pos num
					]
				]
				(
					; If we have a precision, round the number so we can just mold it.
					if integer? prec: spec/prec [
						if percent? value [prec: add prec 2]	; scale precision for percent! values.
						value: round/to value 10 ** negate prec
					]
					value: mold absolute value
					either none? spec/width [value][pad-aligned value align spec/width fill-ch]
				)
			]
		]
	]
	
]

