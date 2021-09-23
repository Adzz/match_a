defmodule MatchA.MatchError do
  defexception [:message]
end

defmodule MatchA.InvalidMatchSyntax do
  defexception message: "The provided syntax is not correct for the data type you are matching"
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

  # Guess what we have a lisp.
  #     MatchA.case([
  #       # generalise the rollback thing mental.
  #       {pattern([var(:head), wildcard()]), continuation}
  #     ], [1])

  #     MatchA.destructure(pattern([var(:head), wildcard()]), [1,2,4])

  # case destructures then calls the and_then with the bindings. So does with, but it has
  # an "undo" effectively - passes through the original data though interestingly.

  # We could implement the case statement as a Pipeline - have a match trigger a rollback.
  # which is essentially a with. HANG ON! That could be a cool feature to double back to
  # the pipeline library at the end and implement `with` there (can even talk about how it
  # helps solve the problem with `with`s (that the step that fails is hard to relate to the
  # things that caused it to fail)).

  @doc """
  Returns a map of data destructured from the pattern match. The keys are the variables named in
  the pattern and the values are the data that got matched out.

  Returns {:no_match, %{}} in the event of no match and returns {:match bindings} otherwise.
  """
  def destructure(pattern, data) do
    case Match.a(data, pattern) do
      # We could return data in the event of no match, or raise. Returning data means
      # you could implement the rest higher up I suppose.
      :no_match -> {:no_match, %{}}
      {:match, bindings} -> {:match, bindings}
    end
  end

  @doc """
  is a case statement with pattern matching.
  """
  def case({:case_clauses, clauses}, data) when is_list(clauses) do
    Enum.reduce_while(clauses, :no_match, fn {:case_clause, pattern, continuation}, acc ->
      # I guess each thing needs to be able to define the way it can be matched. So lists,
      # tuples all that. That means we need to know BOTH what are we matching on AND with what
      # are we matching... which smells like double dispatch?

      # We can do this if the patterns are struct/protocols - or really modules with the same
      # fn implemented. So I guess a behaviour might be more natural.
      with {:no_match, _} <- MatchA.destructure(pattern, data) do
        {:cont, acc}
      else
        {:match, bindings} -> {:halt, {:match, bindings, continuation}}
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

  # The only reason to have pattern cases not be a list is so that we can provide validation when
  # creating case statements AND so you could change the implementation latter (to a zipper?)
  # That would mean we could undo the pattern match
  def case_clauses(cases), do: {:case_clauses, cases}
  def case_clause(pattern, continuation), do: {:case_clause, pattern, continuation}
  def variable(name), do: {:variable, name}
  # a binding can be wildcard() or variable()
  def rest(binding \\ wildcard()), do: {:rest, binding}
  def empty(), do: :empty
  def wildcard(), do: :wildcard
  def list(items), do: {:list, items}
end
