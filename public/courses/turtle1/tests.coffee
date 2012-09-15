qc = @quickCheck ? require './quickcheck'
ex = @examine ? require './examine'

assert = (result) ->
  if result != true
    throw result.errObj

run = (code, call) ->
  turtle2d.run (code + "\n\n" + call), false, false

ae = graph.almostEqual

sequencesEqual = (code, expected, call) ->
  res = run code, call
  resSeq = turtle2d.sequences
  exp = run expected, call
  expSeq = turtle2d.sequences

  assert res

  return _.isEqual(resSeq.degreesSequence, expSeq.degreesSequence) and
    ae(resSeq.anglesSequence, expSeq.anglesSequence) and
    ae(resSeq.distancesSequence, expSeq.distancesSequence)

check = (obj) ->
  res = ex.test obj
  if obj.afterwards?
    turtle2d.run obj.afterwards, false
  res

@tests = {
  nuhelnik: (code, expected) -> check
    name: "nuhelnik"
    property: (n, delka) ->
      sequencesEqual code, expected, "nuhelnik(#{n},#{delka});"
    quickCheck: [qc.arbChooseInt(3, 20), qc.arbChooseInt(5, 1000)]
    afterwards: "#{code}\n\nnuhelnik(10, 30);"
    maxSuccess: 10
  nuhelnikBeforehand: (expected) ->
    turtle2d.run "#{expected}\n\nnuhelnik(5, 30);", true
}
