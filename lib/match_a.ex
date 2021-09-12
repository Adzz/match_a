defmodule MatchA.MatchError do
  defexception [:message]
end

defprotocol Match do
  @moduledoc """

  """
  def a(data, pattern)
end

# erlang :arrays are tuples.. Probably until they are not or some shit but let's go with it...
defimpl Match, for: Tuple do
  # :array.set(17, true, :array.new(5))
  # {:array, 5, 0, :undefined,
  #   {:undefined, :undefined, :undefined, true, :undefined, :undefined, :undefined, :undefined, :undefined, :undefined}
  # }
  # We could also wrap in a struct which is possibly better.
  def a({:array, _, _, _, _}, _pattern_case) do
    :no_match
  end
end

defimpl Match, for: List do
  @doc """
  Incoming pattern should look something like this:
      [%Variable{}, %Rest{}]
      [%Variable{}, %Rest{binding: %Variable{name: :thing}}]

  """
  # def a(x, p), do: p |> IO.inspect(limit: :infinity, label: "")
  # raise("Invalid Match Syntax")
  def a([], []), do: raise("Invalid Match Syntax")
  def a([], {:case, [:empty], continuation}), do: {:match, %{}, continuation}

  def a(_, {:case, [:empty], _}), do: raise("no matches!")
  def a(_, {:case, [:empty | _], _}), do: raise("Invalid Match Syntax")

  # The one element is special because it has two things in it really.
  def a([_], {:case, [:wildcard, {:rest, :wildcard}], continuation}) do
    {:match, %{}, continuation}
  end

  def a([_], {:case, [:wildcard, {:rest, {:variable, name}}], continuation}) do
    {:match, %{name => []}, continuation}
  end

  def a([element], {:case, [variable: first, rest: :wildcard], continuation}) do
    {:match, %{first => element}, continuation}
  end

  def a([element], {:case, [variable: first, rest: {:variable, name}], continuation}) do
    {:match, %{first => element, name => []}, continuation}
  end

  # Is invalid syntax or a match error?
  def a([_], {:case, [_, _], _continuation}), do: :no_match

  # lol at pattern matching to implement pattern matching.
  def a([element], {:case, [{:variable, name}], continuation}) do
    {:match, %{name => element}, continuation}
  end

  def a([_element], {:case, [:wildcard], continuation}) do
    {:match, %{}, continuation}
  end

  # Rest doesn't makes sense for the first element in a one element list.
  def a([_element], {:case, [{:rest, _}], _}), do: raise("Invalid Match Syntax")
  def a([_element], {:case, [_], _}), do: raise("Invalid Match Syntax")

  def a(list, {:case, pattern, continuation}) when is_list(pattern) do
    # A list could have anything in it so we need a unique value to be able to determine
    # if the list is out of bounds.
    out_of_bounds = make_ref()
    list_length = length(list)

    Enum.reduce_while(pattern, {0, %{}}, fn
      {:variable, var_name}, {index, bindings} ->
        case Enum.at(list, index, out_of_bounds) do
          ^out_of_bounds -> {:halt, :no_match}
          value -> {:cont, {index + 1, Map.put(bindings, var_name, value)}}
        end

      {:rest, :wildcard}, {index, bindings} ->
        # We still need to check that index is valid - we have a valid match.
        case Enum.at(list, index, out_of_bounds) do
          ^out_of_bounds -> {:halt, :no_match}
          # Rest is the end of the pattern so we halt if we see it.
          _value -> {:halt, {index + 1, bindings}}
        end

      {:rest, {:variable, var_name}}, {index, bindings} ->
        # We still need to check that index is valid - we have a valid match.
        case Enum.at(list, index, out_of_bounds) do
          ^out_of_bounds ->
            {:halt, :no_match}

          _value ->
            rest = Enum.slice(list, index..list_length)
            # Rest is the end of the pattern so we halt if we see it.
            {:halt, {index + 1, Map.put(bindings, var_name, rest)}}
        end

      :wildcard, {index, bindings} ->
        {:cont, {index + 1, bindings}}
    end)
    |> case do
      :no_match -> :no_match
      {_, bindings} -> {:match, bindings, continuation}
    end
  end
end

defmodule MatchA do
  @moduledoc """
  Documentation for `MatchA`.
  """

  @doc """
  Guess what we have a lisp.
      MatchA.case([
        # generalise the rollback thing mental.
        {pattern([var(:head), wildcard()]), continuation}
      ], [1])

      MatchA.destructure(pattern([var(:head), wildcard()]), [1,2,4])

  case destructures then calls the and_then with the bindings. So does with, but it has
  an "undo" effectively - passes through the original data though interestingly.

  We could implement the case statement as a Pipeline - have a match trigger a rollback.
  which is essentially a with. HANG ON! That could be a cool feature to double back to
  the pipeline library at the end and implement `with` there (can even talk about how it
  helps solve the problem with `with`s (that the step that fails is hard to relate to the
  things that caused it to fail)).
  """
  def case({:pattern_cases, cases}, data) do
    with :no_match <- Match.a(data, pattern) do
        {:cont, acc}
      else
        {:match, bindings, continuation} -> {:halt, {:match, bindings, continuation}}
      end
    end)
    |> case do
      {:match, bindings, continuation} -> continuation.(bindings)
      # We could not raise and have the caller decide what to do. Raising a match error
      # happens in some places in elixir, but sometimes leads to fallthrough like case / with
      # etc. I suppose we are really defining case statements.
      :no_match -> raise MatchA.MatchError, "no matches!"
    end
  end

  # destructure? bindings? match? attempt_match?
  def bind() do
  end

  @doc """
  """
  # This is really more of a case statement. Which means we should make the continuations
  # required. If we just want bindings then that should be another fn probably which this fn
  # calls.
  def match({:pattern_cases, cases}, data) do
    Enum.reduce_while(cases, :no_match, fn pattern, acc ->
      # I guess each thing needs to be able to define the way it can be matched. So lists,
      # tuples all that. That means we need to know BOTH what are we matching on AND with what
      # are we matching... which smells like double dispatch?

      # We can do this if the patterns are struct/protocols - or really modules with the same
      # fn implemented. So I guess a behaviour might be more natural.
      #
      with :no_match <- Match.a(data, pattern) do
        {:cont, acc}
      else
        {:match, bindings, continuation} -> {:halt, {:match, bindings, continuation}}
      end
    end)
    |> case do
      {:match, bindings, continuation} -> continuation.(bindings)
      # We could not raise and have the caller decide what to do. Raising a match error
      # happens in some places in elixir, but sometimes leads to fallthrough like case / with
      # etc. I suppose we are really defining case statements.
      :no_match -> raise MatchA.MatchError, "no matches!"
    end
  end

  # pattern([
  #   # By default continuation is ID
  #   case conflicts with kernel though.... so perhaps pattern case?
  #   bit long though
  #   pattern_case([var(:head), wildcard()]),
  #   pattern_case([empty()], & &1 + 1),
  #   pattern_case([wildcard(), rest(wildcard())], & &1 + 1),
  #   pattern_case([wildcard(), rest(var(:tail)) ], & &1 + 1),
  # ])
    # Aside:
    # Really pattern is "case statement:, Because the idea of continuation isn't inherent
    # to PM but part of the case idea. That means we could have other kinds of things
    # like a simple "assign" that takes one pattern and returns bindings for it - or raises
    # in the case of a match error.
    # Then you could do with etc etc.
    # assign(bindings()), data
    # really I guess the data being match sits in the assign then..,

  # We should think about whether the original struct implementation gives
  # use anything with regard to protocols. At a guess we might get some kind of
  # multiple dispatch behaviour but what does that extensibility buy?
  # Multiple representations of the pattern syntax?
  # Dispatching on the data being matched makes more sense because then you can
  # validate the syntax for that data type.

  # You could essentially be like "implement this pattern syntax for a list" and you'd
  # know for sure it was a list because of the previous protocol. It might mean that you'd
  # need to implement that matching protocol for a list for _all_ patterns. But that might
  # give you an easy way to be like "invalid match syntax" because if it's not implemented
  # then

  # Do we get extensible patterns (yes) using protocols. Because we'd be able to define our
  # own pattern structs and implement the protocol for them.

  # You would need a lot of protocols though. Like one for every data type / pattern.
  # (this is the whole solving the expression problem post) Say you define a %Last{} pattern
  # and you wanted to implement it for a list then you'd have to
  defprotocol Last do
    defstruct []
    @fallback_to_any true
    def match(data)
  end

  defimpl Last, for: List do
    def match(list) do
      List.last(list)
    end
  end

  # Can't remember the syntax but essentially we can fallback to any.
  # This is cool but is it better? And can we explain it in a 40 min talk?
  # probs difficult.
  defimpl Last, for: Any do
    def match(data) do
      raise "Invalid match syntax - Last not implemented for #{inspect(data)}"
    end
  end

  defprotocol Pattern do
    def evaluate(pattern, data)
  end

  defimpl Pattern, for: Last do
    def evaluate(%struct{}, pattern) do
      struct.match(pattern)
    end
  end
  pattern = %Last{}
  data = [1,2]
  Pattern.evaluate(pattern, data)

  # we could validate the cases here and then raise pattern syntax errors
  # we could also do that at compile time I presume and therefore not affect runtime with that
  def pattern_cases(cases), do: {:pattern_cases, cases}
  def pattern_case(pattern, continuation \\ & &1), do: {:case, pattern, continuation}
  # This would be like the individual pattern that would / could appear in the case.
  # A pattern on its own is really just bindings.
  def pattern(pattern), do: {:pattern, pattern}
  def variable(name), do: {:variable, name}
  # a binding can be wildcard() or variable()
  def rest(binding \\ wildcard()), do: {:rest, binding}
  def empty(), do: :empty
  def wildcard(), do: :wildcard
end
