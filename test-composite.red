Red []

do %composite.red

test-composite: func [input][
	print [mold input "==" mold composite input]
]
test-composite-no-err: func [input][
	print [mold input "==" mold composite/hide-errors input]
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
	":("
	":('end"
	"):"
	")::("
][test-composite val]

print "^/Composite/hide-errors"

test-composite-no-err "ax:(1 / 0):xb"


halt
