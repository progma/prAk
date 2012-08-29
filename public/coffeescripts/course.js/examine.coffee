root = exports ? this
qc = root.quickCheck

##
## Settings
##
sandboxID = 'sandbox'


# Very simple comparison function. It doesn't care about class names or hidden
# attributes.
deepeq = (a, b) ->
  return a == b unless a instanceof Object && b instanceof Object
  return false if Object.keys(a).length != Object.keys(b).length

  for own prop of a
    return false unless deepeq a[prop], b[prop]

  true

# Create test case
#
# Arguments:
# - array of arguments for tested function/property
# - expected result    (optional, default true)
# - name of test case  (optional, default "")
T = (args, res = true, name = "") ->
  args: args
  expected: res
  name: name

# Create named test case
#
# Arguments:
# - array of arguments for tested function/property
# - name of test case  (optional, default "")
#
# Expected result is set to true.
Tn = (args, name = "") ->
  T args, undefined, name

# Testing user code.
#
# In property/testedFunction is user's environment accessible via @user
# variable. In our example below are @user.log, @user.alert, @user.foo,
# @user.bar added to scope too.
#
# Example:
#
# examine.test {
#   name: "Test name"
#
#   code: "..."                       # users code to load before tests (optional)
#                                     # needs jQuery, use @user.fun(...) for
#                                     # users functions
#   environment:
#     log: console.log                # (optional) adds functions to global scope
#     alert: alert                    # for user code
#     ...
#
#   constants:                        # (optional) adds constants/objects to global
#     foo: 10                         # scope for user code
#     bar: "not wrapped"
#
#   property: somePropertyToTest
#   quickCheck: [generators in array] # if ommited dont use QuickCheck
#   quickCheckArgs: args              # if ommited use default
#   quickCheckExpected: true | false  # default true
#
#   testedFunction: someFunction      # if ommited use @property
#   testCases: [
#     T  [1,2,3]      # args
#      , 6            # expected result
#      , "Small ..."  # test case name (default "")
#
#     Tn [3,2,1]     # args
#      , "Reversed"  # test case name (default "")
#
#     T [0,0,0], 0, "Zero case"
#     T or Tn ...
#   ]
# }
# Best use case:
# - use just property with QuickCheck and/or testCases (expecting true/false)
# - use just testedFunction with testCases and expected result always set
#
# Note:
# - if environment is set QuickCheck runs with variables defined by environment
#   property and ignores quickCheckArgs.user
#
# Returns just true if test succeeded or object containing fail informations

test = (settings) ->
  resObj = testName: settings.name

  try
    if 'code' of settings
      # Users code is sandboxed inside a hidden iframe
      sandboxFrame = $ '<iframe/>', id: sandboxID
      sandboxFrame.css "display", "none"
      $('body').append sandboxFrame
      user = sandboxFrame.get(0).contentWindow

      if 'environment' of settings
        setEnvironment user, settings.environment

      if 'constants' of settings
        user[i] = val for i, val of settings.constants

      # Parse users code
      user.eval settings.code

    if 'quickCheck' of settings
      qcArgs = settings.quickCheckArgs ? qc.stdArgs
      qcArgs.user = user  # export environment for QuickCheck

      resObj.qcRes =
        qc.runWith qcArgs
                 , settings.property
                 , settings.quickCheck...

      # Fail if succeeded and is supposed to fail or converse
      if resObj.qcRes == true           && settings.quickCheckExpected == false ||
         resObj.qcRes instanceof Object && settings.quickCheckExpected != false
        resObj.quickCheckFailed = true
        return resObj

    if 'testCases' of settings
      for tc in settings.testCases
        # Set user environment so that all inner functions/variables are
        # accessible in testedFunction or tested property via @user
        logObj = user: user

        res = (settings.testedFunction ? settings.property).apply logObj, tc.args

        # Fail if result is different to expected result
        if not deepeq res, tc.expected
          resObj.testsRes  = false
          resObj.testRes   = res
          resObj.epected   = tc.expected
          resObj.testCases = tc.args
          resObj.name      = tc.name
          resObj.logObj    = logObj
          return resObj

  catch err
    resObj.errorOccurred = true
    resObj.errObj = err
    resObj.reason = czechErrorName err

    return resObj
  finally
    stopExecution sandboxID

  true

czechErrorName = (err) ->
  # TODO lepe okomentovat, tzn rozepsat pripady kdy
  #  - se pouzije nedefinovana promenna
  #  - pristoupi se k neexistujici polozce v poli a neco s ni
  #  - vola se cislo jako funkce (pripadne undefined)
  #  - ...
  switch err.name
    when "RangeError"
      "Chyba mezí (#{err.message})."
    when "ReferenceError"
      "Použita neexistující proměnná nebo funkce." # TODO zkusit presah pole
    when "SyntaxError"
      "Syntaktická chyba (#{err.message})."
    when "TypeError"
      "Nesprávné použití hodnoty. Nevoláš funkci na nedefinované proměnné?"
    # when "EvalError"
    #   "Asi syntax error." # TODO podaří se vyvolat?
    else
      "Neznámá chyba (#{err.toString()})"

setEnvironment = (to, from) ->
  for i of from
    to[i] = do (i) -> ->
      throw Error 'Code stopped from outside.' if to.__STOP == true
      from[i] arguments...

  to.__STOP = -> to.__STOP = true

stopExecution = (iframeID = sandboxID) ->
  $("#"+iframeID)
    .detach().end()
    .get(0)?.contentWindow?.__STOP()


##
## Exports
##
(exports ? this).examine = {
  deepeq
  T
  Tn
  test
  sandboxID
  stopExecution
}
