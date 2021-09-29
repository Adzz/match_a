defmodule MatchATest do
  use ExUnit.Case
  doctest MatchA

  import MatchA,
    only: [
      var: 1,
      rest: 1,
      rest: 0,
      empty: 0,
      wildcard: 0,
      <~>: 2
    ]

  describe "destructure/2" do
    test "[head, _] = [1, 2]" do
      pattern = [var(:head), wildcard()]
      assert MatchA.destructure(pattern, [1, 2]) == {:match, %{head: 1}}
    end
  end

  describe "case/2 for lists" do
    test "[head, _] = [1, 2]" do
      pattern = [var(:head), wildcard()]
      consequence = & &1

      assert MatchA.case([{pattern, consequence}], [1, 2]) == %{head: 1}

      pattern = [var(:head), wildcard()]
      consequence = fn bindings -> Map.put(bindings, :head, bindings.head + 1) end
      assert MatchA.case([{pattern, consequence}], [1, 2]) == %{head: 2}

      assert_raise(MatchA.MatchError, "no matches!", fn ->
        MatchA.case([{pattern, consequence}], [1])
      end)
    end

    test "[head | rest] = [1, 2]" do
      pattern = [var(:head), rest(var(:rest))]

      assert MatchA.case([{pattern, & &1}], [1, 2]) == %{head: 1, rest: [2]}
      assert MatchA.case([{pattern, & &1}], [1]) == %{head: 1, rest: []}
    end

    test "[head | _] = [1, 2]" do
      pattern = [var(:head), rest(wildcard())]
      assert MatchA.case([{pattern, & &1}], [1, 2]) == %{head: 1}

      pattern = [var(:head), rest()]
      assert MatchA.case([{pattern, & &1}], [1, 2]) == %{head: 1}
    end

    test "[head, rest] = [1]" do
      pattern = [var(:head), var(:rest)]

      assert_raise(MatchA.MatchError, "no matches!", fn ->
        MatchA.case([{pattern, & &1}], [1])
      end)
    end

    test "[] = []" do
      pattern = [empty()]

      assert MatchA.case([{pattern, & &1}], []) == %{}

      assert_raise(MatchA.MatchError, "no matches!", fn ->
        MatchA.case([{pattern, & &1}], [1])
      end)
    end
  end
end
