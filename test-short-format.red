Red []

do %format.red			; only needed for ordinal-suffix right now.
do %short-format.red

tests: context [
	parse-test: function [
		input [string!] 
	][
		print "parse-as-short-format"
		print [tab "INPUT: ^/^-^-" mold input]
		res: parse-as-short-format input
		print [tab "OUTPUT:"]
		either object? res [print [tab tab trim/lines mold res]][
			foreach item res [print [tab tab trim/lines mold item]]
		]		
	]
	parse-specs: [
		""
		":"
		"::"
		"^^:"
		"test"
		":*.*d"
		":20.10d"
		"\t:*.*\n"
		"\t:20.10d\n"
		":+*.*"
		":<*.*"
		":>*.5"
		":>"
		":5"
		":.5"
		":0*.*"
		": *.*"
		":+<>0_*.*" ; multi flags
		"0:*.*"
		"Color :s, number1 :d, number2 :05, float :5.2.\n"
		":/5"
		"/a"
		"/1"
		"/num:20.10"
		"/abc xyz"
		"/abc:xyz"
		"/a/b/c:xyz"
		"/(code here)xyz"

		":º"
		":$"
		":¤"
		
		":>'fixed"
		":'money"
		"/num:+<>Z_5.2'general"
		"/abc:'ordinal xyz"
		"/abc:'hex:<5.2"
		"/abc:'hex:xyz"
		"/a/b/c:'binary/key-x"
		"/(code here):'base-64 "
	]
	run-parse-tests: does [
		print ""
		foreach spec parse-specs [parse-test dbg: spec]
	]
	;------------------------------------------------------
	apply-test: function [
		input [string!] "Spec as string to be parsed"
		value
	][
		print "apply-test"
		print [tab "INPUT: " mold input]
		print [tab "VALUE: " trim/lines mold value]
		res: short-form input value
		print [tab "OUTPUT:" mold res]
	]
	apply-specs: compose/only [
		""				123.456
		":"             123.456
		"^^:^^:"        123.456
		"^^:"           123.456
		"test"          123.456
		":*.*d"         123.456
		":20.10d"       123.456
		"\t:*.*\n"      123.456
		"\t:20.10d\n"   123.456
		":+*.*"         123.456
		":<*.*"         123.456
		":>*.2"         123.456
		":<10"          123.456
		":>10"          123.456
		":10"           123.456
		":/5"           123.456		; XXX dupes value in output
		":.5"           123.456
		":07.1"         123.456
		":010.1"        123.456		; This is confusing, with 0 as a flag
		":00.1"         123.456		; This is confusing, with 0 as a flag
		":0007.1"       123.456		; This is confusing, with 0 as a flag
		":015.4"        123.456789	; This is confusing, with 0 as a flag
		":Z10.1"        123.456
		":Z0.1"         123.456
		":Z007.1"       123.456
		":Z15.4"        123.456789
		":_*.*"         123.456
		":+<>0_*.*"     123.456
		"0:*.*"         123.456
		
		":10"           123.456%
		":<10"          123.456%
		":+10"          123.456%
		":5.1"          123.456%
		":5.2"          123.456%
		":10.3"         123.456%
		":10.4"        -123.456%
		
		":2.2"          1.2

		":10.4 :8.2 :5.0"    -123.456%
		":8.2" -10.5
		":Z8.2" -10.5
		":<8.2" -10.5
		":º" 1
		":º" 2
		":º" 3
		":º" 4
		":º" 15
		":º" 123

		"Color :<10, number1 :3, number2 :05, float :<5.2.\n" ["Red" 2 3 -45.6]

		; "Color _<10, number1 _3, number2 _05, float _<5.2.\n" ["Red" 2 3 -45.6]
		; "Color =<10, number1 =3, number2 =05, float =<5.2.\n" ["Red" 2 3 -45.6]
		; "Color &<10, number1 &3, number2 &05, float &<5.2.\n" ["Red" 2 3 -45.6]
		; "Color @<10, number1 @3, number2 @05, float @<5.2.\n" ["Red" 2 3 -45.6]
		; "Color !<10, number1 !3, number2 !05, float !<5.2.\n" ["Red" 2 3 -45.6]

		"Color :'col-1| idx3 /3:'acct| num2 /N2:<'general| pi /system/words/pi:<'fixed| /(1 + 1) /now/time" [
			"Red" n2 2 3 n4 -45.6
		]
		
		"Color :<5| idx3 /3:Z3| num2 /N2:<5| pi /system/words/pi:<5.2| /(1 + 1) /now/time" [
			"Red" n2 2 3 n4 -45.6
		]
		;"Color Red  | idx3 003| num2 2    | pi 3.14 | 2"
		"Color :<5| idx3 /3:Z3| num2 /N2:<5| pi /system/words/pi:<5.2| /(1 + 1):z3 |/now/time/precise:10|/fn" (compose [
			"Red" n2 2 3 n4 -45.6 fn (does [42])
		])

		; named fields in an block
		"First^^: /first:<8| Last^^: /last:8| phone^^: /phoneX" [
			first: "Gregg" last: "Irwin" phone: #208.461.9999
		]

		; named paths in an block
		"First^^: /name/first:<8| Last^^: /name/last:8| phone^^: /name/phoneX" [
			name: [first: "Gregg" last: "Irwin" phone: #208.461.9999]
		]

		; named fields in an object
		"First^^: /first:<8| Last^^: /last:8| phone^^: /phoneX" (context [
			first: "Gregg" last: "Irwin" phone: #208.461.9999
		])

		; named paths in an object
		"First^^: /name/first:<8| Last^^: /name/last:8| phone^^: /name/phoneX" (context [
			name: context [first: "Gregg" last: "Irwin" phone: #208.461.9999]
		])

		; named fields in a map
		"First^^: /first:<8| Last^^: /last:8| phone^^: /phoneX" #(
			first: "gregg" last: "irwin" phone: #208.461.0000
		)

		; named paths in a map
		"First^^: /name/first:<8| Last^^: /name/last:8| phone^^: /name/phoneX" #(
			name: #(first: "gregg" last: "irwin" phone: #208.461.0000)
		)

	]
	run-apply-tests: does [
		print ""
		foreach [spec val] apply-specs [apply-test dbg: spec val]
	]
	
]
test-apply: func [str val][
	apply-short-format parse-as-short-format str val
]


tests/run-parse-tests
print '--------------------------------------
tests/run-apply-tests
print '--------------------------------------
test-apply ":5" 123.456

halt
