Red []

do %format.red
do %short-format.red

;-------------------------------------------------------------------------------

using: func [
	"Like USE, but combines the local words and their initial values in a spec block."
	spec [block!] "Spec-block format of words and values"
	body [block!] "Block to evaluate"
][
	with context spec body
]
; using [a: 3 b: 5] [a + b]

; Sort of like VB's with statement.
; Should it return the result of the DO, or the object?
;!! There is a risk here. If the object does NOT contain words set in
;   the body, they will escape and bind to an outer context.
with: func [
	object [object! none!]
	body   [block!]
][
	if object [do bind/copy body object]
]
; >> o: context [a: 1 b: 2]
; >> oo: context [c: 3 d: 4]
; >> oo: context [a: 3 b: 4]
; >> with o [a + b]
; == 3
; >> with oo [a + b]
; == 7

;-------------------------------------------------------------------------------

with formatting [
	tests: [
		join [
			join 1 2
			join "a" 'b
			join %a #b
			join [a] 'b
			join 'a/b 'c
			join #(a: 1) [b: 2]
			join #(a: 1) #(b: 2)
			join context [a: 1] [b: 2]
		]
		form-num-with-group-seps [
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
		pad-aligned [
			pad-aligned "" 'left 10 #" "
			pad-aligned "" 'left 10 #"0"
			pad-aligned "x" 'left 10 #"."
			pad-aligned "x" 'right 10 #"."
			pad-aligned "x" 'right -10 #"."
			pad-aligned "xxxxxxxxx" 'right 10 #"."
			pad-aligned "xxxxxxxxxx" 'right 10 #"."
			pad-aligned "xxxxxxxxxxx" 'right 10 #"."
		]
		sign-chars [
			sign-chars 1
			sign-chars 0
			sign-chars -1
			sign-chars/use+ 1
			sign-chars/use+ 0
			sign-chars/use+ -1
			sign-chars/acct 1
			sign-chars/acct 0
			sign-chars/acct -1
		]	
		format-bytes [
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
			format-bytes/as 999999999 'GiB
			format-bytes/as/to 999999999 'GiB 1.0
			format-bytes/to 999999999 .01
			format-bytes/as/to 999999999 'GiB .01
			format-bytes/to/as 1500 .1 'bytes
			format-bytes/to/as/sep 1500 .1 'bytes space
			format-bytes/to/as/sep 1500 .1 'bytes #"_"
			format-bytes 1125899906842624.0	; 1PiB
			
			format-bytes/SI 1
			format-bytes/SI 1500
			format-bytes/SI/to 1500 .1
			format-bytes/SI 2048
			format-bytes/SI 9999
			format-bytes/SI 99999
			format-bytes/SI 999999
			format-bytes/SI 9999999
			format-bytes/SI 99999999
			format-bytes/SI 999999999
			format-bytes/SI 9999999999
			format-bytes/SI 99999999999
			format-bytes/SI 999999999999
			format-bytes/SI 9999999999999
			format-bytes/SI 99999999999999
			format-bytes/SI 999999999999999
			format-bytes/SI 9999999999999999
			format-bytes/SI 99999999999999999
			format-bytes/SI 999999999999999999
			format-bytes/SI 9999999999999999999
			format-bytes/SI 99999999999999999999
			format-bytes/SI 999999999999999999999
			format-bytes/SI 9999999999999999999999
			format-bytes/SI 99999999999999999999999
			format-bytes/SI 999999999999999999999999
			format-bytes/SI 9999999999999999999999999
			format-bytes/SI 99999999999999999999999999
			format-bytes/SI 999999999999999999999999999
			format-bytes/SI/to 999999999999999999999999999 .01
			
			format-bytes/SI 999999999
			format-bytes/SI/as 999999999 'GB
			format-bytes/SI/as/to 999999999 'GB 1.0
			format-bytes/SI/to 999999999 .01
			format-bytes/SI/as/to 999999999 'GB .01
			format-bytes/SI/to/as 1500 .1 'bytes
			format-bytes/SI/to/as/sep 1500 .1 'bytes space
			format-bytes/SI/to/as/sep 1500 .1 'bytes #"_"
			
		]
		format-logic [
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
		merge-number-mask [
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
		format-number-with-style [
			format-number-with-style 0 'r-general
			format-number-with-style 0 'r-standard
			format-number-with-style 0 'r-fixed
			format-number-with-style 0 'r-currency
			format-number-with-style 0 'r-money
			format-number-with-style 0 'r-percent
			format-number-with-style 0 'r-ordinal

			format-number-with-style 0 'general
			format-number-with-style 0 'standard
			format-number-with-style 0 'fixed
			format-number-with-style 0 'currency
			format-number-with-style 0 'money
			format-number-with-style 0 'percent
			format-number-with-style 0 'ordinal

			format-number-with-style 0 'hex
			format-number-with-style 0 'min-hex
			format-number-with-style 0 'C-hex
			format-number-with-style 0 'bin
			format-number-with-style 0 'min-bin
			
			format-number-with-style 0 'sci
			format-number-with-style 0 'eng
			format-number-with-style 0 'accounting

			format-number-with-style 12345.678 'r-general
			format-number-with-style 12345.678 'r-standard
			format-number-with-style 12345.678 'r-fixed
			format-number-with-style 12345.678 'r-currency
			format-number-with-style 12345.678 'r-money
			format-number-with-style 12345.678 'r-percent
			format-number-with-style 12345.678 'r-ordinal

			format-number-with-style 12345.678 'general
			format-number-with-style 12345.678 'standard
			format-number-with-style 12345.678 'fixed
			format-number-with-style 12345.678 'currency
			format-number-with-style 12345.678 'money
			format-number-with-style 12345.678 'percent
			format-number-with-style 12345.678 'ordinal

			format-number-with-style 32767 'hex
			format-number-with-style 32767 'min-hex
			format-number-with-style 32767 'C-hex
			format-number-with-style 32767 'bin
			format-number-with-style 32767 'min-bin

			format-number-with-style 12345.678 'sci
			format-number-with-style 12345.678 'eng
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

			format-number-with-style -12345.678 'sci
			format-number-with-style -12345.678 'eng
			format-number-with-style -12345.678 'accounting
			format-number-with-style -12345 'accounting
			
		]
		format-number-by-width [
			format-number-by-width 0 0 0
			format-number-by-width 1 0 0
			format-number-by-width 123.456 0 0
			format-number-by-width -123.456 0 0

			format-number-by-width 10.5% 0 0
			format-number-by-width -10.5% 0 0
			format-number-by-width/with -10.5% 8 2 #"0"
			format-number-by-width/with -10.56% 8 2 #"0"

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
		form-num-ex [
			form-num-ex/type 0 'gen
			form-num-ex/type -0 'gen
			form-num-ex/type 0.45 'gen
			form-num-ex/type 1.45 'gen
			form-num-ex/type 12.45 'gen
			form-num-ex/type 123.45 'gen
			form-num-ex/type 1234.0 'gen
			form-num-ex/type 12345.0 'gen
			form-num-ex/type 123450.0 'gen
			form-num-ex/type 1234500.0 'gen
			form-num-ex/type 12345000.0 'gen
			form-num-ex/type 123'450'000.0 'gen
			form-num-ex/type 1'234'500'000.0 'gen
			form-num-ex/type -1'234'500'000.0 'gen
			form-num-ex/type -0.000'000'123'45 'gen
			form-num-ex/type 0.000'000'123'45 'gen
			form-num-ex/type 0.00'000'123'45 'gen
			form-num-ex/type 0.0'000'123'45 'gen
			form-num-ex/type 0.000'123'45 'gen
			form-num-ex/type 0.0012345 'gen
			form-num-ex/type 0.012345 'gen
			form-num-ex/type 0.12345 'gen
			form-num-ex/type 0.2345 'gen
			form-num-ex/type 0.345 'gen
			form-num-ex/type 0.45 'gen
			form-num-ex/type 0.5 'gen
			form-num-ex/type 1e16 'gen
			form-num-ex/type 1e-5 'gen
			form-num-ex/type 123.45% 'gen
			form-num-ex/type/to 123.45% 'gen 10%
			form-num-ex/type/to 123.45% 'gen 1%
			form-num-ex/type/to 123.45% 'gen .1

			form-num-ex/type 0 'eng
			form-num-ex/type -0 'eng
			form-num-ex/type 0.45 'eng
			form-num-ex/type 1.45 'eng
			form-num-ex/type 12.45 'eng
			form-num-ex/type 123.45 'eng
			form-num-ex/type 1234.0 'eng
			form-num-ex/type 12345.0 'eng
			form-num-ex/type 123450.0 'eng
			form-num-ex/type 1234500.0 'eng
			form-num-ex/type 12345000.0 'eng
			form-num-ex/type 123'450'000.0 'eng
			form-num-ex/type 1'234'500'000.0 'eng
			form-num-ex/type -1'234'500'000.0 'eng
			form-num-ex/type -0.000'000'123'45 'eng
			form-num-ex/type 0.000'000'123'45 'eng
			form-num-ex/type 0.00'000'123'45 'eng
			form-num-ex/type 0.0'000'123'45 'eng
			form-num-ex/type 0.000'123'45 'eng
			form-num-ex/type 0.0012345 'eng
			form-num-ex/type 0.012345 'eng
			form-num-ex/type 0.12345 'eng
			form-num-ex/type 0.2345 'eng
			form-num-ex/type 0.345 'eng
			form-num-ex/type 0.45 'eng
			form-num-ex/type 0.5 'eng
			form-num-ex/type 1e16 'eng
			form-num-ex/type 1e-5 'eng

			form-num-ex/type 0 'sci
			form-num-ex/type -0 'sci
			form-num-ex/type 0.45 'sci
			form-num-ex/type 1.45 'sci
			form-num-ex/type 12.45 'sci
			form-num-ex/type 123.45 'sci
			form-num-ex/type 1234.0 'sci
			form-num-ex/type 12345.0 'sci
			form-num-ex/type 123450.0 'sci
			form-num-ex/type 1234500.0 'sci
			form-num-ex/type 12345000.0 'sci
			form-num-ex/type 123'450'000.0 'sci
			form-num-ex/type 1'234'500'000.0 'sci
			form-num-ex/type -1'234'500'000.0 'sci
			form-num-ex/type -0.000'000'123'45 'sci
			form-num-ex/type 0.000'000'123'45 'sci
			form-num-ex/type 0.00'000'123'45 'sci
			form-num-ex/type 0.0'000'123'45 'sci
			form-num-ex/type 0.000'123'45 'sci
			form-num-ex/type 0.0012345 'sci
			form-num-ex/type 0.012345 'sci
			form-num-ex/type 0.12345 'sci
			form-num-ex/type 0.2345 'sci
			form-num-ex/type 0.345 'sci
			form-num-ex/type 0.45 'sci
			form-num-ex/type 0.5 'sci
			form-num-ex/type 1e16 'sci
			form-num-ex/type 1e-5 'sci

			form-num-ex/type 0 'acct
			form-num-ex/type -0 'acct
			form-num-ex/type 0.45 'acct
			form-num-ex/type 1.45 'acct
			form-num-ex/type 12.45 'acct
			form-num-ex/type 123.45 'acct
			form-num-ex/type 1234.0 'acct
			form-num-ex/type 12345.0 'acct
			form-num-ex/type 123450.0 'acct
			form-num-ex/type 1234500.0 'acct
			form-num-ex/type 12345000.0 'acct
			form-num-ex/type 123'450'000.0 'acct
			form-num-ex/type 1'234'500'000.0 'acct
			form-num-ex/type -1'234'500'000.0 'acct
			form-num-ex/type -0.000'000'123'45 'acct
			form-num-ex/type 0.000'000'123'45 'acct
			form-num-ex/type 0.00'000'123'45 'acct
			form-num-ex/type 0.0'000'123'45 'acct
			form-num-ex/type 0.000'123'45 'acct
			form-num-ex/type 0.0012345 'acct
			form-num-ex/type 0.012345 'acct
			form-num-ex/type 0.12345 'acct
			form-num-ex/type 0.2345 'acct
			form-num-ex/type 0.345 'acct
			form-num-ex/type 0.45 'acct
			form-num-ex/type 0.5 'acct
			form-num-ex/type 1e16 'acct		; limit of std notation
			form-num-ex/type 1e-14 'acct	; lower limit of precision
			form-num-ex/type 123.45% 'acct
			form-num-ex/type/to 123.45% 'acct 10%
			form-num-ex/type/to 123.45% 'acct 1%
			form-num-ex/type/to 123.45% 'acct .1
			
			form-num-ex/type 1234.5678 			:cust-exp-fn
			form-num-ex/type 124123234.5678 	:cust-exp-fn
			form-num-ex/type 14123234.5678 		:cust-exp-fn
			form-num-ex/type 0.0000000123456789 :cust-exp-fn    
			form-num-ex/type 0.000000123456789 	:cust-exp-fn
			form-num-ex/type -1'234'500'000.0 	:cust-exp-fn
			
		]
	]
	print mold reduce tests/join
	print mold reduce tests/form-num-with-group-seps
	print mold reduce tests/pad-aligned
	print mold reduce tests/sign-chars
	print mold reduce tests/format-bytes
	print mold reduce tests/format-logic
	print mold reduce tests/merge-number-mask
	print mold reduce tests/format-number-with-style
	print mold reduce tests/format-number-by-width
	cust-exp-fn: formatting/make-exponent-function [either any [e < -7  e > 7][e][none]]
	cust-exp-fn: func [e [integer!] "Exponent"][either any [e < -7  e > 7][e][none]]
	print mold reduce tests/form-num-ex
	;print mold reduce tests/
	;print mold reduce tests/

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
	print "deci-char-tests complete."


	format-number-with-mask-tests: context [
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
	format-number-with-mask-tests/run
	
]

block-form-tests: context [
	parse-test: function [
		input [block!] 
	][
		print "parse-as-block-format"
		print [tab "INPUT: ^/^-^-" mold input]
		res: parse-as-block-format input
		print [tab "OUTPUT:"]
		if res [
			either object? res [print [tab tab trim/lines mold res]][
				foreach item res [print [tab tab trim/lines mold item]]
			]
		]
	]
	parse-specs: [
		[(test)]
		[(20 10)]
		[tab (20 10) newline]
		[(:+)]
		[(:<)]
		[(:> 5)]
		[(:>)]
		[(5)]
		[(0 5)]
		[(:+0<_Zz¤º)] ; multi flags  $ isn't allowed. Lexing issue.
		[(/5)]
		[(/a)]
		[(/num 20 10)]
		[(/abc #xyz)]
		[(/abc :xyz)]
		[(a/b/c)]
		[((code here) xyz)]

		[(:º)]
		[(:¤)]

		[(:< fixed)]
		[(money)]
		[(/num :+<Z_ 5 2 general)]
		[(/abc ordinal) "xyz"]
		[(/abc 5 2 hex) (:< 5 2)]
		[(/abc 'hex) ":xyz"]
		[('a/b/c binary /key-x)]
		[((code here) base-64) ]

		[(system/words/pi)]

		[Color: (:< 10)  number1 (3)  http:// (:Z 5)  float: (:< 5 2)]
	]
	run-parse-tests: does [
		print ""
		foreach spec parse-specs [parse-test dbg: spec]
	]
	;------------------------------------------------------
	apply-test: function [
		input [block!] "Spec as string to be parsed"
		value
	][
		print "apply-test"
		print [tab "INPUT: " mold input]
		print [tab "VALUE: " trim/lines mold value]
		res: block-form input value
		print [tab "OUTPUT:" mold res]
	]
	apply-specs: compose/only [
		[()]			123.456
		[(general)]          123.456
		[( 20 10)]       123.456
		['tab (20 10) 'newline]   123.456
		[(:+)]         123.456
		[(:<)]         123.456
		[(:> 0 2)]         123.456
		[(:< 10)]          123.456
		[(10)]           123.456
		[(/5)]           123.456		; produces "123.456123.456" This is the single-value multi-placeholder question
		[(0 5)]           123.456
		[(:Z 7 1)]         123.456
		[(:Z 10 1)]        123.456
		[(:Z 0 1)]         123.456
		[(:Z 007 1)]       123.456
		[(:Z 15 4)]        123.456789
		[(:Z 15 4)]        -123.456789
		[(:_)]         123.456
		[(:+<0_)]     123.456

		[(10)]           123.456%
		[(:< 10)]          123.456%
		[(:+ 10)]          123.456%
		[(5 1)]          123.456%
		[(5 2)]          123.456%
		[(10 3)]         123.456%
		[(10 4)]        -123.456%

		[(2 2)]          1.2

		[(10 4) " | " (8 2) " | " (5 0)]    -123.456%
		[(8 2)] -10.5
		[(:Z 8 2)] -10.5
		[(:<Z 8 2)] -10.5				; produces "-10.5000"	; this matches printf's approach
		[(:<Z 8 2)] -12345678.5
		[(:< 8 2)] -10.5

		[(:º)] 1  
		[(:º)] 2  
		[(:º)] 3  
		[(:º)] 4  
		[(:º)] 15 
		[(:º)] 123

		[(/5)]  123.456
		[(/pi)] 123.456
		[(/a)]  123.456
		[(system/words/pi)] 123.456
		[((1 + 1))] 123.456

		[Color: (:< 10) number1 (:_ 3) number2 (:z 5) xxx] ["Red" 2 3 -45.6]		; :z /N hangs
		[Color: (:< 10) number1 (/3) number2 (:z "xxx") xxx] ["Red" 2 3 -45.6]		; :z /N hangs
		[Color: (:< 10) number1 (/3) number2 (:z /5) xxx] ["Red" 2 3 -45.6]		; :z /N hangs
		[Color: (:< 10) number1 (/3) number2 (/5 :z)] ["Red" 2 3 -45.6]
		[Color (:< 10) number1 (/3) number2 (/5 :z)  float (:< 5 2) . newline] ["Red" 2 3 -45.6]

		; word or lit-word style name are both acceptable
		[Color (col-1)| idx3 (/3 acct)| num2 (/N2 :< general)| pi (system/words/pi :< fixed)| ((1 + 1)) (now/time)] [
			"Red" n2 2 3 n4 -45.6
		]

		; Flags adjacent to named key		
		[Color (:<5)| idx3 (/3 :Z3)| num2 (/N2:<5)| pi (system/words/pi :< 5 2)| ((1 + 1)) (now/time)] [
			"Red" n2 2 3 n4 -45.6
		]

		[Color (:<5)| idx3 (/3:Z3)| num2 (/N2:<5)| pi (system/words/pi :<5 2)| ((1 + 1))(:z3) |(now/time/precise 10)|(/fn)] (compose [
			"Red" n2 2 3 n4 -45.6 fn (does [42])
		])

		; named fields in an block
		; Can't stick width up against flags. It will be silently consumed.
		[First: (/first:< 8)| Last: (/last 8)| phone: (/phoneX)] [
			first: "Gregg" last: "Irwin" phone: #208.461.9999
		]

		; named paths in an block
		; Can't stick flags up against path keys
		[First: (name/first :< 8)| Last: (name/last 8)| phone: (name/phoneX)] [
			name: [first: "Gregg" last: "Irwin" phone: #208.461.9999]
		]

		; named fields in an object
		[First: (/first :< 8)| Last: (/last 8)| phone: (/phoneX)] (context [
			first: "Gregg" last: "Irwin" phone: #208.461.9999
		])

		; named paths in an object
		[First: (name/first :< 8)| Last: (name/last 8)| phone: (name/phoneX)] (context [
			name: context [first: "Gregg" last: "Irwin" phone: #208.461.9999]
		])

		; named fields in a map
		[First: (/first :< 8)| Last: (/last 8)| phone: (/phoneX)] #(
			first: "gregg" last: "irwin" phone: #208.461.0000
		)

		; named paths in a map. Nicer escapes
		[First: (name/first :< 8)| Last: (name/last 8)| phone: (name/phoneX)] #(
			name: #(first: "gregg" last: "irwin" phone: #208.461.0000)
		)

	]
	run-apply-tests: does [
		print ""
		foreach [spec val] apply-specs [apply-test dbg: spec val]
	]
	
]
block-form-test-apply: func [str val][
	apply-short-format parse-as-block-format str val
]


block-form-tests/run-parse-tests
print '--------------------------------------
block-form-tests/run-apply-tests
print '--------------------------------------
block-form-test-apply [(5)] 123.456

halt