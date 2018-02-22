--[[ 

  Testcase for cNumber

--]]

_tests:insert({
name = "cNumber",
fn = function()

  LOG(">>> cNumber: starting unit-test...")

  cLib.require (_clibroot.."cNumber")
  _trace_filters = {"^cNumber*"}

  -- basic accessors

  local cnum = cNumber{
    value_min = 1,
    value_max = 100,
    value_quantum = 1,
    value = 50,
  }

  LOG("cnum",cnum)
  LOG("cnum.value",cnum.value)
  LOG("type(cnum)",type(cnum))
  LOG("type(cnum.value)",type(cnum.value))
  LOG("cnum()",cnum()) -- __call
  LOG("cnum('value')",cnum('value')) -- __call
  LOG("cnum.newvalue",cnum.newvalue) -- __newindex (N/A)
  LOG("#cnum",#cnum) -- __len 

  cnum = cnum+20
  assert(cnum()==70)

  cnum = cnum-50
  assert(cnum()==20)

  cnum = cnum*2
  assert(cnum()==40)

  cnum = cnum/4
  assert(cnum()==10)

  LOG("cnum.value",cnum.value)

  -- construct based on existing instance

  local cnum2 = cNumber(cnum)

  LOG("cnum2",cnum)
  LOG("cnum2.value",cnum2.value)

  LOG(">>> cNumber: OK - passed all tests")

end
})

