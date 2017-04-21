Red []

do %composite.red

test-composite: func [input][
	print [mold input "==" mold composite input]
]
test-composite-custom-err: func [input][
	print [mold input "==" mold composite/err-val input "#ERR"]
]

print "Composite"
foreach val [
	""
	":(1):"
	":(pi):"
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

	":("
	":('end"
	"):"
	")::("
][test-composite val]

print "^/Composite/custom-error-val"

test-composite-custom-err "ax:(1 / 0):xb"
test-composite-custom-err "ax :(1 / 0): xb"



halt
