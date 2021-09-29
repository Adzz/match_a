add_two = fn x -> x + 2 end
times_three = fn x -> x * 3 end

PipeLine.new(1)
|> PipeLine.add_steps([
  add_two,
  times_three
])
|> PipeLine.execute()


PipeLine.new(1)
|> PipeLine.add_steps([
  add_two,
  times_three
])
|> PipeLine.with_trace()

{[current_step | _ ], [previous_step | _]} = pipeline.steps

def with_trace(%Pipeline{steps: steps, state: state}) do
  Enum.reduce(steps, state, fn step, acc ->
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = step.action.(acc)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    new_state
  end)
end

def with_trace(%Pipeline{steps: steps, state: state}) do
  Enum.reduce_while(steps, state, fn step, acc ->
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = step.action.(acc)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    case new_state do
      {:ok, _} -> {:cont, new_state}
      {:error, _} -> {:halt, new_state}
    end
  end)
end


%PipeLine{
  ...
  steps: [
    %PipeLine.Step{action: add_two},
    %PipeLine.Step{action: times_three}
  ]
}

%PipeLine{
  ...
  steps: [
    %PipeLine.Step{action: add_two, on_error: subtract_two},
    %PipeLine.Step{action: times_three, on_error: divide_by_three}
  ]
}

%Square{}
%Triangle{}
%Circle{}

defprotocol Shape do
  def area(shape)
  def perimeter(shape)
end

defmodule Square do
  defstruct [...]
end

defmodule Triangle do
  defstruct [...]
end

defimpl Shape, for: Trianlge do
  ...
end

defimpl Shape, for: Square do
  ...
end

defmodule Triangle do
  defstruct :area, :perimeter
end

defmodule Circle do
  defstruct :area, :perimeter
end

# A possible solution is:

%PipeLine{}
%PipeLine.Reversible{}

# That means our with_trace function isn't like broken, but it is now incomplete.
# so we are forced to choose between having to right a with_trace for every kind of
# pipeline. OR have to change the implementation to handle the internal details.


defmodule PipeLine do
  def next_step(...) do
    ...
  end

  def previous_step(...) do
    ...
  end
end

def with_trace(pipeline) do
  if Pipeline.complete?(pipeline) do
    pipeline.state
  else
    current = PipeLine.current_step(pipeline)
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = PipeLine.Step.execute(current)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    with_trace(PipeLine.update_state(pipeline, new_state))
  end
end

# Actually it should be this.

def with_trace(pipeline) do
  if Pipeline.complete?(pipeline) do
    pipeline.state
  else
    current = PipeLine.current_step(pipeline)
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = PipeLine.Step.execute(current)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    # We don't want to handle and trace the rollback, but we want to at least not break the
    # previous implementations.

    case new_state do
      {:error, _} ->
        pipeline
        |> PipeLine.update_state(new_state)
        |> PipeLine.previous_step()
        |> PipeLine.rollback()

      {:ok, state} ->
        pipeline
        |> PipeLine.update_state(new_state)
        |> PipeLine.next_step()
        |> with_trace()
    end
  end
end

def with_trace(pipeline) do
  if Pipeline.complete?(pipeline) do
    pipeline.state
  else
    current = PipeLine.current_step(pipeline)
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = PipeLine.Step.execute(current)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    case new_state do
      {:error, _} -> ...
      {:ok, _} ->
        pipeline
        |> PipeLine.update_state(new_state)
        |> PipeLine.next_step()
        |> with_trace()
    end
  end
end

# So really the motivating example has to match to make it somewhat convincing when
# we use reduce it just becomes about "implement enumerable" and distracts from it.
# but

# Should be this because then they are even closer

def with_trace(%Pipeline{steps: steps, state: state} = pipeline) do
  if [] == steps do
    state
  else
    [current_step | rest ] = steps

    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = current_step.action.(state)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    case new_state do
      {:error, _} -> new_state
      {:ok, _} -> with_trace(%{pipeline | state: new_state, steps: rest})
    end
  end
end

# With functions

def with_trace(pipeline) do
  if Pipeline.complete?(pipeline) do
    pipeline.state
  else
    current = PipeLine.current_step(pipeline)

    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = PipeLine.Step.execute(current)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    case new_state do
      {:error, _} ->
        pipeline.state

      {:ok, _} ->
        pipeline
        |> PipeLine.update_state(new_state)
        |> PipeLine.next_step()
        |> with_trace()
    end
  end
end

# with pattern matching

def with_trace(%Pipeline{steps: steps} = pipeline) do
  if MatchA.matches?([empty()], steps) do
    pipeline.state
  else
    bindings = [var(:current_step), rest(var(:rest))] <~> steps

    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = bindings.current_step.action.(state)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    case new_state do
      {:error, _} -> new_state
      {:ok, _} -> with_trace(%{pipeline | state: new_state, steps: bindings,rest})
    end
  end
end

