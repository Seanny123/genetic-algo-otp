defmodule Individual do
  defstruct [:genes, :fitness]
end

defmodule Population do
  # initialize population recursively and using MapSet
  def init(pop_size, indiv_len, alphabet, population) do
    if MapSet.size(population) == pop_size do
      IO.inspect(MapSet.to_list(population), label: "initial population")
      population
    else
      genes = for _ <- 1..indiv_len, do: Enum.random(alphabet)
      individual = %Individual{genes: genes, fitness: Population.eval_fitness(genes)}
      init(pop_size, indiv_len, alphabet, MapSet.put(population, individual))
    end
  end

  def mutate(seed_individual, alphabet, mut_locs) do
    new_gene =
      Enum.with_index(seed_individual.genes, fn letter, index ->
        if index in mut_locs do
          # TODO: make sure the new letter is not the same as the old one
          Enum.random(alphabet)
        else
          letter
        end
      end)

    %Individual{genes: new_gene, fitness: 0}
  end

  # mutate population until the goal size is reached
  def mutate_pop(seed_population, alphabet, pop_size, population) do
    if MapSet.size(population) == pop_size do
      population
    else
      individual =
        mutate(
          Enum.random(seed_population),
          alphabet,
          Enum.take_random(1..Optimize.indiv_len, Enum.random(1..div(Optimize.indiv_len(), 2)))
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
    cx_point = :rand.uniform(Optimize.indiv_len)
    {new_indiv_a, new_indiv_b} = crossover(indiv_a, indiv_b, cx_point)
    [new_indiv_a, new_indiv_b | acc]
  end

  # toy objective/fitness function
  # add one to score if A is found in the first half of the individual
  # or if D is found in the second half of the individual
  def eval_fitness(genes) do
    half_gene_size = Optimize.indiv_len / 2

    Enum.with_index(genes, fn letter, index ->
      cond do
        letter == ?A && index < half_gene_size ->
          1
        letter == ?D && index >= half_gene_size ->
          1
        true -> 0
      end
    end)
    |> Enum.sum()
  end

  def select(population, select_size) do
    population
    |> Enum.sort_by(& &1.fitness, :desc)
    |> Enum.take(select_size)
  end
end

defmodule Optimize do
  @pop_size 4
  @indiv_len 6
  @alphabet 'ABCD'

  def indiv_len, do: @indiv_len

  def run() do
    final_generation = Population.init(@pop_size, @indiv_len, @alphabet, MapSet.new())
    |> evaluate()
    |> loop(100)
    IO.inspect(final_generation, label: "final population")
  end

  def mate(population) do
    population
    |> Enum.chunk_every(2)
    |> Enum.reduce([], &Population.mate/2)
  end

  def evaluate(population) do
   Enum.map(population, fn individual ->
      fit = Population.eval_fitness(individual.genes)
      %{ individual | fitness: fit }
    end)
  end

  def loop(population, generations) do
    if generations == 0 do
      population
    else
      population
      |> mate()
      |> Population.mutate_pop(@alphabet, 2 * @pop_size, MapSet.new())
      |> Population.select(@pop_size)
      |> evaluate()
      |> loop(generations - 1)
    end
  end
end
