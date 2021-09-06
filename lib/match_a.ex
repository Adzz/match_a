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
  def a([], []), do: raise("Invalid Match Syntax")
  def a([], {:case, [:empty]}), do: {:match, %{}}

  def a(_, {:case, [:empty]}), do: raise("no matches!")
  def a(_, {:case, [:empty | _]}), do: raise("Invalid Match Syntax")

  # The one element is special because it has two things in it really.
  def a([_], {:case, [:wildcard, {:rest, :wildcard}]}), do: {:match, %{}}
  def a([_], {:case, [:wildcard, {:rest, {:variable, name}}]}), do: {:match, %{name => []}}

  def a([element], {:case, [{:variable, first}, {:rest, :wildcard}]}) do
    {:match, %{first => element}}
  end

  def a([element], {:case, [{:variable, first}, {:rest, {:variable, name}}]}) do
    {:match, %{first => element, name => []}}
  end

  def a([_], {:case, [_, _]}), do: raise("Invalid Match Syntax")

  # lol at pattern matching to implement pattern matching.
  def a([element], {:case, [{:variable, name}]}), do: {:match, %{name => element}}
  def a([_element], {:case, [:wildcard]}), do: {:match, %{}}
  # Rest doesn't makes sense for the first element in a one element list.
  def a([_element], {:case, [{:rest, _}]}), do: raise("Invalid Match Syntax")
  def a([_element], {:case, [_]}), do: raise("Invalid Match Syntax")

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
  """
  def match(pattern_cases, data) do
    do_the_match(pattern_cases, data, false)
  end

  # match/2 is really `bindings/2` and this is like do
  def match_and_continue(pattern_cases, data) do
    do_the_match(pattern_cases, data, true)
  end

  defp do_the_match({:pattern_cases, cases}, data, continue?) do
    Enum.reduce_while(cases, :no_match, fn pattern, acc ->
      # I guess each thing needs to be able to define the way it can be matched. So lists,
      # tuples all that. That means we need to know BOTH what are we matching on AND with what
      # are we matching... which smells like double dispatch?
      with :no_match <- Match.a(data, pattern) do
        {:cont, acc}
      else
        {:match, bindings, continuation} -> {:halt, {:match, bindings, continuation}}
      end
    end)
    |> case do
      {:match, bindings, continuation} ->
        if continue? do
          continuation.(bindings)
        else
          bindings
        end

      :no_match ->
        raise "no matches!"
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
