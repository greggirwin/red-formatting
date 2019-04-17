Red []

do %composite.red

test-composite: func [input][
	print [mold input "==" mold composite input]
]
test-composite-custom-err: func [input][
	print [mold input "==" mold composite/err-val input "#ERR"]
]
test-bad-composite: func [input][
	print [mold input "==" mold try [composite input]]
]
test-composite-marks: func [input markers][
	print [mold input mold marks tab "==" mold composite/marks input markers]
]
test-composite-with: func [input ctx][
	print [mold input "==" mold composite/with input ctx]
]
test-composite-with-fn: func [input [string!] fn [function!] arg][
	print [mold input "==" mold fn input arg]
]

print "Composite"
s: "1 + 2"
foreach val [
	""
	":(1):"
	":(pi):"
	{:("foo"):}
	":(rejoin ['a 'b]):"
	"a:('--):b"
	"a:('--):"
	":('--):b"
	"ax:(1 / 0):xb"

	"alpha: :(rejoin ['a 'b]): answer: :(42 / 3):"
	{
		name: :(form-full-name cust):
		rank: :(as-ordinal index? find scores cust):
		ser#: :(cust/uuid):
	}

	"a :('--): b"
	"a :('--):"
	":('--): b"
	"ax :(1 / 0): xb"

	{a :("1 + 2"): b}
	{a :({{1 + 2}}): b}
	{a :({"1 + 2"}): b}
	{a :(s): b}
][test-composite val]

print "^/Composite/custom-error-val"

test-composite-custom-err "ax:(1 / 0):xb"
test-composite-custom-err "ax :(1 / 0): xb"

print "^/Bad Composite Input"
foreach val [
	":("
	":('end"
	"asdf:('end"
	"):"
	"beg):"
	")::("
	":(1):beg):"
	"asdf:(1):beg):"
	":(1/a/b/c):"
	":(2abc):"
][test-bad-composite val]

print "^/Composite/Marks"
foreach [val marks] [
	"" 				["" ""]
	":(1):"			[":(" "):"]
	"):pi:("		["):" ":("]
	"a<%'--%>b"		["<%" "%>"]
	"a{'--}b"		[#"{" #"}"]
	"a{'--}}b"		[#"{" "}}"]
	"a{{'--}b"		["{{" #"}"]
	"a<c>'--</c>b"	["<c>" "</c>"]
	"a<c>'--</c>b"	[<c> </c>]
][test-composite-marks val marks]

print "^/Composite/with"
o: object [a: 1 b: 2]
foreach val [
	""
	":(1):"
	":(pi + a):"
	":(reduce [a b]):"
	":(rejoin [a b]):"
	"a:(a + b):b"
][test-composite-with val o]

; Function support is from @hiiamboris. I'm not sure about it's usefulness yet.
print "^/Composite/with (func)"
f: func [str w][
	composite/with str context? 'w
]
test-composite-with-fn ":(w):" :f 100


print ""

halt
