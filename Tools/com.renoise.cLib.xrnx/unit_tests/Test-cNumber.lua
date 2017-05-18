--[[ 

  Testcase for cNumber

--]]

_tests:insert({
name = "cNumber",
fn = function()

  print(">>> cNumber: starting unit-test...")

  require (_clibroot.."cNumber")
  _trace_filters = {"^cNumber*"}

  -- basic accessors

  local cnum = cNumber{
    value_min = 1,
    value_max = 100,
    value_quantum = 1,
    value = 50,
  }

  print("cnum",cnum)
  print("cnum.value",cnum.value)
  print("type(cnum)",type(cnum))
  print("type(cnum.value)",type(cnum.value))
  print("cnum()",cnum()) -- __call
  print("cnum('value')",cnum('value')) -- __call
  print("cnum.newvalue",cnum.newvalue) -- __newindex (N/A)
  print("#cnum",#cnum) -- __len 

  cnum = cnum+20
  assert(cnum()==70)

  cnum = cnum-50
  assert(cnum()==20)

  cnum = cnum*2
  assert(cnum()==40)

  cnum = cnum/4
  assert(cnum()==10)

  print("cnum.value",cnum.value)

  -- construct based on existing instance

  local cnum2 = cNumber(cnum)

  print("cnum2",cnum)
  print("cnum2.value",cnum2.value)

  print(">>> cNumber: OK - passed all tests")

end
})

