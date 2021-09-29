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
    # this gets the value out but we need to bind it to a variable really.
    List.last(list)
  end
end

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

<!-- We should use Rest as the example  -->

# in the list impl, something like:
rest = %{ %Rest{} | context: %{index: index} }

case Pattern.match(rest, list) do
  :no_match -> {:halt, :no_match}
  value -> {:cont, {index + 1, Map.put(bindings, var_name, value)}}
end

# in the map something like:

rest = %{ %Rest{} | context: %{taken_keys: keys} }

case Pattern.match(rest, map) do
  :no_match -> {:halt, :no_match}
  value -> {:cont, {index + 1, Map.put(bindings, var_name, value)}}
end

defprotocol Rest do
  # this allows data to be passed through to the implementation
  # for example the index where "rest" begins, or in a map the
  # keys already selected I guess.
  defstruct [:binding, :context]
  @fallback_to_any true
  def match(data, context)
end

defimpl Rest, for: List do
  def match(list, %Rest{context: %{index: index}}) do
    out_of_bounds = make_ref()

    case Enum.at(list, index, out_of_bounds) do
      ^out_of_bounds -> :no_match
      value -> value
    end
  end
end

defimpl Rest, for: Map do
  # assumes taken keys have already not blown up - ie we match so far.
  def match(map, %Rest{binding: %Wildcard{}, context: %{taken_keys: taken}}) do
    Map.drop(map, taken)
  end
end

defimpl Rest, for: Any do
  def match(data, _) do
    raise "Invalid match syntax - Rest not implemented for #{inspect(data)}"
  end
end

defprotocol Pattern do
  def evaluate(pattern, data)
end

defimpl Pattern, for: Rest do
  def evaluate(%struct{} = pattern, data) do
    <!-- passing this in second allows us to add free vars to the mix and use them in the fn ? -->
    struct.match(data, pattern)
  end
end

<!-- This would basically return %{a: [1,2]} from a destructure -->
Pattern.evaluate(list([rest(variable(:a))]), [1,2])


```

Let's think about the match syntax. We want to have one bit of syntax map to many

```elixir
def variable(name), do: {:variable, name}
# rest is only for ordered collections really. You could have it for maps but how would that work.
# like JS destructuring I suppose. The spread operator.
def rest(binding \\ wildcard()), do: {:rest, binding}
def empty(), do: :empty
def wildcard(), do: :wildcard
def list(items), do: {:list, items}
# could / should we add map syntax - lets us get a subset of a thing?

def map(bindings), do: {:map, bindings}
# pattern matching here is fine because rest is implemented above so if we change it we'll know to
# change here too quite quickly.
# aside does it make sense to call this map, or subset? the list matching is more like a match on
# order of elements tbh. though for the talk name might be fine. Using something like subset might
# allow more flexibility to specify a subset of things that aren't implemented via a map or where
# there is an abstraction barrier that we shouldn't cross... For example MapSet.
# maybe it's not subset, maybe it's just elements or something. Though they sort of mean the same
# thing. But how do we use a map to specify elements in a map set? as mapsets dont have keys
# use a list? make it keyword if there are keys.
def map(bindings, {:rest, bindings}), do: {:map, bindings, bindings}

map(%{my_key: variable(:a)})
map(%{my_key: variable(:a)}, rest(variable(:rest)))



map([my_key: variable(:a), variable(:b)])
subset(%{key: wildcard()})
<!-- subset is not ordered but a list is by that's just a means to get values in. Really it would -->
<!-- be a mapset there, but then using mapsets to pattern match mapsets... which okay. -->
<!-- could be fine I guess. Interesting whether we can unlock the key pattern match for example. -->
patern = subset(%{a: :b})
pattern = subset([1, 2, rest])

```

right so variable works the same for everything - you access some value determined by the context of the pattern it is in and add it to the bindings.

rest is only relevant for collections and different collections need to implement it differently. So really it can only appear in certain matches and doesn't make sense on its own
really. So rest on a string might not make sense - unless rest on a thing is all of it.

empty again only makes sense for collections (including strings/binaries) probably and is implemented differently for
those collections.

wildcard is universal but contextual a bit - in that sometimes it's a valid match and sometimes not. Like:
_ = 1 is valid but [a, _] = [1] is not.

having a map or subset or elements kind of thing would be cool to enable pattern matching on MapSets, the same
way we do on maps. Maybe for maps the subset is a k / v pair which is why a keyword list could be useful

The Q we are trying to answer is do we need the double dispatch faff? No probably not to be honest.
variable is implemented the same sort of - where you get the var from does matter for different



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
Pipline. Rollbacks. Oh fuck. Maybe... it's only... good in the abstract??
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

This is cool because it enables extension of pattern matching - essentially you can define
more powerful PM for your own data types that doesn't just rely on

<!-- We want to be able to pattern match the list ?
Or do we want to be able to pattern match next?  -->

<!--
  for it to be equivalent though it's not the PM that failed - it still got steps it
  was the iteration. The value changed, not the key.

  For our pipeline not to fail we have to implement enumerable for the PipeLine. That's it.
  (no because then you wouldn't be able to reverse etc. but it would solve some cases) that
  you can then build reverse etc off of.

  What PM problem does Matcha solve? Means we can PM on more than one kind of thing but the problem
  statement about PipeLine doesn't really help. It would land more if the PM version accessed the
  next step via PM - but we dont we used reduce_while.

  Also "next_item" is that general enough to reify into a pattern? Do we want open and extensible
  patterns? I guess it is in a sense.

  Is there a more convincing use case that leverages a PM that we can't really hide behind an
  abstraction? The array thing springs to mind.
 -->

prior art in other langs
  - clojure allows matching on sequence abstrations
  - F sharp has active patterns which allow a similar idea in some ways
  - Scala has extractors which are also dancing around the same idea
  - Are protocols enough? Should we just use functions?

Pattern.match(list([variable(:head), rest()]), %PipeLine{})


Conclusion:
  implement your own PM language.
  Just kidding.

 PM for (type based) control flow - this struct do this, otherwise do that.
 If you access data are you crossing an abstraction barrier?
 Use it with abandon _inside_ your abstractions.
 When writing libraries offer those function interfaces, try and make it as clear
 as possible what is fair game.

But all this got me thinking. (End on a question kind of deal?)
Are we thinking about this all wrong. Is this a source code problem?
Imagine this editor, you see the function and it inlines the fn so you can see the pattern match
this is quick and not permanent.

Is that a better way?




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






Let's dig into what makes pattern matching easier to read -
  - less things to keep in your head
  - less distance - is there a good analogy here or prior art?
  - Koppel idea of whatever it was
  - nearness less far to carry the knowledge - to keep in your head. We use chunking and
    stuff. That's really what abstraction is - needing to carry less.
  - So can you get that without it?


Also - make it a story the thread in Duffel was about my story our story and something else...
Basically framing it in a way that draws in the people.


All Pipes Lead to Smart pipes - AKA I wrote a pipeline lib.
... And got bitten. (reversible list - zipper)

Explicitly state the problem.
Active Patterns, extractors, Views - Papers written before Haskell had me reading Miranda!
In short... confusion. So let's back up. The problem is... Pattern Matching exposes the internals,
but in doing that... well we expose the internals; we rely on them meaning if they change BOOM!
So if pattern matching only good in an abstract sense? Or can it be good in Abstract data?

What is abstract data? - Multiple implementations at once - or over time.
  Multiple implementations at once: Shapes! Area! Permimeter! Reversible Pipeline vs PipeLine. (explosion? but backwards compatible)
  Multiple implementations over time: Pipeline - list / zipper.

Two simple solutions - 1. Just don't care
 - pm is usually explicit coupling meaning you should know when it fails. So it may represent
   work to go and fix all the pattern matches, but this may not be that much work and it's at least better than it failing silently.

So this is easy then... Just don't use pattern matching.
  - Expose functions, define public interface.
  - means composable, reusable functions.
  - means being insulated from changes.

But there are downsides...

  You have to define that interface and it's usually a breaking change to remove or edit a function in it.

  In elixir you can't force access to only be via the functions - so there isn't the encapsulation that you might expect. In reality this is usually fine but still you cannot
  say "the only way to access this data is via this fn". IE you can't stop the match.

  You have to jump around files when reading. There this sense where you can understand
  what's happening in the code well with well named functions, but you struggle to really
  understand _what's happening_. We can think about two levels of code here: What the code
  _means_ - like what's happening in the domain. And what is actually happening to enable
  the thing you want the domain to do. So there is the concept of "finished the pipeline"
  and there is the way we actually _know_ how to do that (eg check for empty list).

  Adding a function introduces the chance of calling that function incorrectly. You need docs
  and type checking and unit tests to eliminate a problem that wouldn't exist if everything was inlined - ie if there was not function.

  PM is very natural in elixir. So what are we saying? We should never use it? Seems... bad.

Can we get the best of both? Can we pattern match abstract data?

I am neither brave nor clever enough to change erlang's pattern matching implementation but I am
foolhardy enough to try it in elixir. To get what we want the problem boils down to one pattern
refering to one data type:

[a, b] = [1, 2]

The above only works on lists, not on all collection types, nor even all ordered collections (like erlang arrays)
So let's write our own pattern match library that allows us this flexibility...

DEMO:
  - basic two pattern match - explain can be made recursive and all the rest but keep example v. simple.
  - list([variable(:a), variable(:b)]) == [a, b]
  - MatchA.destructure(list([variable(:a), variable(:b)]), [1, 2]) == [a, b] = [1, 2]

  - Now peek the implementation - We use a protocol to get the indirection we desire. Means we can
    now implement the above for both list and erlang array - or our own datatype! Yay.
  - There are obviously lots of patterns though.. so we use pattern matching to implement pattern matching.
    which lol.
  - Except now we have hit the very problem that the library we are writing is trying to solve.
  -


There are two ways to get one pattern to match many different data types. One is to implement one match for each data type differently. The other is to implement each data type with the same kind of underlying data type.

So for example in elixir Structs are all maps. That means pattern matching syntax for maps applies to any struct. So we get one to many. Both have their place, but one downside of implementing lots of datatypes in terms of one is it can lead to strange looking data in order to get sensible looking pattern matches. To the point where you wouldn't do that.

Like imagine a MapSet that allows PM - well MapSet is a struct and therefore a map, so we _can_ pm on it.... but to get what we actually want (like pattern match on the elements in the MapSet) we'd have to expose the things we want to match on in the keys present in the MapSet.

So instead we can go the other way and try to implement one pattern differently for each data type it might be relevant to.



primitives in the PM lang? like variable and wildcard. Empty and rest should be implemented differently
We can use the struct technique to add free variables into the mix and therefore add more values where
needed.



What are ADTs
Abstractions - many concretions. Either at once or over time.
Because you have many concretions the abstraction handles that usually by exposing fns
So we could do that. But now we aren't pattern matching.

So why are pattern matching?

There's this sense where piling on abstractions can (at its best) give you a clear understanding of
what you program is doing in the problem domain - it can tell you what's happening at that level of
abstraction.

But there is a clear need to know sometimes what is actually happening. 2am when the pager is going
mental (also, remember pagers?!).

Both have their places and both

Sometimes we have the clear design pressure to know "we'll have many shapes let's think about that"
But other times you might not think "we need reversible pipelines" until much later.

so the solution can't be "just think of everything up front" (solution to what we havent outlined the problem yet)

Abstract then means we can hide implementation details. But this is by definition at odds with
what pattern matching does.





  # We could implement the case statement as a Pipeline - have a match trigger a rollback.
  # which is essentially a with. HANG ON! That could be a cool feature to double back to
  # the pipeline library at the end and implement `with` there (can even talk about how it
  # helps solve the problem with `with`s (that the step that fails is hard to relate to the
  # things that caused it to fail)). There is something very tricky here around when we generalised
  # the rollback mechanism. Like if each step in a pipeline is a pattern match then we can implement
  # an executor that attempts a match and if it doesn't match continues if it does it stops. Or
  # vice versa...

