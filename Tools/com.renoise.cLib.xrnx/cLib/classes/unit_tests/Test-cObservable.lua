--[[ 

  Testcase for cObservable

--]]

require (_clibroot.."cObservable")

local base_obj = {}

local name_value = nil
local name_handler = function()
  local obs,err = cObservable.retrieve_observable('rns.name_observable')
  print("rns.name_observable",obs,err)
  name_value = obs.value
end

local prefx_value = nil
local prefx_handler = function(val)
  --local obs,err = cObservable.retrieve_observable('rns.tracks[1].prefx_volume.value_observable')
  local val,err = cLib.parse_str('rns.tracks[1].prefx_volume.value')
  print("rns.tracks[1].prefx_volume.value",val,err)
  prefx_value = val
end

__tests:insert({
name = "cObservable",
fn = function()

  print(">>> cObservable: starting unit-test...")

  -- TODO automatically attach/renew registered observables
  cObservable.set_mode(cObservable.MODE.AUTOMATIC)

  -- testing attach/detach 


  -- basic access -----------------------------------------
  -- specifying the literal name of the observable 

  -- observable,object,function

  local obs = cObservable.attach('rns.name_observable',base_obj,name_handler)
  local unique_name = "Foobar"..tostring(math.random(1,1000))
  rns.name = unique_name
  assert(name_value == unique_name)

  -- observable,function

  local obs = cObservable.attach('rns.name_observable',name_handler)
  local unique_name = "Foobar"..tostring(math.random(1,1000))
  rns.name = unique_name
  assert(name_value == unique_name)

  -- deep access --------------------------------------
  -- some observable property inside an table

  -- observable,object,function

  local obs = cObservable.attach('rns.tracks[1].prefx_volume.value_observable',base_obj,prefx_handler)
  local unique_value = math.random(0,10000)/10000
  rns.tracks[1].prefx_volume.value = unique_value
  assert(cLib.float_compare(prefx_value,unique_value,10000000))

  -- observable,function

  local obs = cObservable.attach('rns.tracks[1].prefx_volume.value_observable',prefx_handler)
  local unique_value = math.random(0,10000)/10000
  rns.tracks[1].prefx_volume.value = unique_value
  assert(cLib.float_compare(prefx_value,unique_value,10000000))

  -- dynamic access --------------------------------------
  -- an observable property which change as the parent
  -- (and also observable) object is changed 

  -- TODO

  print(">>> cObservable: OK - passed all tests")

end
})

