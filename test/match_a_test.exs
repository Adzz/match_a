defmodule MatchATest do
  use ExUnit.Case
  doctest MatchA
  import MatchA

  describe "list implementation" do
    test "[head _]" do
      pattern = pattern_cases([pattern_case([variable(:head), wildcard()])])
      assert MatchA.match(pattern, [1, 2]) == %{head: 1}
    end

    test "[head | rest]" do
      pattern =
        pattern_cases([
          pattern_case([variable(:head), rest(variable(:rest))])
        ])

      assert MatchA.match(pattern, [1, 2]) == %{head: 1, rest: [2]}
    end

    test "[head | _]" do
      pattern =
        pattern_cases([
          pattern_case([variable(:head), rest(wildcard())])
        ])

      assert MatchA.match(pattern, [1, 2]) == %{head: 1}
    end
  end
end
