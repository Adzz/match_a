defmodule MatchATest do
  use ExUnit.Case
  doctest MatchA
  import MatchA

  describe "list implementation" do
    test "[head, _] = [1, 2]" do
      pattern = pattern_cases([pattern_case([variable(:head), wildcard()])])
      assert MatchA.match(pattern, [1, 2]) == %{head: 1}

      # With continuation...
      pattern =
        pattern_cases([
          pattern_case([variable(:head), wildcard()], fn bindings ->
            Map.put(bindings, :head, bindings.head + 1)
          end)
        ])

      assert MatchA.match(pattern, [1, 2]) == %{head: 2}
    end

    test "[head | rest] = [1, 2]" do
      pattern =
        pattern_cases([
          pattern_case([variable(:head), rest(variable(:rest))])
        ])

      assert MatchA.match(pattern, [1, 2]) == %{head: 1, rest: [2]}
    end

    test "[head | _] = [1, 2]" do
      pattern =
        pattern_cases([
          pattern_case([variable(:head), rest(wildcard())])
        ])

      assert MatchA.match(pattern, [1, 2]) == %{head: 1}

      pattern =
        pattern_cases([
          pattern_case([variable(:head), rest()])
        ])

      assert MatchA.match(pattern, [1, 2]) == %{head: 1}
    end

    test "[head | rest] = [1]" do
      pattern =
        pattern_cases([
          pattern_case([variable(:head), rest()])
        ])

      assert MatchA.match(pattern, [1]) == %{head: 1}
    end

    test "..." do
    end
  end
end
