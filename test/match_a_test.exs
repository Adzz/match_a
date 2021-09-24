defmodule MatchATest do
  use ExUnit.Case
  doctest MatchA

  import MatchA,
    only: [
      variable: 1,
      rest: 1,
      rest: 0,
      empty: 0,
      wildcard: 0,
      list: 1
    ]

  # If we make it a case fn then we'd have to implement case for every data type which
  # no one wants. They need to be higher order - case takes a list of patterns and
  # matching_functions (fns to do on match) that all use the matching (which is essentially)
  # the control flow part. How is it different from destructuring?

  describe "destructure/2" do
    test "[head, _] = [1, 2]" do
      pattern = list([variable(:head), wildcard()])
      assert MatchA.destructure(pattern, [1, 2]) == {:match, %{head: 1}}
    end
  end

  describe "case/2 for lists" do
    test "[head, _] = [1, 2]" do
      pattern = list([variable(:head), wildcard()])
      consequence = & &1

      assert MatchA.case([{pattern, consequence}], [1, 2]) == %{head: 1}

      # With continuation...
      pattern = list([variable(:head), wildcard()])
      consequence = fn bindings -> Map.put(bindings, :head, bindings.head + 1) end
      assert MatchA.case([{pattern, consequence}], [1, 2]) == %{head: 2}

      assert_raise(MatchA.MatchError, "no matches!", fn ->
        MatchA.case([{pattern, consequence}], [1])
      end)
    end

    test "[head | rest] = [1, 2]" do
      pattern = list([variable(:head), rest(variable(:rest))])

      assert MatchA.case([{pattern, & &1}], [1, 2]) == %{head: 1, rest: [2]}
      assert MatchA.case([{pattern, & &1}], [1]) == %{head: 1, rest: []}
    end

    test "[head | _] = [1, 2]" do
      pattern = list([variable(:head), rest(wildcard())])
      assert MatchA.case([{pattern, & &1}], [1, 2]) == %{head: 1}

      pattern = list([variable(:head), rest()])
      assert MatchA.case([{pattern, & &1}], [1, 2]) == %{head: 1}
    end

    test "[head, rest] = [1]" do
      pattern = list([variable(:head), variable(:rest)])

      assert_raise(MatchA.MatchError, "no matches!", fn ->
        MatchA.case([{pattern, & &1}], [1])
      end)
    end

    test "[] = []" do
      pattern = list([empty()])

      assert MatchA.case([{pattern, & &1}], []) == %{}

      assert_raise(MatchA.MatchError, "no matches!", fn ->
        MatchA.case([{pattern, & &1}], [1])
      end)
    end
  end
end
