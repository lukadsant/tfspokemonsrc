function onSay(player, words, param)
  dofile('data/tests/test_natures.lua')
  runNatureTests(player)
  return true
end
