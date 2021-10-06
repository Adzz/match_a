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

%{you_up?: true} = my_map

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

# So what can we do? Easy, re-implement pattern matching. Now I am not brave nor clever enough
# to attempt a re-write of erlang's pattern matching but I am foolhardy enough to attempt it in
# elixir.

# The simplest way is to introduce a protocol. This would allow each data type to implement a given
# pattern for themselves... so we could define some patterns like so:

  # [slide of pattern syntax]
  # [show the equiv]

defimpl Match, for: Zipper do
  def a(zipper, pattern) do
    ...
  end
end

defimpl Match, for: List do
  def a(zipper, pattern) do
    ...
  end
end

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












