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

We want to be able to change a fn call to the pattern match
and then change it back.

is it expanding a macro?

Basically I want to be able to replace a pattern match with a fn and vice versa
It would have to be the same fn / pattern match pair I guess

Really does this just amount to jumping to / from the call site?
Though that always takes me away from what I'm reading and loses context.

You turn it into edit mode - which is the fn call then you can turn it back
to pattern match - basically inline the fn

PipeLine.current_step()

%{}

def current_step_match_(pipeline) do
  # But yea can't return patterns from fns right.
  # But you can return AST.

  quote do
    %PipeLine{steps: {[current |_], _}} = pipeline
  end
end

### Aside - is PM declarative

Yes in the sense that how the data is accessed is hidden from you. But no in the sense that the data that you get is explicitly declared. so i guess it is really.


### Possible talk outline

Match made in heaven
The Pipeline problem (lol)
What even _is_ pattern matching?
  - bindings
  - control flow (is it though? or does that come from functions like case that just leverage PM? Maybe depends if you include raising errors as control flow which maybe it isn't.)
  - declarative, explicit, revealing
  - wait PM is not declarative because it isn't high level and it specifies explicit steps. But core.match is declarative - so it can be made to be...
  - Loop back to implement with in Pipeline - showing how it might help make clearer which
    step failed. Though stack traces are the big elephant in the room.

Elixir! PM! Look at me go!
Pipline. Rollbacks. Oh fuck. Maybe it's only good in the abstract?
Easy - just Funs for everyone?
Abstraction giveth and abstraction taketh away (why do we want pattern matching anyway?)
The problem: One to one from pattern to data type.
There are at least two ways to solve this
  1. Can patterns point to more than one concretion?
  <!-- Don't reveal this right away, hint at it and come back -->
  2. Can we think different - do refactoring tools help solve the same problem? sourceror spells
Dive into the library - list example. Implement array.
Demo how we hit the problem with the lib we were writing.
Get tricky with protocols for patterns.






The "I" thing
When I first started in Elixir PM was cool etc.
Then Pipeline. Steps... Boom.

This is a problem. We have to go into tradeoffs with our eyes open so we should talk about the tradeoffs with pattern matching.
By definition it reaches into the data structure's internals etc, but it's good.
So what is the solution? Can we get the benefits of both? Can pattern matching be good in the abstract - or is it destined to be good in the abstract (ie in theory) (maybe slide says theory I say abstract again to make the pun very clear.)

So if we step back and think about the problem we know what the solution is - it's what it always is - indirection. We need space for some implementation detail to change without it affecting an external interface. So for pattern matching what this really means is we need one pattern to be able to apply to many different data types.

Active Patterns do this.
Extractors sort of do this.
Can we do this in Elixir? (yes with our own skill)
have neither the skill or inclination to dive into the erlang pattern matching implementation to provide this but I have begun a naive go in elixir.

[tour of the lib?]

[hilarious anecdote about how we use pattern matching for pattern matching lib AND how the library we wrote was needed to solve the a problem we encountered while writing the library (structs to tuples.)]


We need to be sure on whether we are describing the library we wrote or a bigger thing.
Probably the latter.

The latter is like:
  - pattern matching is.
  - indirection - one pattern to many data types
  - patterns you can pass about - as first class data.
  - one immutable interface - if implementation details change we can swap them without
    propagating changes.
  - The best of both via dev tools - if we had automated refactoring then would this problem
    go away? inline the function to read the pattern - outline it for changes (so effectively all call sites are updated together). The tricky part is the same as the tricky part in having an abstract data type and defining a functional interface to it (ideally an unchanging one). Because you have to reason about how it'll be used - what patterns will be needed.


Another Aside

If you have patterns as data you can get a whole program as serializable data...presumably can be sent over the wire as etf - and we are in the world of defunctionalization probably.








Let's dig into what makes pattern matching easier to read -
  - less things to keep in your head
  - less distance - is there a good analogy here or prior art?
  - Koppel idea of whatever it was
  - nearness less far to carry the knowledge - to keep in your head. We use chunking and
    stuff. That's really what abstraction is - needing to carry less.
  - So can you get that without it?


Also - make it a story the thread in Duffel was about my story our story and something else...
Basically framing it in a way that draws in the people.








