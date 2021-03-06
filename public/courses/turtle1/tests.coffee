qc = @quickCheck ? require './quickcheck'
ex = @examine ? require './examine'

assert = (result) ->
  if result != true
    throw result.errObj

run = (code, call) ->
  turtle2d.run (code + "\n\n" + call),
    shadow: false
    draw:   false

sequencesEqual = (code, expected, call) ->
  res = run code, call
  resSeq = turtle2d.sequences
  exp = run expected, call
  expSeq = turtle2d.sequences

  assert res
  graph.sequencesEqual resSeq, expSeq

check = (obj) ->
  res = ex.test obj
  if obj.afterwards?
    turtle2d.run obj.afterwards, shadow: false
  res

@tests = @tests ? {}
@tests.turtle1 = {
  nuhelnik: (code, expected) -> check
    name: "nuhelnik"
    property: (n, delka) ->
      sequencesEqual code, expected, "nuhelnik(#{n},#{delka});"
    quickCheck: [qc.arbChooseInt(3, 20), qc.arbChooseInt(5, 1000)]
    afterwards: "#{code}\n\nnuhelnik(10, 30);"
    maxSuccess: 10
  nuhelnikExpected: (expected, inSlide = true) ->
    turtle2d.run "#{expected}\n\nnuhelnik(5, 100);",
      shadow:  inSlide
      animate: inSlide
}
