defmodule MatchA.MatchError do
  defexception [:message]
end

defmodule MatchA.InvalidMatchSyntax do
  defexception message: "The provided syntax is not correct for the data type you are matching"
end

defprotocol Match do
  def a(data, pattern)
end

defprotocol ListPattern do
  defstruct [:patterns]
  def match(nested_pattern, data, bindings, pattern_index)
end

defprotocol VariableInAList do
  def match(data, index)
end

defmodule Zipper do
  defstruct [:zip]
end

defmodule Var do
  defstruct [:name]
end
# Need to implement this.
defimpl Match, for: ListPattern do
  def a(%ListPattern{patterns: patterns}, data) do
    Enum.reduce_while(patterns, {0, %{}}, fn pattern, {index, bindings} ->
      case ListPattern.match(pattern, data, bindings, index) do
        {:match, bound} -> {:cont, {index + 1, bound}}
        :no_match -> {:halt, {:no_match, bindings}}
      end
    end)
    |> case do
      {:no_match, _} -> raise "match error!"
      {_index, bindings} -> {:match, bindings}
    end
  end
end

defimpl ListPattern, for: Var do
  def match(%Var{name: var_name}, data, binding, index) do
    case VariableInAList.match(data, index) do
      {:ok, value} -> {:match, Map.put(binding, var_name, value)}
      :no_match -> :no_match
    end
  end
end

defimpl VariableInAList, for: List do
  def match(list, index) do
    case Enum.fetch(list, index) do
      {:ok, value} -> {:ok, value}
      :error -> :no_match
    end
  end
end

defimpl VariableInAList, for: Zipper do
  def match(%{zip: {left, right}}, index) do
    list = Enum.reverse(right) ++ left
    case Enum.fetch(list, index) do
      {:ok, value} -> {:ok, value}
      :error -> :no_match
    end
  end
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
  def a([], []), do: raise("Invalid Match Syntax")
  def a([], [:empty]), do: {:match, %{}}

  def a(_, [:empty]), do: :no_match
  def a(_, [:empty | _]), do: raise(MatchA.InvalidMatchSyntax)

  # The one element is special because it has two things in it really.
  def a([_], [:wildcard, {:rest, :wildcard}]), do: {:match, %{}}
  def a([_], [:wildcard, {:rest, {:variable, name}}]), do: {:match, %{name => []}}
  def a([element], variable: first, rest: :wildcard), do: {:match, %{first => element}}

  def a([element], variable: first, rest: {:variable, name}) do
    {:match, %{first => element, name => []}}
  end

  # Is invalid syntax or a match error?
  def a([_], [_, _]), do: :no_match

  # lol at pattern matching to implement pattern matching.
  def a([element], variable: name), do: {:match, %{name => element}}
  def a([_element], [:wildcard]), do: {:match, %{}}

  # Rest doesn't makes sense for the first element in a one element list.
  def a([_element], [{:rest, _}]), do: raise(MatchA.InvalidMatchSyntax)
  def a([_element], [_]), do: raise(MatchA.InvalidMatchSyntax)

  def a(list, pattern) when is_list(pattern) do
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
      {_, bindings} -> {:match, bindings}
    end
  end
end

defmodule MatchA do
  @moduledoc """
  Documentation for `MatchA`.
  """

  @doc """
  Returns a map of data destructured from the pattern match. The keys are the variables named in
  the pattern and the values are the data that got matched out.

  Returns {:no_match, %{}} in the event of no match and returns {:match bindings} otherwise.
  Returning a tuple like this enables you to do things on the back of no match - like raise a
  match error. This is meant as a low level utility function.
  """
  def destructure(pattern, data) do
    case Match.a(data, pattern) do
      :no_match -> {:no_match, %{}}
      # This means we can implement raising match errors and falling through to other matches
      # If we just raise here we couldn't do that.
      {:match, bindings} -> {:match, bindings}
    end
  end

  def pattern <~> data do
    case Match.a(pattern, data) do
      {:match, bindings} -> bindings
      {:no_match, _} -> raise MatchA.MatchError, "no match!"
    end
  end

  def matches?(pattern, data) do
    case MatchA.destructure(pattern, data) do
      {:no_match, _} -> false
      {:match, _} -> true
    end
  end

  @doc """
  is a case statement with pattern matching.
  """
  def case(clauses, data) when is_list(clauses) do
    Enum.reduce_while(clauses, :no_match, fn {pattern, continuation}, acc ->
      # I guess each thing needs to be able to define the way it can be matched. So lists,
      # tuples all that. That means we need to know BOTH what are we matching on AND with what
      # are we matching... which smells like double dispatch?

      # We can do this if the patterns are struct/protocols - or really modules with the same
      # fn implemented. So I guess a behaviour might be more natural. But the point is doing this
      # with double dispatch is like tricky - you need structs really.
      with {:no_match, _} <- MatchA.destructure(pattern, data) do
        {:cont, acc}
      else
        {:match, bindings} -> {:halt, {:match, bindings, continuation}}
      end
    end)
    |> case do
      {:match, bindings, continuation} -> continuation.(bindings)
      # This could also be a case clause error really.
      :no_match -> raise MatchA.MatchError, "no matches!"
    end
  end

  def var(name), do: %Var{name: name}
  # a binding can be wildcard() or variable()
  def rest(binding \\ wildcard()), do: {:rest, binding}
  def empty(), do: :empty
  def wildcard(), do: :wildcard
  def list(patterns), do: %ListPattern{patterns: patterns}
end
