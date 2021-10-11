add_two = fn x -> x + 2 end
times_three = fn x -> x * 3 end

PipeLine.new(1)
|> PipeLine.add_steps([
  add_two,
  times_three
])
|> PipeLine.execute()


PipeLine.new(1)
|> PipeLine.add_steps([
  add_two,
  times_three
])
|> PipeLine.with_trace()

{[current_step | _ ], [previous_step | _]} = pipeline.steps

def with_trace(%PipeLine{steps: steps, state: state}) do
  Enum.reduce(steps, state, fn step, acc ->
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = step.action.(acc)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    new_state
  end)
end

def with_trace(%PipeLine{steps: steps, state: state}) do
  Enum.reduce_while(steps, state, fn step, acc ->
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = step.action.(acc)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    case new_state do
      {:ok, _} -> {:cont, new_state}
      {:error, _} -> {:halt, new_state}
    end
  end)
end


%PipeLine{
  ...
  steps: [
    %PipeLine.Step{action: add_two},
    %PipeLine.Step{action: times_three}
  ]
}

%PipeLine{
  ...
  steps: [
    %PipeLine.Step{action: add_two, on_error: subtract_two},
    %PipeLine.Step{action: times_three, on_error: divide_by_three}
  ]
}

%Square{}
%Triangle{}
%Circle{}

defprotocol Shape do
  def area(shape)
  def perimeter(shape)
end

defmodule Square do
  defstruct [...]
end

defmodule Triangle do
  defstruct [...]
end

defimpl Shape, for: Trianlge do
  ...
end

defimpl Shape, for: Square do
  ...
end

defmodule Triangle do
  defstruct :area, :perimeter
end

defmodule Circle do
  defstruct :area, :perimeter
end

# A possible solution is:

%PipeLine{}
%PipeLine.Reversible{}

# That means our with_trace function isn't like broken, but it is now incomplete.
# so we are forced to choose between having to right a with_trace for every kind of
# pipeline. OR have to change the implementation to handle the internal details.


defmodule PipeLine do
  def next_step(...) do
    ...
  end

  def previous_step(...) do
    ...
  end
end

def with_trace(pipeline) do
  if PipeLine.complete?(pipeline) do
    pipeline.state
  else
    current = PipeLine.current_step(pipeline)
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = PipeLine.Step.execute(current)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    with_trace(PipeLine.update_state(pipeline, new_state))
  end
end

# Actually it should be this.

def with_trace(pipeline) do
  if PipeLine.complete?(pipeline) do
    pipeline.state
  else
    current = PipeLine.current_step(pipeline)
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = PipeLine.Step.execute(current)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    # We don't want to handle and trace the rollback, but we want to at least not break the
    # previous implementations.

    case new_state do
      {:error, _} ->
        pipeline
        |> PipeLine.update_state(new_state)
        |> PipeLine.previous_step()
        |> PipeLine.rollback()

      {:ok, state} ->
        pipeline
        |> PipeLine.update_state(new_state)
        |> PipeLine.next_step()
        |> with_trace()
    end
  end
end

def with_trace(pipeline) do
  if PipeLine.complete?(pipeline) do
    pipeline.state
  else
    current = PipeLine.current_step(pipeline)
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = PipeLine.Step.execute(current)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    case new_state do
      {:error, _} -> ...
      {:ok, _} ->
        pipeline
        |> PipeLine.update_state(new_state)
        |> PipeLine.next_step()
        |> with_trace()
    end
  end
end

# So really the motivating example has to match to make it somewhat convincing when
# we use reduce it just becomes about "implement enumerable" and distracts from it.
# but

# Should be this because then they are even closer

def with_trace(%PipeLine{steps: steps, state: state} = pipeline)
  when is_list(steps) do
  if [] == steps do
    state
  else
    [current_step | rest ] = steps

    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = current_step.action.(state)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    case new_state do
      {:error, _} -> new_state
      {:ok, state} -> with_trace(%{pipeline | state: state, steps: rest})
    end
  end
end

# With functions

def with_trace(pipeline) do
  if PipeLine.complete?(pipeline) do
    pipeline.state
  else
    current = PipeLine.current_step(pipeline)
    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = PipeLine.Step.execute(current)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    case new_state do
      {:error, _} ->
        pipeline.state

      {:ok, state} ->
        pipeline
        |> PipeLine.update_state(state)
        |> PipeLine.next_step()
        |> with_trace()
    end
  end
end

# Anything form Haskell? We can emulate Fib or some algo
# like the Real and Cart things (though a bit Maths-y)


# Essentially though you either have indirection or you don't.
# What things can be done to help jump over the code/

# Either you go to the mountain or you move the mountain here.
# The first way is to bring clarity to abstraction. The best way I could
# think of that is actually an editor integration or source code manipulation.
# When writing you want your change to propagate everywhere (write in one place)
# But when reading you might want to expand out the fn so you don't have to switch between files.
# So would be great if you could like inline the code and peek the implementation switch it on
# and off.

# Then there is the other way. Adding some indirection to PM. Again there are ways to do this -
# named patterns (expat) or have a go at implementing it for ourselves.
# Now we are running with one hand tied behind our back because we can't put the patterns
# anywhere and we have to return bindings. BUT even with that we can slim down the thing.

# What would the best of both worlds look like? Well. Either it would be


# Anything with gnarly ifs - that would be nested if statements with heaps of
# type checks or whatever. could do fizzbuzz


# with pattern matching

def with_trace(%PipeLine{steps: steps} = pipeline) do
  if MatchA.matches?([empty()], steps) do
    pipeline.state
  else
    bindings = [var(:current_step), rest(var(:rest))] <~> steps

    Logger.info("Executing Step...")
    start_time = System.monotonic_time(:millisecond)

    new_state = bindings.current_step.action.(state)

    milliseconds_taken = System.monotonic_time(:millisecond) - start_time
    Logger.info("Milliseconds taken = #{milliseconds_taken}")

    case new_state do
      {:error, _} -> new_state
      {:ok, state} -> with_trace(%{pipeline | state: state, steps: bindings.rest})
    end
  end
end


# We need to big up the PM !! We see it everywhere. Why? it needs to be convincing that
# we want to keep PM.

# Encapsulation...
# Take time on definitions - Define concretion eg (or give another name for it)
# mention encapsulation dwell on ADTs a bit.



# There are two ways fix this.
# 1. Bring indirection to pattern matching.... But then why not just use fns
     # (lots of ways to do that active patterns re-implement pm etc)
# 2. Bring declarative stuff to fns... Sourceror ?
  # like "peek" the implementation (inline temporarily?)

# Making functions more declarative?
# removing magic?

# we first need to know whats  good about pm. It's the clarity of what is actually happening.

# So we can ask the question, why do we abstract at all? What's that trying to get us?
# If it's ability to propagate changes to all callsites, that can be solved another way.
# there is re-use and discoverability...

# Basically we need to ask can the PM be more expressive than a function name.
# or a series of them...


# Could we be like there are two ways to solve it.
# 1. Add indirection to PM
# 2. Bring clarity to functions



# On a more convincing example...
# a more convincing case would be one where there isn't a data type to hide the
# pm in. Where a functional interface doesn't work That could be because
# either you dont have access to add it there, or because adding a functional
# interface would end up adding many more functions to achieve the same thing
# Or it could be because you aren't sure of the abstraction yet but you still
# need to get to the data.

# A more complex pattern match? Would be trickier to get the same thing (have)
# a whole host of fns to get the same effect.
# Especially

%{
  thing: %{z: z, b: %{c: [d, 2, 3]}}
} = test

d = test
|> Map.get(:thing)
|> Map.get(:b)
|> Map.get(:c)
|> Enum.at(1)

z = test
|> Map.get(:thing)
|> Map.get(:z)

Money...

# We deal with nested data at duffel all the time. is there an example there.






Mix.install([:expat])
defmodule PipeLine do
  use Expat

  defpat current_step({to_do, complete})
  defpat next_step({[current | _], _})
end

defmodule T do
  import PipeLine
  def t do
    PipeLine.next_step(to_do: t) = {[1], []}
  end
end

if PipeLine.current_step() = {[], []} do
  :ok
else
  :nope
end

if PipeLine.current_step() = [] do
  :ok
else
  :nope
end

PipeLine.next_step(to_do: t) = {[1], []}

# This at least means the library solves the problem we outlined.

# expat? Active patterns? Extractors?

# expat is named patterns but I don't think you can get
# multiple patterns to one function. You can name patterns though

# which is nice for clearing patterns up a bit and potentially hiding details
# but doesn't allow for two at the same time..... SO GUESS WE CAN TIE THAT POINT IN

# So we could use expat to create named patterns - which would allow the patterns to
# reside inside the PipeLine module - meaning if they change there they change for everyone
# (I think)

# But we can't have multiple concretions at once with expat.


# basically provide functions that figure out how to destructure
# the data type. and then use the bindings from that in the subsequent
# bit but i think they have the problem of needing to be exhaustive.
# and therefore not extensible...

# NAMED PATTERNS - named patterns help because they put the pattern in one place
# meaning inside the PipeLine module which is very great.

# BUT their weakness is it's tricky to have multiple concretions at one time
# and have one pattern handle both.

# To do that we need to re-implement pattern matching!
# MatchA

# Conclusion...

# PM and ADTs don't play nice - they are at odds
# Re-implement pattern matching to work on abstract data.
# Just kidding. Although that would be nice.

# Can we establish some rules of the match?
# the rule is use with algebraic with abandon.
# Don't use for abstract data.

# If you want to use on abstract data implement your own pm language a la clojure
# or use active patterns?
# shout out both papers if we can?

# Should we get active patterns? Will they be too much power and responsibility?

# zipper is algebraic really, there aren't two kinds of zippers - well you could have map
# zippers. Same as you could have lists implemented with maps that had different properties
# (like near constant access). The problem is because they are inside an abstract data type (pipeline)
# it becomes easy to say "just do it in the pipeline module and it'll work". But supporting all of
# the variations either involves having many cases (which isn't extensible) or

list = %{0 => 1, 1 => 2, 2 => 3}
[a | rest] = list
%{0 => n} = list


# Maybe we start with algebraic data types and demo why PM is so good for them
  # good quick example, maybe from the paper the pairs thing, or maybe nested extractions?
# Then be like Abstract data (pipelines, zippers)
# Then be like PM and abstraction are at odds, because one wants to hide the details and the other
  # needs to know them.

# Why would we want PM over functions? - structural picture worth a thousands words

# The ACTUAL talk outline:

# PM! Isn't it great!
# There is something in common all these examples that makes PM good: Algebra(ic data types)
# What is algebraic - sum / product. But for this talk think "maps".
# There is another kind of data type though....
# |> PipeLine - with trace - FEATURES - Zipper - 💥 BOOM.

# Then be like can we get the best of both? There are two ways that might work:
  # 1. Make the abstraction less indirect (more direct I guess) (but not actually)
    # (editor extension, inline the fn... etc... )
  # 2. Make the PM more indirect - have one pattern syntax work on many kinds of data types.
    # Two ways to do that. And in reality we can already get one of them now - because all structs
    # are maps, all valid map pattern matches are valid struct patterns, so one kind of match syntax is valid for
    # two data types. BUT this requires that the abstraction be expressed structurally
    # meaning by the keys that are used. so for example if the abstraction for shapes is area and perim, then
    # all our shapes should have those keys and voila (we have something that looks like objects) but our
    # match can abstract over specifics. BUT there are many abstract data types where that just isn't possible.
    # Take colour for example - RGB and CMYK, they share no keys though they can both refer to the same
    # colour. Structurally there's nothing to abstract over, though conceptually they are the same.

    # So the other way is to allow each data type to implement a given pattern for themselves. Protocols.
    # This adds indirection to the pattern match, so now we have to be sure that the PM is better
    # than just using a function. Which we can imagine examples where that holds true.... Hairy nested things
    #

    # Then be like pattern matching on abstract data
    # Then be like lol pattern matching to implement PM (aside on hitting the problem we are trying to solve)


# PM on streams! [example they mention in Active patterns paper is lazy list]
  # But the point is Streams are abstract (well sort of, in that you shouldn't reach into them
  # but you shouldn't like expect it to change really, though the keys may I suppose.)
  # We just said lists are abstract, but we PM on lists. We are pming on linked lists specifically
  # which we can assume will not change.
# but principle is the same. The pattern could even be lazy I suppose.

# They also use an example which is summing pairs of elements in a list.
# This with and without PM is illustrative. Better / simpler with PM

# The examples _for_ PM though are always interacting with algebraic data types
# which gives a nice kind of guidance on when to use PM with abstract data -
# (it would be fine to match on the struct name in all liklihood its public etc)
# but everything else is probably off limits. But inside, or when working with
# bare maps etc you can go ham.

[current_step | rest] = [1, 2]
[var(:current_step), rest(var(:rest))] = [1, 2]

bindings = Match.a([1, 2], [var(:current_step), rest(var(:rest))])

# could maybe say there are ways to clean this up with macro magic
# but this serves to illustrate the point.

# We can slim down the syntax a lot with macros. This is the ast for: [a | _]
# [ { :|, [], [{:a, [], Elixir}, {:_, [], Elixir}] } ]
vars = [var(:current_step), rest(var(:rest))] <~> [1, 2]

# you never want to PM across an abstraction boundary, but is there ever still
# benefit to having the PM over a fn... well yes if it drastically simplifies the fns
# turns it into a visual somehow structural look.

# There's something about PM making reading the code more structural in a sense
# which really I guess I mean less abstract. But like it's more visual in some
# sense than textual (like a function name might be.)

# Basically because it flattens that nesting which means you see a much clearer path
# for what the execution of the program will be.

# like take fizz buzz.
# Now I know this is a contrived example, but it is one you'll be familiar with
# and the implementation isn't wrong. What makes it difficult to read is the nesting
# because you can get to the end of one path, then you have to backtrack, which means
# recalling the whole past up to that point

# Gilded rose kata?
if Integer.mod(n, 15) == 0 do
  "Fizzbuzz"
else
  if Integer.mod(n, 5) == 0 do
    "buzz"
  else
    if Integer.mod(3, n) == 0 do
      "fizz"
    else
      n
    end
  end
end




%{current_step: 1, rest: [2]}











# PM is good and normal for Algebraic data types. What are they?
# Maps, lists, unions, tuples. essentially sums and products. They are like
# compound (made of other data structures) and they represent adding or multiplying
# those data structures together. In some weird way.
#
# Now PM does not work well for abstract data. Because abstraction introduces a barrier
# you don't want to cross (doing so exposes internals etc)
#
# So one solution is make the abstract data out of algebraic data. And we actually see
# that in elixir because Structs (the things we would use to represent abstract data like
# a shape) are implemented in terms of algebraic data: maps!
#
# So you can match all structs in the same way you can match a map - so it sounds like you
# would get one pattern to many data types. BUT you don't really because to get the kind
# of match we want - a semantic match - the abstraction has to be expressed in the keys
# of the Struct. Which forces you into a structural thing. (shapes need an area key...)
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#


#================================= BEGIN =========================================================

# When you first start in elixir you see this

at_elixir_conf = true

# And you think I know what that does! Then someone shows you this

%{speaker?: true} = user

# And you think wat.

  # [wat slide]

# That's backwards.
%{speaker?: true} = user

# Because it wasn't variable assignment it was pattern matching. And what a world,
# what a time to be alive! There are some great examples of pattern matching.

def fizz_then_buzz_off(n) when is_integer(n) do
  case {Integer.mod(n, 3), Integer.mod(n, 5)} do
    {0, 0} -> "Fizzbuzz"
    {0, _} -> "Fizz"
    {_, 0} -> "Buzz"
    {_, _} -> n
  end
end

def fizz_then_buzz_off(n) when is_integer(n) do
  mask = {Integer.mod(n, 3), Integer.mod(n, 5)}

  if mask == {0, 0} do
    "Fizzbuzz"
  else
    if elem(mask, 0) == 0 do
      "Fizz"
    else
      if elem(mask, 1) == 0 do
        "buzz"
      else
        n
      end
    end
  end
end

# Let's get an admin user's best friend's, best friend's name.

%{
  admin: true,
  friends: [%{friends: [ %{name: friends_friends_name} | _]} | _]
} = user

%{
  admin: true,
  friends: [%{friends: [ %{name: friends_friends_name} | _]} | _]
} <~> user

# What if the list of friends was a zipper? why would it be tho
# could become array?
# Map with integer keys.

friends = %{ 0 => friend_1, 1 => friend_2,  2 => friend_3}
friends = %MapList{ list: %{0 => friend_1, 1 => friend_2} }


# ... Or let's sum pairs of numbers in a list.
# [Probs drop this for time. Leave it add it if we run out.]

def sum_pairs(list), do: :lists.reverse(sum_pairs(list, []))

def sum_pairs([], acc), do: acc
def sum_pairs([a], acc), do: [a | acc]
def sum_pairs([a, b], acc), do: [a + b | acc]
def sum_pairs([a, b | rest], acc), do: sum_pairs(rest,  [a + b | acc])

# Or from elixir itself.

def reduce(_list, {:halt, acc}, _fun), do: {:halted, acc}
def reduce(list, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(list, &1, fun)}
def reduce([], {:cont, acc}, _fun), do: {:done, acc}
def reduce([head | tail], {:cont, acc}, fun), do: reduce(tail, fun.(head, acc), fun)

# Now it's not important that you read and understand these examples right now
# but let's compare what it would look like without pattern matching.

def reduce(list, acc, fun) do
  tuple_tag = elem(acc, 0)

  if tag == :halt do
    {:halted, acc}
  else
    if tuple_tag == :suspended do
       {:suspended, acc, &reduce(list, &1, fun)}
    else
      if tuple_tag == :cont && length(list) == 0 do
        {:done, acc}
      else
        reduce(tail, fun.(head, acc), fun)
      end
    end
  end
end

# Again don't worry about the actual content but look at the shape, the nesting is a
# good hint that this'll be tricky to understand, debug etc etc

# So pattern matching is good. But there is something in all these examples that is
# making it good. And the answer is

  # [ALGEBRA]

# I know boo hiss. Well really it's

  # [ALGEBRAIC DATA TYPES]

# What are they? Algebraic data types are data types that are made from sum and/or product types.
# Sum type - These have become more popular recently but imagine you say that the valid values
# for a colour are red green or blue:

"red" | "green" | "blue"

# The set of all possible valid values for that type can be created by ADDING each possibility.

"red" + "green" + "blue"

# so there are 3 possible valid values for this type - the three strings you see above.
# So sums are when there are an OR and or is like analogous to + adding.

# Product type - Now imagine the following map where each key can be a number between 0 and 255
# inclusive:

%{red: 0..255, greeen: 0..255, blue: 0..255}

# To work out all of the possible valid maps that the type allows you have to MULTIPLY all of the
# available options:

%{red: 0, greeen: 0, blue: 0}
%{red: 1, greeen: 0, blue: 0}
%{red: 2, greeen: 0, blue: 0}
...
%{red: 255, greeen: 0, blue: 0}
...

# So to get the total number of valid values for the type you must get the product - the cartesian
# product - of all of the possible values.

# For the purposes of this talk when I say algebraic data type you can just think "map" or "list"


# What we've seen so far is that pattern matching and algebraic data types work very well together.
# They are a good (pattern) _match_ ... pun definitely intended.

# But there is another kind of data type. To understand that let's look at the Pipe.

#  [|>]

# If you do elixir long enough you gets to thinking that the pipe is cool but you know what's better
# smart pipes! So you take it upon yourself to "improve" them
#
# I'm no exception so I wrote a pipeline library...

# [The PipeLine slides (fixed) up to the boom]

# The problem is the PipeLine as presented here is an ADT - an abstract data type. The tell is
# there are multiple possible implementations or concretions for it. Either at once or over time.

# The tension is as follows. Pattern Matching wants the details, but the abstraction is trying to
# hide them.

# So we have some options right. The first is just like never use Pattern matching.
# Guess perfectly each time when you are using an abstract data type and never use it for then.
# I don't find this to be compelling, and I don't know if the language is going to help you in
# that goal of not using pattern matching.


# The more interesting question for me is... Can we get the best of both?
# So first we have to define what that is. There are two ways to bring these opposing ideas together:
# Abstraction adds indirection, so either

# Either the abstract data types have to get less indirect (more direct) or the pattern matching
# has to get more indirect.

# [Less abstract abstract data...]

# I can only think of one reasonable way to approach this - programmer tools. It's reasonable
# to think that we might want different things when reading code and when editing it. So like
# imagine if we had functions instead of pattern matching, but the function was just this:

  # [function showing simple pattern match]

# That lives in the abstract data type (pipeline) so if we change it we only have to change it in
# one place. But now imagine if at the callsite I could hit a hotkey and inline the function.

# Now I maybe get the best of both - for write it's still update in one place. But for read I
# don't have to jump through like 5 files to get to what I want.

# But the more interesting approach to me is: is there value in making PM more abstract. The
# essence of this is can one pattern be valid for multiple data types.

# Again there are at least two ways to think about this. The first we can actually already do in
# elixir. All structs are maps. That means any valid map pattern is a valid struct pattern. So
# in that sense you can have pattern that abstract over many data types BUT it has this interesting
# consequence that the abstraction has to be expressed structurally - which is to say in terms
# of the keys in those structs.

# So concretely if we have shapes and we say the abstract thing that all shapes have is an area
# fn. Well for this:

def area(%{area: area_fn} = shape) do
  area_fn.(shape)
end

# to work on all shapes all shapes need an area key. And when we can only express the abstraction
# structurally it ends up being quite limiting.

# Take another example: colors. We can have RGB and CMYK as valid colour representations,
# but there is no overlap in the keys used to represent each that we can leverage.

%RGB{red: 100, green: 100, blue: 255}
%CMYK{cyan: 10, magenta: 10, yellow: 20, key: 50}

# Which means there isn't a map pattern match we can make that abstracts over these two different
# colour representations.

# Imagine trying to write this functions:

def is_red(%{...}) do
  ...
end

# There are no keys to abstract over.

def is_red(%{__struct__: colour_type} = colour) do
  colour_type.is_red?(colour)
end

# So what can we do? Easy, re-implement pattern matching. Now I am not brave nor clever enough
# to attempt a re-write of erlang's pattern matching but I am foolhardy enough to attempt it in
# elixir.

# The simplest way is to introduce a protocol. This would allow each data type to implement a given
# pattern for themselves... so we could define some patterns like so:

[current_step | rest] = [1, 2]
[var(:current_step), rest(var(:rest))] = [1, 2]

vars =
  [var(:current_step), rest(var(:rest))] <~> [1, 2]


# This is the actuall function BUT FOR THE SLIDE we do
# [it a bit different and skip the destructure function to keep it simpler]

def pattern <~> data do
  case MatchA.destructure(pattern, data) do
    {:match, bindings} -> bindings
    {:no_match, _} -> raise MatchA.MatchError, "no match!"
  end
end

# [ this is what's used on the slide:]

def pattern <~> data do
  case Match.a(data, pattern) do
    {:match, bindings} -> bindings
    {:no_match, _} -> raise MatchA.MatchError, "no match!"
  end
end

defprotocol Match do
  def a(data, pattern)
end

defimpl Match, for: List do
  def a(list, pattern) do
    ...
  end
end

# so remember our pattern syntax:

[var(:thing)] = [1]

# Well var(:thing) right now returns this:

{:var, :thing}

# So with that in mind we could implement the simplest pattern match case
# like so:
defimpl Match, for: List do
  def a([item] = _list, [{:var, name}]) do
    %{ name => a}
  end
end

# Now show the pipeline Zipper getting wrapped in a struct:

%PipeLine{
  ...
  steps: {[step_1, step_2], []}
}

# To this:

%PipeLine{
  ...
  steps: %Zipper{zip: {[step_1, step_2], []}}
}

# Now we can imagine implementing the same for the zipper!
defimpl Match, for: Zipper do
  def a(zipper, pattern) do
    ...
  end
end

# Something like this.
defimpl Match, for: Zipper do
  def a(%{zip: {[item], []}}, [{:var, name}]) do
    %{name => item}
  end

  def a(%{zip: {[], [item]}}, [{:var, name}]) do
    %{name => item}
  end
end

# NOW THOUGH.
# We've implemented pattern matching with pattern matching.
# 👌

# But we've inadvertently run into the exact problem the library
# has been written to solve. To demonstrate that let's imagine
# we try to extend this whole idea to allow user defined patterns.

# To do that the first thing we need to do is make MOAR PROTOCOLS
# we are going to treat each pattern as its own protocol that can be implemented
# by each data type for itself.... So when we call

Match.a(data, pattern)

# What we actually do is something like this

# In fact should we first dispatch on the pattern THEN on the data?
def a(pattern, data) do
  Pattern.for(data, pattern)
end

# This is a pattern that utilizes other patterns. That means
# that any pattern can be used inside any other one. So we need to dispatch


list(var(:current))

defprotocol ListPattern do
  def match(nested_pattern, data, pattern_index)
end


var(:current_step)
# returns
{:var, :current_step}

var(:current_step)
# returns
%Var{name: :current_step}


list([var(:thing)]) =>
  %ListPattern{patterns: [var(:thing)]} =>
    %ListPattern{patterns: [%Var{name: :thing}]}


PipeLine.pattern(%{steps: [var(:current), rest()] }) = PipeLine.add_steps(PipeLine.new(1), [& &1])



# =============== Extensible Patterns leggoooooo ===========================

# 1. Make the patterns Structs.

[var(:current_step), rest(var(:rest))]
# becomes
list([var(:current_step), rest(var(:rest))])
# which is:
%ListPattern{
  patterns: [
    %Var{name: :current_step},
    %Rest{binding: %Var{name: :rest}}
  ]
}

pattern = %ListPattern{patterns: [%Var{name: :current_step} ]}

# 2. Change the protocol.

defprotocol Match do
  def a(pattern, data)
end

# 3. Implement it for a ListPattern:

defimpl Match, for: ListPattern do
  def a(%ListPattern{patterns: patterns}, data) do
    Enum.reduce_while(patterns, {0, %{}}, fn pattern, {index, bindings} ->
      case ListPattern.match(pattern, data, bindings, index) do
        {:match, bound} -> {:cont, {index + 1, bound}}
        :no_match -> {:halt, {:no_match, bindings}}
      end
    end)
  end
end

# Add the ListPattern protocol. But wait. We want to use the same name 😱
defprotocol ListPattern do
  def match(nested_pattern, data, bindings, pattern_index)
end

# Well never mind. We can just do this.
defprotocol ListPattern do
  defstruct [:patterns]
  def match(nested_pattern, data, bindings, pattern_index)
end

# This means we _know_ we are a variable in a list. Now we can implement it for
# any future pattern - meaning any list can have a pattern in it.
defimpl ListPattern, for: Var do
  def match(%Var{name: var_name}, data, index) do
    # At this point we know for certainty that we are a variable in a list pattern
    # so now we need to figure out what data type we are matching.... we do that by
    # CALLING ANOTHER PROTOCOL. The reason is because the sub pattern in the list
    # in our case the variable needs different information depending on WHERE is is
    # If it was in variable_in_a_map then we'd need to know that the key the pattern was
    # under exists.
    case VariableInAList.match(data, index) do
      {:ok, value} -> {:match, value}
      :no_match -> :no_match
    end
  end
end

defimpl ListPattern, for: Var do
  def match(%Var{name: var_name}, data, binding, index) do
    case VariableInAList.match(data, index) do
      {:ok, value} -> {:match, value}
      :no_match -> :no_match
    end
  end
end


# We need to breakdown why we do this. the variable isn't really a variable, it's a
# variable in a list pattern. Now this could be different from a variable_in_a_map
# pattern for example, where the key is the context, not the index.... (though they are both keys really meh)
defprotocol VariableInAList do
  def match(data, index)
end

# Now finally we know all the things. We know we are a variable pattern that appeared
# in a list, that is matching against a list.
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

defprotocol RestInAList do
  def match(list, bindings, index)
end

defimpl ListPattern, for: Rest do
  # Right do we know the data is a list? Not yet no.
  def match(%{rest: %Var{var_name}, data, bindings_so_far, index) do
    # Ergh vom. Rest is actually higher order too. So it calls
    # VariableInRestInMap
    # or VariableInRestInList which no. we need to recur somewhere or something.

    # we want extensible
    RestInAList.match(data, bindings_so_far, index)
  end
end

defimpl RestInAList, for: List do
  def match(list, bindings, index) do
    # we are on index means to get rest we drop everything before then
    amount_to_drop = length(list) - index - 2
    rest = Enum.drop(list, amount_to_drop)

  end
end

# I think effectively what we've done is make a graph where each of the lines between the nodes is a protocol
# MEANING at each point you can add more arrows to other implementations. Show this if we can.

# MAtch a pattern
   # |
# List Pattern
#    |
#  Variable
   # |
# Access data and see if



# ...stuff

# So we started out writing a library that was trying to bring some indirection to
# pattern matching. The idea was doing that would make us resilient to changes in
# the data-structures being pattern matched against.... We implemented that using
# pattern matching. Then changed the implementation of the data we were pattern matching
# against - and ran smack bang into the middle of the problem we were attempting to solve!

# Which is amusing.


# But let's recap. Right now we've sketched out _a_ way to bring some indirection to pattern
# matching. This has served as an illustration of what doing that might bring us. So
# what has it brought us?

# Originally we said what we liked about PM was:
# 1. A picture is worth 1,000 functions (what does this mean? same as 2? less surface area?)
# 2. Construction and destruction are the same (syntax)
# 3. You understand what's _actually_ happening. (peek past the abstraction)**

# Well in our implementation the syntax is not the same, so 2 isn't really try anymore
# We also don't know what's _really_ happening because the match is abstract now.

# So we are left with 1.

    # Now it's possible we can bring back 2. with some macro magic
    # [we could wave hands here or we can try for user defined patterns which would]
    # [allow pipeline pattern] I guess built in types are hand wave-y macro magic but
    # for custom ones you'd want to create your own syntax.

# But I think if we want to ask the question 'can PM be good in the abstract' we have
# to ask the question - is there value in abstract pictures? In pictures of the gist
# of what is happening?

# This is a question that I can't answer for you, but I'd love to hear your thoughts.

# End on Jose post because it's funny.

# **for me at least getting an example that you can then think about generalising is
# simpler than trying to go the other way - thinking about the abstraction first

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

# Might not need this protocol as we can just use normal polymorphism
# as we don't need it to be extensible.
# defprotocol Pattern do
#   def evaluate(pattern, data)
# end

# defimpl Pattern, for: Last do
#   def evaluate(%struct{}, pattern) do
#     struct.match(pattern)
#   end
# end

# named patterns are just really grouping patterns together
# to make smaller ones, and also to provide one place to update patterns
# if the implementation of them changes. That's the value they provide.

defimpl Match, for: List do
  def a([item] = list, [%{__struct__: pattern}]) do
    # Pattern has to determine how to find the value? Or determine like whether it
    # binds a var or not?
    pattern.match(list)
    %{ name => }
  end
end


# patterns that incorporate other patterns need to know about them in order to
# be able to do stuff with them. This would require that each pattern implement
# a ListXXX protocol, where the XXX is the pattern. So for example
# ListPipeLine pattern would be the "this is a PipeLine in a List patern". When there
# we woule be able to figure out what to do. We'd need the corresponding element from
# the point we are at in the list.

# The problem then comes for things like "rest" which could apply to many higher order
# patterns... There we want to get a different thing from

# maybe it works if we pass through the pattern and the current bindings. We sacrafice
# a lot of ease of understanding to get re-use etc.
# But that way the pattern can decide what to do.
# Do we also need context of like "where we are"

# Or can we just take on the chin that implementations of pattterns that use
# other patterns will require enumerating all the patterns it wants to be able to handle
# It is not after all an unreasonable stipulation - but it does mean you can't really
# implement list pattern for everyone as you'll likely miss a pattern they need.

# I do feel like there is a way though.




# And also how do we know the

# imagine a list of pipeline patterns.
# Can we define a "PipeLine" pattern so that we can get head and next or whatever.
# The idea would be that brings the pattern and creation syntaxes into closer alignment
#

# pipeline pattern idea. So the things that you want from the pipeline are
# current step, next step and previous step (if available). lets do the first two for now

%{current_step: current} =
  current_step(var(:current)) <~> PipeLine.add_steps(PipeLine.new(1), [step_1])

bindings = %PipeLine{
  current_step: current
} <~> PipeLine.add_steps(PipeLine.new(1), [step_1])

# Like the above could be alright but it's not really a picture. we have just gotten back
# to a name


# Oh wait this really means the pattern can be __ANYTHING__ shit. Also what's a good picture
# for current step?
bindings = [var(:current) | _] <~> PipeLine.add_steps(PipeLine.new(1), [step_1])

[_, var(:nest_step)] <~> PipeLine.add_steps(...)

[_previous, var(:current), _next] <~> PipeLine.add_steps


defimpl Match, for PipeLine do
  def a(%{steps: {[current | _], _}}, [{:var, name} | _]) do
    %{name => current}
  end

  def a(%{steps: [current | _]}, [{:var, name} | _]) do
    %{name => current}
  end
end

# current really means first

#

# the idea with the above is that the acutal pipeline can be reversible or not.



current_step(wildcard())

Pattern.evaluate(%Last{}, [1,2])








# Protocol does mean one version though per data type. So we could imagine the last on a map
# as ordering the k/v pairs by key and then selecting the last one, or by ordering by value
# with this approach you'd have to pick one and that would be it. You'd have to define more
# patterns like LastByKey or something. Which by that point you may as well define an ADT
# and have a functional interface to it. I guess the litmus test of a pattern is can it
# apply to more than one concrete data type. If so then good if not it's suspicious.
Pattern.evaluate(%Last{}, %{a: 1, b: 2})

# <!-- We should use Rest as the example?  -->

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
  # if we bind to a wildcard we ignore anyway...
  def match(map, %Rest{binding: %Wildcard{}, context: %{taken_keys: taken}}) do
    Map.drop(map, taken)
  end
end


# so for a map
Rest.match(%{a: 1, b: 2}, map([a: var(:a), rest(var(:rest))])
%{a: 1, rest: %{b: 2} }

# but here's the real problem those patterns that aggregate other patterns need to know
# about all of the patterns they aggregate because otherwise they wont know what else to
# pass to the pattern to let it do its thing.

# So now we need to get to

# The idea is this says how to treat rest when it's inside a list.

# All the stuff you _could_ need is the original data being matched, the
# bindings so far and "where" we are in the list.
defimpl InsideListPattern, for: Rest do
  def for(rest_pattern, data) do
    # This means Rest was the 2nd pattern in the list of patterns and no bindings where
    # made yet - implying the first pattern was wildcard or similar
    Rest.match(list, %{ rest_pattern | bindings_so_far: %{}, list_index: 1})
  end
end

InsideListPattern.for(%Rest{}, [1,2,3])


# The outer pattern - Zip
# the inner pattern - Types of element
# The data being matched - Operation

defimpl MapPatern, for: Map do
  def match(map, %MapPatern{keys: keys}) do
    # keys is a list of bindings
    Enum.reduce(keys, %{}, fn
      {key, %pattern{}}, bindings ->

      # we have to know what pattern it is to know what context to pass through.
      # because we are here we _know_ we are a map matching.

      # we need to be like RestMap
      %pattern{}, bindings ->
        pattern.match(map, _taken_keys = Map.keys(bindings))
    end)
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
    # passing this in second allows us to add free vars to the mix and use them in the fn
    # essentially that's why you might want to add this protocol - then each pattern
    # can add its own context etc to the pattern.
    struct.match(data, pattern)
  end
end



# This would basically return %{a: [1,2]} from a destructure
Pattern.evaluate(list([rest(variable(:a))]), [1,2])



# Then we can implement it for our zipper too.

# Now there is a tradeoff here. In introducing indirection, well we've introduced indirection.
# Do we risk losing the very thing we like about PM - its clarity?

# I'd argue no because there is another property of pattern matching that still holds. For me it
# turns words into pictures. It turns what would be reading function names into something more
# structural, pictorial even.

# There is even prior art for this. In clojure there is core.match which allows pattern matching on
# abstractions - like sequences. There is a great explanation of the algo used to make it work too

  # [show the repo and link to the wiki and title the paper used]

# As well Fsharp uses something called active patterns - again there is a good paper showing how
# it was added to f sharp. Scala also has extractors.

# Conclusion.

# So what can we take from this? For me it's a summary and a question.

  # [Rules of the Match]

# Inside the abstraction match with abandon.
# outside on unstructured, algebraic data go ham.
# On types - ie struct names - for control flow. Also cool. :tick:

# Is there a place for semantic, extensible pattern matching in elixir?

# Cheers. Adz. Twitter. Roll Credits.












