defmodule MatchATest do
  use ExUnit.Case
  doctest MatchA

  import MatchA,
    only: [
      case_clauses: 1,
      case_clause: 2,
      variable: 1,
      rest: 1,
      rest: 0,
      empty: 0,
      wildcard: 0
    ]

  # If we make it a case fn then we'd have to implement case for every data type which
  # no one wants. They need to be higher order - case takes a list of patterns and
  # matching_functions (fns to do on match) that all use the matching (which is essentially)
  # the control flow part. How is it different from destructuring?

  describe "case/2 for lists" do
    test "[head, _] = [1, 2]" do
      pattern =
        case_clauses([
          case_clause([variable(:head), wildcard()], & &1)
        ])

      assert MatchA.case(pattern, [1, 2]) == %{head: 1}

      # With continuation...
      pattern =
        case_clauses([
          case_clause([variable(:head), wildcard()], fn bindings ->
            Map.put(bindings, :head, bindings.head + 1)
          end)
        ])

      assert MatchA.case(pattern, [1, 2]) == %{head: 2}

      assert_raise(MatchA.MatchError, "no matches!", fn ->
        MatchA.case(pattern, [1])
      end)
    end

    test "[head | rest] = [1, 2]" do
      pattern =
        case_clauses([
          case_clause([variable(:head), rest(variable(:rest))], & &1)
        ])

      assert MatchA.case(pattern, [1, 2]) == %{head: 1, rest: [2]}
      assert MatchA.case(pattern, [1]) == %{head: 1, rest: []}
    end

    test "[head | _] = [1, 2]" do
      pattern =
        case_clauses([
          case_clause([variable(:head), rest(wildcard())], & &1)
        ])

      assert MatchA.case(pattern, [1, 2]) == %{head: 1}

      pattern =
        case_clauses([
          case_clause([variable(:head), rest()], & &1)
        ])

      assert MatchA.case(pattern, [1, 2]) == %{head: 1}
    end

    test "[head, rest] = [1]" do
      pattern =
        case_clauses([
          case_clause([variable(:head), variable(:rest)], & &1)
        ])

      assert_raise(MatchA.MatchError, "no matches!", fn ->
        MatchA.case(pattern, [1])
      end)
    end

    test "[] = []" do
      pattern =
        case_clauses([
          case_clause([empty()], & &1)
        ])

      assert MatchA.case(pattern, []) == %{}

      assert_raise(MatchA.MatchError, "no matches!", fn ->
        MatchA.case(pattern, [1])
      end)
    end
  end
end
