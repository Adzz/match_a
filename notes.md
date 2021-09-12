```elixir


pattern([
By default continuation is ID
  case conflicts with kernel though.... so perhaps pattern case?
  bit long though
  case_clause([var(:head), wildcard()]),
  case_clause([empty()], & &1 + 1),
  case_clause([wildcard(), rest(wildcard())], & &1 + 1),
  case_clause([wildcard(), rest(var(:tail)) ], & &1 + 1),
])
```
  Aside:
  Really pattern is "case statement:, Because the idea of continuation isn't inherent
  to PM but part of the case idea. That means we could have other kinds of things
  like a simple "assign" that takes one pattern and returns bindings for it - or raises
  in the case of a match error.
  Then you could do with etc etc.
  assign(bindings()), data
  really I guess the data being match sits in the assign then..,

We should think about whether the original struct implementation gives
use anything with regard to protocols. At a guess we might get some kind of
multiple dispatch behaviour but what does that extensibility buy?
Multiple representations of the pattern syntax?
Dispatching on the data being matched makes more sense because then you can
validate the syntax for that data type.

You could essentially be like "implement this pattern syntax for a list" and you'd
know for sure it was a list because of the previous protocol. It might mean that you'd
need to implement that matching protocol for a list for _all_ patterns. But that might
give you an easy way to be like "invalid match syntax" because if it's not implemented
then

Do we get extensible patterns (yes) using protocols. Because we'd be able to define our
own pattern structs and implement the protocol for them.

You would need a lot of protocols though. Like one for every data type / pattern.
(this is the whole solving the expression problem post) Say you define a %Last{} pattern
and you wanted to implement it for a list then you'd have to. Mad that we found a use
for it.
Also when it's all structs it's kind of serializable I guess.

Having them as structs also forces there to be an immutable external interface - the
struct name I guess.
```elixir

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

Pattern.evaluate(%Last{}, [1,2])

# Protocol does mean one version though per data type. So we could imagine the last on a map
# as ordering the k/v pairs by key and then selecting the last one, or by ordering by value
# with this approach you'd have to pick one and that would be it. You'd have to define more
# patterns like LastByKey or something. Which by that point you may as well define an ADT
# and have a functional interface to it. I guess the litmus test of a pattern is can it
# apply to more than one concrete data type. If so then good if not it's suspicious.
Pattern.evaluate(%Last{}, %{a: 1, b: 2})
```
