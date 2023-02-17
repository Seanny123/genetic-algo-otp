defmodule PopulationTest do
  use ExUnit.Case
  doctest Population

  test "mutates individual" do
    assert Population.mutate(%Individual{genes: 'AAAAAA', fitness: 0}, 'ABCD', [1, 2, 3]).genes != 'AAAAAA'
  end

  test "mates two individuals" do
    {new_indiv_a, new_indiv_b} = Population.crossover(%Individual{genes: 'AAAAAA', fitness: 0}, %Individual{genes: 'BBBBBB', fitness: 0}, 3)
    assert new_indiv_a.genes == 'AAABBB'
    assert new_indiv_b.genes == 'BBBAAA'
  end
end
