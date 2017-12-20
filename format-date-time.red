Red []

;do %/d/red/mezz/select-case.red

;if not value? 'format-number-by-width [
;	do %format.red
;]
if not value? 'as-ordinal [
	do %format.red
]

date-time-formatting: context [

	as-utc: func [date [date!]] [
	    if all [date/zone  0:00 <> date/zone] [
	        date: date - date/zone
	    ]
	    date/zone: 0:00
	    if none? date/time [date/time: 0:0:0]
	    date
	]

	pad-num: func [num [integer! float!] wd [integer!]][
		pad/with/left form num wd #"0"
	]

	pad-decimal: function [
		"Formats a decimal with a minimum number of digits on the left and a maximum number of digits on the right. No separators added."
		value   [integer! float!] "The value to format"
		int-len [integer!] "The number of digits desired on the left of the decimal point. (right justified, never truncates)"
		dec-len [integer!] "The number of digits desired on the right of the decimal point. (left justified, may truncate)"
	][
		dec: round/to absolute (mod value 1) (10 ** negate dec-len)
		int-part: pad-num to integer! value int-len
		dec-part: find/tail form dec #"."
		;!! `pad` modifies the arg, and returns the HEAD. We don't want that in
		;	this case, so we don't re-set dec-part to refer to pad's result.
		pad/with dec-part dec-len #"0"
		rejoin [int-part #"." dec-part]
	]
	
	combine: func [
		"Merge values, modifying a if possible"
		a "Modified if series or map"
		b "Single value or block of values; reduced if `a` is not an object or map"
	][
		if all [block? :b  not object? :a  not map? :a] [b: reduce b]
		case [
			series? :a [append a :b]
			map?    :a [extend a :b]
			object? :a [make a :b]
			'else      [append form :a :b]
		]
	]
	join: func [
		"Concatenate/merge values"
		a "Coerced to string if not a series, map, or object"
		b "Single value or block of values; reduced if `a` is not an object or map"
	][
		if all [block? :b  not object? :a  not map? :a] [b: reduce b]
		case [
			series? :a [a: copy a]
			map?    :a [a: copy a]
			object? :a []	; form or mold?
			'else      [a: form :a]
		]
		combine a b
	]


;	; rel-time-map: [ ; use 't for actual time value; result will be form reduced.
;	;     -0:0:5  to  0:0:5  ["right now"]
;	;     -0:1:0  to  0:0:0  ["moments ago"]
;	;      0:0:0  to  0:1:0  ["in less than a minute"]
;	;     -0:5:0  to  0:0:0  ["a few minutes ago"]
;	;      0:0:0  to  0:5:0  ["in a few minutes"]
;	;     -0:45:0 to  0:0:0  [[absolute to integer! t / 60 "minutes ago"]]
;	;      0:0:0  to  0:45:0 [["in" to integer! t / 60 "minutes"]]
;	;     -1:15:0 to -0:45:0 ["about an hour ago"]
;	;      0:45:0 to  1:15:0 ["in about an hour"]
;	;      case is < -1:15:0 [[format-date-time absolute t 'short-time "ago"]]
;	;      case is >  1:15:0 [["in" format-date-time absolute t 'short-time]]
;	; ]
;
;	rel-day-string: func [days [integer!]] [
;		form reduce select-case days [
;			 0 ["today"]
;			-1 ["yesterday"]
;			 1 ["tomorrow"]
;			case is < -1 [format-number absolute days 'r-general "days ago"]
;			case else    ["in" format-number days 'r-general "days"]
;		]
;	]
;
;	rel-hour-string: func [time [time!]] [
;		time: round/to time 0:15:0
;		;time: time/hour
;		form reduce select-case time [
;			 0:0:0   ["now"]
;			-1:0:0   ["an hour ago"]
;			 1:0:0   ["in an hour"]
;			-0:15:0  ["about 15 mintues ago"]
;			 0:15:0  ["in about 15 mintues"]
;			-0:30:0  ["about half an hour ago"]
;			 0:30:0  ["in about half an hour"]
;			-0:45:0  ["almost an hour ago"]
;			 0:45:0  ["in less than an hour"]
;			-1:45:0 to -1:0:0  ["more than an hour ago"]
;			 1:0:0  to 1:45:0  ["more than an hour from now"]
;			; With detault rounding, times like 2:25:0 will go to 3:0:0 because they 
;			; get rounded to 2:30:0 at the top of the func. Using /half-down means
;			; times like 2:35 will round to 2:0:0 which I like a little better in
;			; this case, based on using it for upcoming event warnings.
;			case is < -1:45:0  [absolute round/half-down/to time 1:0:0 "hours ago"]
;			case else          ["in" round/half-down/to time 1:0:0 "hours"]
;		]
;	]
;
;	rel-time-string: func [time [time!]] [ ; use 't for actual time value; result will be form reduceed.
;		form reduce select-case time [
;			-0:0:5  to  0:0:5  ["right now"]
;			-0:1:0  to  0:0:0  ["moments ago"]
;			 0:0:0  to  0:1:0  ["in less than a minute"]
;			-0:5:0  to  0:0:0  ["a few minutes ago"]
;			 0:0:0  to  0:5:0  ["in a few minutes"]
;			-0:45:0 to  0:0:0  [absolute to integer! time / 60 "minutes ago"]
;			 0:0:0  to  0:45:0 ["in" to integer! time / 60 "minutes"]
;			-1:15:0 to -0:45:0 ["about an hour ago"]
;			 0:45:0 to  1:15:0 ["in about an hour"]
;			 case is < -1:15:0 [format-date-time absolute time 'short-time "ago"]
;			 case is >  1:15:0 ["in" format-date-time absolute time 'short-time]
;		 ]
;	]

	; INET/W3C standards, like RFC822, require English names, not localized.
	en-days: ["Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"]
	en-days-abbr: ["Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun"]
	en-months: ["January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "Decdember"]
	en-months-abbr: ["Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"]
	
	set 'format-date-time func [
		value [date! time!]
		fmt   [word! string! block!] "Named, custom, or accessor format"
		/local d t tt res time-only local-date std-time year-week month-qtr rfc-3339-fmt was-time?
	] [
		; If we only got a time, assume the current date. But also set a flag so
		; we can determine later if we got a time! value as an argument. That way
		; most logic can safely assume a full date arg, but special handling can
		; also be used.
		if time? value [
			was-time?: yes					; so we can check later if the input arg was time!
			d: now
			d/time: value
			value: d
		]
		;?? If there is no /time, should we set that to the current time or 00:00?
		if all [date? value  none? value/time][
			value/time: 00:00:00
		]
		
		; Helper funcs
		time-only: func [val [date! time!]] [either time? val [val][val/time]]
		date-only: func [val [date! time!]] [either date? val [val/date][none]]
		local-date: func [date] [date - date/zone + now/zone]
		am-pm: func [time [time!] /uppercase][
			pick either uppercase [[AM PM]] [[am pm]] time < 12:00
		]
		am-pm-time: func [
			"Convert 24-hour time to 12-hour time. THIS INTENTIONALLY LOSES INFORMATION"
			time [time!]
		][
			if time >= 12:00 [time: mod time 12:00]		; Constrain to  >= 00:00 and < 12:00
			if zero? time/hour [time/hour: 12]			; Humans don't have 0 on a round clock
			time
		]
; Not used currently		
;		std-time: func [
;			"Time formatted for humans"
;			time [time!]
;			/full
;		][
;			if not full [time/second: 0]
;			form reduce [am-pm-time time am-pm/uppercase time]
;		]
		year-week: function [date [date!]][
			new-year: make date! reduce [1 1 date/year] ; to-date join "1-Jan-" year
			day-num: date - new-year + 1
			offset: new-year/weekday - 1
			either not zero? remainder (day-num + offset) 7 [
				to integer! (day-num + offset / 7) + 1
			][
				day-num + offset / 7
			]
		]
		month-qtr: func [month [integer!]] [to integer! month - 1 / 3 + 1]
		zone: func [
			"Format a timezone value, including the sign."
			z [date! time!]
			/with sep [char! string!] "Include a separator between the hours and minutes"
		][
			if date? z [z: z/zone]
			rejoin [
				(pick "-+" negative? z) (pad-num absolute z/hour 2) (any [sep ""]) (pad-num z/minute 2)
			]
		]
		; Fractional seconds are considered a rarely used option in the RFC.
		; The question for us is whether to have the user control whether
		; fractional seconds are used via a special name, or by modding their
		; data values, by trimming fractional seconds, to avoid them being
		; included.
		rfc-3339-fmt: func [value /local t] [
			t: time-only value
			; If the time includes fractional seconds, include them in
			; the format, otherwise omit them.
			format-date-time value either zero? remainder t/second 1 [
				"yyyy-mm-dd\Thhh:mm:ss±zz:zz"
			][
				"yyyy-mm-dd\Thhh:mm:sss±zz:zz"
			]
		]

		date-time-mask-formatting: context [
			res: none
			pos: none
			emit: func [val] [append res val]

			any-char: complement charset ""
			pass-char: charset " ^-^/,.' "		; space tab newline , . ' nbsp
			escape: ["^^" | "\"]
			time-sep: ":"   					; Should this be customizable?
			date-sep: "-"   					; Should this be customizable?
			; English versions, for RFC822+
			en-day-name: func [index] [pick en-days index]
			en-day-abbr: func [index] [pick en-days-abbr index]
			en-month-name: func [index] [pick en-months index]
			en-month-abbr: func [index] [pick en-months-abbr index]
			; localized versions
			day-name: func [index] [pick system/locale/days index]
			month-name: func [index] [pick system/locale/months index]
			;day-abbr: func [index] [pick system/locale/days-abbr index]
			;month-abbr: func [index] [pick system/locale/months-abbr index]
			rules: [
				(d: date-only value t: time-only value)
				any [
					  copy ch pass-char (emit ch)
					| escape copy ch any-char (emit ch)
					| ":" (emit time-sep)
					| copy ch ["-" | "/"] (emit ch) ;(emit date-sep)
					| "c" (emit format-date-time value "dd/mm/yyyy hh:mm:ss AM/PM")	; c = "C"omplete
					| "dddddd" (emit format-date-time value "dddd, mmmm dd, yyyy")
					| "ddddd" (emit format-date-time value "dd/mm/yyyy")
					;!! Note that we have *-en versions for RFC format use
					| ["dddd-en" | "monday-en" | "Monday-en"] (emit en-day-name d/weekday)
					| ["ddd-en" | "mon-en" | "Mon-en"] (emit en-day-abbr d/weekday)
					| ["dddd" | "monday" | "Monday"] (emit day-name d/weekday)		; MS uses 'aaaa for localized 'dddd
					| ["ddd" | "mon" | "Mon"] (emit copy/part day-name d/weekday 3)
					| "dd" (emit pad-num d/day 2)						; TBD allow 2 digit chars?
					| "d"  (emit d/day)									; TBD allow 1 digit char?
					; Day ordinal requires case-sensitive parsing right now.
					| "Dth" (emit as-ordinal d/day)						; ?? ["DDD" | "Dth"]
					;| "ww" (emit to integer! d/julian / 7) ; week of year
					| "ww" (emit year-week d) ; week of year
					| ["weekday" | "w"]  (emit d/weekday)
					| [
						; "hhhh"  (emit pad-num t/hour 2 emit pad-num t/minute 2 ) ; = 0800 2300 etc.
						"hhh" (emit pad-num t/hour 2) ; mil-time 00-23
						| "hh"  (tt: am-pm-time t  emit pad-num tt/hour 2)  ; note that this doesn't work for hour values > 24:00, because we just subtract 12:00.
						| "h"   (tt: am-pm-time t  emit tt/hour)
					  ]
					  opt [":" (emit time-sep)]
					  opt [
						["mm" | "nn"] (emit pad-num t/minute 2)		;?? not sure 'nn is worth having
						| ["m" | "n"] (emit t/minute)				;?? not sure 'n is worth having
					  ]
					| "sss"  (emit pad-decimal t/second 2 3) ; include decimal component to 3 places
					| "ss"   (emit pad-num to integer! t/second 2)
					| "s"    (emit to integer! t/second)
					| "ttttt"  (emit format-date-time value "hh:mm:sss AM/PM")	; long-time
					; Time meridian requires case-sensitive parsing right now.
					| ["AM/PM" | "AM-PM"] (emit am-pm/uppercase t)	;?? Are alternates helpful here?
					| ["am/pm" | "am-pm"] (emit am-pm t)
					| ["A/P" | "A-P"] (emit first form am-pm/uppercase t)
					| ["a/p" | "a-p"] (emit first form am-pm t)
					;!! Note that we have *-en versions for RFC format use
					| ["mmmm-en" | "january-en" | "January-en"] (emit en-month-name d/month)	; MS uses 'oooo for localized 'mmmm
					| ["mmm-en" | "jan-en" | "Jan-en"] (emit en-month-abbr d/month)
					| ["mmmm" | "january" | "January"] (emit month-name d/month)
					| ["mmm" | "jan" | "Jan"] (emit copy/part month-name d/month 3)
					| "mm"   (emit pad-num either was-time? [t/minute][d/month] 2)
					| "m"    (emit either was-time? [t/minute][d/month])
					| ["Mth"] (emit as-ordinal d/month)  			;?? ["MMM" | "Mth"]
					| "qqqq" (emit pick [first second third fourth] (month-qtr d/month))	; Not locale aware
					| "Qth" (emit as-ordinal month-qtr d/month)		;?? ["QQQ" | "Qth"]
					| "qq"   (emit pad-num (month-qtr d/month) 2)
					| "q"    (emit month-qtr d/month)
					| "yyyy" (emit d/year)
					| "yy"   (emit at form d/year 3)
					| "y"    (emit d/julian) 						;?? yd ytd
					; Supporting the optional ± sigil may seem unnecessary, but
					; it can act as documentation in the format string. It 
					; indicates that a sign character will be there. Since the
					; zone often comes after seconds (ss) in format strings, it
					; can also clarify that value marker position.
					| opt #"±" "zz:zz" (emit zone/with value #":")
					| opt #"±" "zzzz"  (emit zone value)
					| pos: (
						print [
							"Unexpected value in format string:" newline
							tab "Where:" mold pos newline
							tab "Index:" index? pos newline
							tab "Value:" mold pos/1 newline
							tab "Code Point:" to integer! pos/1
						]
					) reject
				]
			]
			set 'format-date-time-via-mask func [
				value [date! time!]
				fmt [string!]
			][
				;!! This isn't great, because mutually recursive calls to formatting,
				;   which can be useful in some cases, are unsafe. The reason it's 
				;   set up to use the context level var is that Red currently has 
				;   some limitations when compiling functions inside functions. We
				;   might be able to use a context in the func, which would be cleaner,
				;   but then we have all that overhead in every format call, to build
				;   the context.
				res: copy ""							; context level var so parse actions can change it
				if parse/case fmt rules [res]
			]
		]

		date-time-accessor-formatting: context [
			var: none
			pos: none
			set 'format-date-time-via-accessors function [
				value [date! time!]
				fmt [block!]
			][
				; Rejoin will let us butt up commas and such, but also means we
				; MUST use delimiting values between accessors.
				rejoin collect [
					rules: [
						any [
							set var word! (
								keep either pos: find system/catalog/accessors/date! var [
									if pos/1 = 'julian [ ;<< synonym for yearday, and not a valid index
										pos: find system/catalog/accessors/date! 'yearday
									]
									pick value index? pos
								][#NO_ACCESSOR_BY_THAT_NAME]
							)
							| set var string! (keep var)
							| set var any-type! (keep form :var)
						]
					]
					parse fmt rules
				]
			]
		]
		
		case [
			string? fmt [format-date-time-via-mask value fmt]
			block? fmt [format-date-time-via-accessors value fmt]
			'else [
				; named formats
				switch/default fmt [
					general     [form value]
					long-date   [format-date-time value "dddd, mmmm dd, yyyy"]
					medium-date [form date-only value]
					short-date  [format-date-time value "dd/mm/yyyy"]
					; 'rel-days is handled in format-number
					long-time   [format-date-time value "hh:mm:sss AM/PM"]
					medium-time [format-date-time value "hh:mm:ss AM/PM"]
					short-time  [format-date-time value "hh:mm AM/PM"]
					
					;!! Relative days and times may be outside the current scope, as
					;   they need to be locale aware.
					;rel-days    [rel-day-string value - now]
					;rel-hours   [rel-hour-string either time? value [value - now/time] [difference value now]]
					;rel-time    [rel-time-string either time? value [value - now/time] [difference value now]]
					
					; http://www.hackcraft.net/web/datetime/
					
					; http://tools.ietf.org/html/rfc3339
					; http://www.w3.org/TR/NOTE-datetime.html
					RFC3339 Atom W3C W3C-DTF [rfc-3339-fmt value]

					; http://en.wikipedia.org/wiki/ISO_8601
					ISO8601 [ ; ISO8601 without separators
						either none? value/time [
							format-date-time value "yyyymmdd"
						][
							; If we want to emit Z for UTC times, we can use the first
							; option here. The second is simpler, though, and the
							; output just as valid (and more consistent to boot).
							;format-date-time value join "yyyymmdd^^Thhhmmss" either 0:00 = value/zone ["^^Z"] ["zzzz"]
							format-date-time value "yyyymmdd^^Thhhmmss±zzzz"
						]
					]
					ISO-8601 [ ; ISO8601 with separators
						either none? value/time [
							format-date-time value "yyyy-mm-dd"
						][
							; If we want to emit Z for UTC times, we can use the first
							; option here. The second is simpler, though, and the
							; output just as valid (and more consistent to boot).
							;format-date-time value join "yyyy-mm-dd^^Thhh:mm:ss" either 0:00 = value/zone ["^^Z"] ["zzzz"]
							format-date-time value "yyyy-mm-dd^^Thhh:mm:ss±zzzz"
						]
					]
					
					; http://www.w3.org/Protocols/rfc822/
					; http://feed2.w3.org/docs/error/InvalidRFC2822Date.html
					; http://tech.groups.yahoo.com/group/rss-public/message/536
					RFC822 [
						; We use 2 digits for the year to match the spec. RFC2822 uses 4 digits.
						format-date-time value "ddd-en, dd mmm-en yy hhh:mm:ss ±zzzz"
					]
					
					; http://cyber.law.harvard.edu/rss/rss.html
					; http://diveintomark.org/archives/2003/06/21/history_of_rss_date_formats
					; http://www.ietf.org/rfc/rfc1123.txt
					; http://tools.ietf.org/html/rfc2822#page-14
					RFC2822 RFC1123 RSS [
						format-date-time value "ddd-en, dd mmm-en yyyy hhh:mm:ss ±zzzz"
					]

					; Must be in UTC
					; HTTP-date is case sensitive and MUST NOT include additional
					; LWS beyond that specifically included as SP in the grammar.
					; Per https://tools.ietf.org/html/rfc2616#section-3.3.1
					;	HTTP-date    = rfc1123-date | rfc850-date | asctime-date
					;	rfc1123-date = wkday "," SP date1 SP time SP "GMT"
					;	rfc850-date  = weekday "," SP date2 SP time SP "GMT"
					;	asctime-date = wkday SP date3 SP time SP 4DIGIT				
					;HTTP-Cookie [format-date-time value "ddd, dd mmm yyyy hhh:mm:ss GMT"]
					HTTP-Cookie [format-date-time as-utc value "dddd-en, dd mmm-en yyyy hhh:mm:ss ^^G^^M^^T"]
					RFC850 USENET [format-date-time as-utc value "dddd-en, dd mmm-en yy hhh:mm:ss ^^G^^M^^T"]
					; http://www.ietf.org/rfc/rfc1036.txt  §2.1.2
					RFC1036     [format-date-time as-utc value "ddd-en, dd mmm-en yy hhh:mm:ss ±zzzz"]
					
					; throw error - unknown named format specified?
				][either any-block? value [form reduce value] [form value]]
			]
		]
	]

]

e.g.: :comment
e.g.: :do
e.g. [
	test: func [val fmt /local res][
		res: format-date-time val fmt
		print [mold fmt  tab mold res]
	]

	dt: now/precise
	foreach fmt [
		general     
		long-date   
		medium-date 
		short-date  
		long-time   
		medium-time 
		short-time  
		;rel-days    
		;rel-hours   
		;rel-time    

		;idate
		
		RFC3339     
		Atom        
		W3C
		W3C-DTF
		
		ISO8601
		ISO-8601
		RFC822
		RSS
		RFC2822
		RFC1123
		
		HTTP-Cookie
		RFC850     
		USENET     
		RFC1036    
		
		
		"Mon, dd January, yyyy" 
		"monday, dd jan, yyyy" 
		"monday, dd jan, yyyy ±zzzz" 
		"monday, dd jan, yyyy ±zz:zz" 
		
		"c"
		"dddddd"
		"ddddd"
		"dddd"
		"ddd"
		"dd"
		"d"
		"Mon"
		"Monday"
		
		"Dth"
		
		"w"
		"ww"
		"weekday"
		
		"ttttt"
		"h:m:s"
		"hh:mm:ss"
		"hhh:mm:sss"
		"hAM/PM"
		"ham/pm"
		"hA/P"
		"ha/p"
		
		"mmmm"
		"mmm"
		"mm"
		"m"
		"Mth"

		"qqqq"
		"Qth"
		"qq"
		"q"

		"yyyy"
		"yy"
		"y"
		
		"zz:zz"
		"±zzzz"
		
		[date]
		[date time]
		[yearday julian]
		[
	        date year month day zone time hour minute second weekday yearday 
	        timezone week isoweek julian
	    ] 
	    [bad-accessor-name]
		[date " " time]
		[year "." month "." day "|" hour "_" minute "_" second]
	][test dt fmt]
		
	val: 0:0:0
	foreach fmt [long-time medium-time short-time][
		test val fmt
	]
	val: 12:0:0
	foreach fmt [long-time medium-time short-time][
		test val fmt
	]
	val: 13:0:0
	foreach fmt [long-time medium-time short-time][
		test val fmt
	]
	
	test now "monday, dd jan, yyyy ±zz:zz" 	; nbsp

	test now "x"
	test now "monday, dd jan, yyyy ±±zz:zz" 
	test now "monday, dd jan,$yyyy ±zz:zz" 
	test now "monday, dd jan, yyyy ±zz:zz$" 
	
]