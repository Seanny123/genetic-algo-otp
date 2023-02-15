defmodule Individual do
  defstruct [:genes, :fitness]
end

defmodule Population do
  # initialize population recursively and using MapSet
  def init(pop_size, indiv_len, alphabet, population \\ MapSet.new()) do
    if MapSet.size(population) == pop_size do
      population
    else
      individual = for _ <- 1..indiv_len, do: Enum.random(alphabet)
      init(pop_size, indiv_len, alphabet, MapSet.put(population, individual))
    end
  end

  def mutate(seed_individual, alphabet, mut_locs) do
    new_gene = Enum.with_index(seed_individual.genes, fn letter, index ->
      if index in mut_locs do
        Enum.random(alphabet)
      else
        letter
      end
    end)
    %Individual{genes: new_gene, fitness: 0}
  end

  def mutate_pop(seed_population, alphabet, pop_size, population \\ MapSet.new()) do
    if MapSet.size(population) == pop_size do
      population
    else
      individual =
        mutate(
          Enum.random(seed_population),
          alphabet,
          Enum.take_random(1..Main.indiv_len, Enum.random(1..div(Main.indiv_len, 2)))
        )

      mutate_pop(seed_population, alphabet, pop_size, MapSet.put(population, individual))
    end
  end

  def crossover(indiv_a, indiv_b, cx_point) do
    {head_a, tail_a} = Enum.split(indiv_a.genes, cx_point)
    {head_b, tail_b} = Enum.split(indiv_b.genes, cx_point)
    new_indiv_a = %Individual{genes: head_a ++ tail_b, fitness: 0}
    new_indiv_b = %Individual{genes: head_b ++ tail_a, fitness: 0}
    {new_indiv_a, new_indiv_b}
  end

  def mate([indiv_a, indiv_b], acc) do
    cx_point = :rand.uniform(Main.indiv_len())
    {new_indiv_a, new_indiv_b} = crossover(indiv_a, indiv_b, cx_point)
    [new_indiv_a, new_indiv_b | acc]
  end

  def new_generation(population, pop_size) do
    mated_pop =
      population
      |> Enum.chunk_every(2)
      |> Enum.reduce([], &mate/2)
      |> IO.inspect(label: "mated")

    mutate_pop(mated_pop, Main.alphabet, pop_size)
  end
end

defmodule Main do
  def indiv_len, do: 6

  def alphabet, do: 'ABCD'

  def run do
    alphabet = 'ABCD'

    pop_size = 4
    indiv_len = 6

    population = Population.init(pop_size, indiv_len, alphabet)
    IO.inspect(MapSet.to_list(population), label: "population")

    # add one to score if A is found in the first half of the individual
    # or if D is found in the second half of the individual
    population =
      population
      |> Enum.map(fn individual ->
        score =
          Enum.with_index(individual, fn letter, index ->
            case letter do
              ?A when index < div(indiv_len, 2) -> 1
              ?D when index >= div(indiv_len, 2) -> 1
              _ -> 0
            end
          end)
          |> Enum.sum()

        %Individual{genes: individual, fitness: score}
      end)

    IO.inspect(population, label: "population")

    # select best half of population
    population =
      population
      |> Enum.sort_by(& &1.fitness, :desc)
      |> Enum.take(div(length(population), 2))
      |> Population.new_generation(pop_size)

    IO.inspect(MapSet.to_list(population), label: "new population")
  end
end

Main.run()
