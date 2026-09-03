---
layout: page
title: Replace Mutable Fields with Lenses
subtitle: "Replace mutable fields with lenses: package a field's reader and pure writer as one value, and the read becomes get, the write becomes set or modify — inline the lens, and a field that is never composed just becomes a field again"
permalink: /refactorings/replace-mutable-fields-with-lenses/
tags: [refactorings, replace-mutable-fields-with-lenses]
hide: true   # entry pages are reached from the catalogue, not the top-right nav
---

<p class="rf-crumb"><a href="{{ '/refactorings/' | relative_url }}">← The refactoring catalogue</a> · 2 of 35</p>

A mutable field is a place where the class's invariants can be broken:
any method can read it, any method can write it, and nothing stops a
write from putting the object into a state the other methods did not
anticipate. Object-oriented refactoring has a ladder of moves up this
smell — Fowler's *Encapsulate Variable* (the catalogue entry that used
to be *Encapsulate Field*, and before that *Self-Encapsulate Field*)
hides the field behind accessor methods [[1](#ref-1)], [[2](#ref-2)], and *Remove Setting
Method* then removes the setter once the field no longer needs to be
written from outside the class [[3](#ref-3)]. The field is still a field; it is
just visited through a corridor.

The functional reading goes one step further: a field of an immutable
record is not a location, it is a projection, and a projection that can
also be written is a *lens* — a value packaging `get :: s -> a` and
`set :: a -> s -> s` [[4](#ref-4)]. Replacing a mutable field with a lens means
making the record immutable and routing every read through `get` and
every write through `set` (or `modify`, which reads, applies a pure
function and writes in one step). The single field's lens *composes*
with the lenses of enclosing records, so a deep update that once
touched five records by hand becomes one composed path. And because
`set` is a pure function, the writes cannot run off and mutate
something the rest of the program is looking at; the state transition
is a value again. The three lens laws — `get (set v s) = v`,
`set (get s) s = s`, `set v₂ (set v₁ s) = set v₂ s` — are exactly
the equations under which the move is a refactoring, and they are
stateable as property tests [[4](#ref-4)], [[5](#ref-5)].

The inverse direction is just as useful. A lens that is never composed,
never updated through a path, and never read by more than one caller is
abstraction tax: the reader and writer are already next to each other,
and a `get`/`set` pair or a plain field says the same thing with less
machinery. Inlining the lens — replacing `lens.get(s)`, `lens.set(v)(s)`
and `lens.modify(f)(s)` with direct field access — is the move that
removes indirection that no longer earns its name. Foster, Greenwald,
Moore, Pierce and Schmitt's notion of a *well-behaved lens* is the
property-theoretic core both directions are checked against: the two
functions are a lens exactly when the GetPut and PutGet laws (the first
two above, in the form they state) hold [[4](#ref-4)].

## Motivation

Reach for the lens when the same field is read and written in many
places and the writes compose. The smell is repetition of field
handling: an object-with-accessors whose setters are one-liners that
nothing intercepts, a copy-update chain that grows a level for every
record you descend, or an update that must be re-derived by hand each
time a field moves. An OO class can hold its invariants in accessor
methods, but the corridor is per-type and per-field; a lens is a value,
so it can be passed around, stored, and composed into paths that reach
several levels down without ever repeating the intermediate records.
When the invariant itself matters — a balance that must never go
negative, a size that must bracket its children — the pure writer makes
the transition a value the type system and the tests can see, and a
*bad* write is a failed check rather than a corrupted object.

Reach for the inverse when the lens is speculative generality. The
smell that drives Inline is the mirror image: a field whose updates are
all one level deep, a lens composed nowhere, a get/set pair whose writer
is `const`-like and whose reader is the identity. The abstraction costs
a reader a detour — what is *set v₂ (set v₁ s)* doing when the program
only ever calls `set` once? — and it costs the compiler nothing it can
deduce. When all the code does with the field is read it once, or write
it once, a plain field or a pair of functions is clearer. The two moves
are one equation read in two directions; which direction you choose
records a judgement about whether the field is part of a *path* or a
*leaf*.

## The move

Both catalogue pages are short. *Encapsulate Variable*: create a
function that reads the field, create one that writes it, replace every
read with a call to the reader and every write with a call to the
writer, and test [[2](#ref-2)]. The precondition is that the readers and writers
are the only way in and out — nothing may reach the field directly — and
the payoff is that the class owns its representation. *Remove Setting
Method*: once the field can be initialised and never needs to be
reassigned, delete the setter and initialise at construction [[3](#ref-3)]. Read
the two together and they are the OO route to what the lens packages:
reads through a named getter, writes through a named setter, and no
bare `field = ...` anywhere. Herbert's dissertation on Scala
refactoring points at the same target from the tooling side: a
refactoring that turns a mutable field into a pure accessor pair has to
move the *writes*, and that is the whole analysis [[11](#ref-11)].

In the functional reading the move is mechanical. Make the record
immutable. Define `get` as the record's field accessor and `set` as a
function returning a copy with the field replaced; package them as a
lens value. Replace reads with `get`, writes with `set`, read-modify-
write with `modify`. Where a field sits inside other records, compose
the lenses along the path. The OO precondition — no direct access — is
replaced by a type: the only way to reach the field is through the
lens, and the type checker enforces it. The trickier part is what the
OO ladder leaves implicit. `set` must leave every other field alone, so
a lens is not just any `(get, set)` pair; it is one that satisfies the
three laws, and those laws are precisely what a property test can check
[[4](#ref-4)].

## The functional reading

In a referentially transparent language a record field is a *focus*: a
value that indexes into a structure. A lens is a focus with a reader
and a writer, and the two directions share one equation. `get` selects
the focus; `set` replaces it; `modify f` is `set` after `get` after
`f`. Nested records compose: the composite focus `outer . inner`
selects `inner` inside `outer`, so a deep update becomes one path
instead of a copy chain. What makes this a *refactoring* rather than a
rewrite is that the three lens laws are equations between programs —
`get (set v s) = v`, `set (get s) s = s`, `set v₂ (set v₁ s) =
set v₂ s` — and they are exactly the conditions under which replacing
field access with `get`/`set` preserves behaviour [[4](#ref-4)], [[5](#ref-5)].

Foster, Greenwald, Moore, Pierce and Schmitt defined *well-behaved
lenses* and proved a large catalog of combinators (composition, map,
and recursion among them) that compose them while preserving those
laws; their GetPut and PutGet are the first two equations above, and
PutPut (the third) distinguishes the very well-behaved class [[4](#ref-4)].
O'Connor showed that lenses are exactly the coalgebras for the costate
comonad — the categorical shape of "a structure with a distinguished
hole" — which is why `get`/`set` pairs and the functor-based encodings
coincide [[6](#ref-6)]. Gibbons and Johnson give the equational proof of
that correspondence [[7](#ref-7)]. Van Laarhoven's representation made the
encoding practical: a lens as a polymorphic function
`(a -> f a) -> (s -> f s)` for all *functor* `f`, which composes with
ordinary function composition and is what Kmett's *lens* library and
Pickering, Gibbons and Wu's *profunctor optics* generalise [[8](#ref-8)], [[9](#ref-9)], [[10](#ref-10)].
On the OO side the same idea appears as a many-to-one refactoring
in Stocker's later Scala tooling [[11](#ref-11)].

Concretely, the reader never needs most of that. A lens is a `get` and
a `set`, and a `modify` defined from them; if the field is nested, the
lenses compose. The laws are the contract, and the contract is checked,
not hoped.

## To and from

<figure class="rf-figure">
{% include_relative replace-mutable-fields-with-lenses/diagrams/koan.svg %}
<figcaption>The koan. One equation, read in two directions: replace
(package the reader and pure writer of a field as a lens value) to the
right, inline (drop the lens, access the field directly) to the left.
The three lens laws — <em>get</em> (<em>set v s</em>) = <em>v</em>,
<em>set</em> (<em>get s</em>) <em>s</em> = <em>s</em>, and
<em>set v&#8322;</em> (<em>set v&#8321; s</em>) = <em>set v&#8322; s</em> —
are the equation the move is checked against.</figcaption>
</figure>

The catalogue lists each refactoring in both directions because the two
moves are one equation read left to right and right to left. Replace a
field with a lens: define `get` and `set` for the field, replace every
read with `get`, every write with `set` or `modify`, and where the
field is nested compose the lenses. Inline a lens: replace `get`, `set`
and `modify` at their use sites with direct access, and delete the
lens. The lens laws say both directions are behaviour-preserving:
`get (set v s) = v` is the forward equation, `set (get s) s = s` the
backward one, and `set v₂ (set v₁ s) = set v₂ s` says writing twice is
writing the last value once [[4](#ref-4)].

The directions serve different ends. Replace is for containment, so the
writes to a field are reachable only through a pure function and any
invariant the writer holds is visible at the one place it is held; for
composition, because a lens along a path reaches nested records without
repeating them; and for reuse, because a lens is a value that can be
passed to a function that reads and writes through it. Inline is for
simplicity, because a field that is never composed or updated is
clearer as a field; and for removing a seam, because a lens whose
callers couple to its mechanics rather than its meaning adds a hop, not
a guarantee. Both directions are checked by the same property: for all
generated inputs, the before-program and the after-program agree on the
entry point.

## Three examples

Each example is the same program twice, `Before` and `After`, in Scala 3
and in Haskell. The entry point keeps its name and its type, the lens is
the only difference, and a hedgehog property generates inputs and demands
that both versions agree on every one of them. The sources below are
included verbatim from the files the tests run against.

### 1 · Account balance: the field becomes a lens

A single mutable field — the balance — is read and written by
`withdraw`. The Before version spells the update out with a copy; the
After version packages the field's `get` and pure `set` as one
`Lens[Account, Int]` and routes the update through `modify`. The second
property checks the three lens laws, which are the equation that makes
the move a refactoring.

<figure class="rf-figure">
{% include_relative replace-mutable-fields-with-lenses/01-account-balance/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/01-account-balance/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/01-account-balance/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/01-account-balance/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/01-account-balance/After.hs %}{% endhighlight %}
</div>
</div>

Note what did *not* change: `withdraw` still returns a new account, the
bonus field is untouched, and `modify` is a function of the lens we
could pass elsewhere. The property compares result *values* — both
sides return their own record type, so the test reads `.balance` and
`.bonus` off each result.

<details class="rf-spec">
<summary>The property: <code>Before.withdraw == After.withdraw</code> on generated accounts, and the three lens laws</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/01-account-balance/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/01-account-balance/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

### 2 · Game and player: the composed path

The player sits inside a game, and moving it means a copy-update chain
that touches both records at every call. The After version composes
`player . x` and `player . y` into paths and moves through them; the
nested write is one step, not two. This is the composition property
that made lenses famous: `compose` on lenses is exactly function
composition read backwards, and the second property re-checks the lens
laws for the composed path.

<figure class="rf-figure">
{% include_relative replace-mutable-fields-with-lenses/02-player-position/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/02-player-position/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/02-player-position/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/02-player-position/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/02-player-position/After.hs %}{% endhighlight %}
</div>
</div>

Two notes. `compose` is a few lines because the whole encoding is a few
lines — `Lens` is just a `get` and a `set`, and `modify` is defined
from them; a library like Kmett's or Monocle supplies the same
combinators with more machinery behind them [[8](#ref-8)], [[11](#ref-11)]. And the
property again compares result values, so it reads `.level`, `.player.x`
and `.player.y` off each result rather than asserting record equality
across two types.

<details class="rf-spec">
<summary>The property: <code>Before.moveX/moveY == After.moveX/moveY</code> on generated games, and the composed lens obeys the laws</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/02-player-position/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/02-player-position/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

### 3 · File tree: the lens inside the recursion

The tree's `size` field is updated in the same recursive pass that
walks the children. The Before version writes it directly in the
`copy`; the After version routes the write through a lens and leaves
the recursion alone. This is the inverse picture from example 2: here
the lens is *not* composed — there is one record type and one field —
and the reason to use it is that the write is a named, checked step of
the traversal rather than an anonymous copy. The second property checks
the lens laws on generated nodes.

<figure class="rf-figure">
{% include_relative replace-mutable-fields-with-lenses/03-file-tree/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/03-file-tree/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/03-file-tree/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/03-file-tree/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/03-file-tree/After.hs %}{% endhighlight %}
</div>
</div>

A design choice is worth stating: example 3 uses one *total* lens whose
focus is a single field, not a lens over "all files in the tree". Every
node has a `size`, so the lens is total, the property can test it on any
node, and the recursion is unchanged. "All the files" is a traversal,
not a lens — a different abstraction with its own laws — and the page
stays within the lens equation.

<details class="rf-spec">
<summary>The property: <code>Before.bumpSizes == After.bumpSizes</code> on generated trees, and the size lens obeys the laws</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/03-file-tree/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/03-file-tree/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

## Pitfalls

The equation has hypotheses, and each is one of the constructive
criteria. Where a hypothesis fails, replacing a field with a lens
changes the program. In a language with referential transparency the OO
precondition does not become easier to satisfy; it disappears, and the
move becomes an equation. The structures that make that true are
gathered in the footnote at the end of this section.

- **Partial lenses.** A lens whose `get` is not defined on part of the
  source type — reading a field out of a sum type where one branch does
  not carry it — must `error`/`sys.error` on that region, and the laws
  can only be checked where the lens is defined. Totality is exactly
  the condition that makes a lens a lens everywhere; prefer a record
  shape where every value has the field, or use a prism/traversal for
  the partial case.
- **Laziness and evaluation count.** A lens's `set` is lazy in the new
  value in Haskell — `set l (f s) s'` does not force `f s` unless the
  result needs it — and `modify f = set l . f . get l` can force `f`
  earlier than a direct field write would. Where the program is lazy
  about an untouched field (a bonus never read, an id never shown),
  `undefined` in that field is a probe: before and after must both
  tolerate it. In Scala a `def` recomputes and a `val` shares; a lens
  stored as a `val` builds its functions once.
- **Strictness.** A `modify` reads the focus, applies a function and
  writes it back; if the focus is bottom, the read is forced and the
  result differs from a direct write that never looked. Totality, no
  `undefined` and no partial functions, is exactly the condition under
  which this cannot arise. Example 1 probes it with `undefined` in the
  untouched field.
- **Composition direction.** `compose outer inner` focuses `inner`
  *inside* `outer`; the reader writes `inner` after `outer`, and
  getting the order backwards is a type error, not a runtime bug. Two
  lenses with the same source do not compose at all — there is no
  single focus — which is what stops the "compose a pair" mistake from
  even compiling.
- **The laws as a contract.** A `(get, set)` pair is a lens only when
  the three laws hold; a pair that violates PutPut is a lens in name
  only. Any consumer of a lens — including the ones in examples 2 and 3
  — relies on them, so the property that checks them is not decoration.

In each case the fix is the same: restore the hypothesis, by keeping
the lens total, by using a `val` where sharing matters, and by testing
the laws; or admit that this is not a refactoring and test it as a
change.

<details class="rf-spec">
<summary>The functional reading</summary>
<div markdown="1">

A lens is a focus with a reader and a writer. In a referentially
transparent language a record `s` with field `a` gives a lens whose
`get` is the field accessor and whose `set` is the copy-update; the two
are one value because the field is a projection, not a location. Nested
records compose because a projection of a projection is a projection:
`compose outer inner` selects `inner` inside `outer`, and the
read-modify-write `modify` is `set` after `get` after `f`.

This is not a new idea dressed up. Foster, Greenwald, Moore, Pierce and
Schmitt introduced the *very well-behaved lens* laws (GetPut, PutGet,
PutPut) and proved that their combinators — composition, map, recursion
— preserve them, which made it possible to assemble large bidirectional
transformations from small, verified lenses [[4](#ref-4)]. O'Connor showed
lenses are the coalgebras for the costate comonad, the categorical
shape of "a structure with one hole", and conjectured the equivalence
of the store and functor encodings [[6](#ref-6)]; Gibbons and Johnson proved
the correspondence [[7](#ref-7)]. Van Laarhoven's representation, a lens as a
polymorphic function `(a -> f a) -> (s -> f s)` for every functor `f`,
is what the *lens* library builds on [[8](#ref-8)], [[9](#ref-9)]; Pickering, Gibbons and
Wu's *profunctor optics* shows the same idea scales to prisms and
traversals by generalising the arrow [[10](#ref-10)]. Monocle gives Scala the
same library treatment [[12](#ref-12)].

That is the point. With referential transparency the OO precondition —
no direct writes — does not become easier to satisfy; it disappears,
because the writer is a pure function and the type checker enforces the
corridor. Replacing a field with a lens stops being something you hope
preserved behaviour and becomes an equation you wrote down.

</div>
</details>

## Verification

Because the move is an equation, its correctness is a property: for all
inputs *x* in the domain of the entry point, `Before x == After x`. That
is a one-line property in the sense Claessen and Hughes introduced with
QuickCheck, where a generator produces inputs and the framework searches
for a counterexample and shrinks it to a minimal one [[13](#ref-13)]. The catalogue
states every entry this way, in Scala and in Haskell, with hedgehog on
both sides [[14](#ref-14)]. Hedgehog is used because its shrinking is integrated
into the generator, so a shrunk counterexample obeys the same invariants
as a generated one and the minimal failing input it reports is a real
input of the program, not an artefact of a separate shrinker. The lens
laws are second properties — the equation the move is checked against,
stated directly.

A property is only worth having if it can fail, so each spec above was
mutation-checked: change `After` so it is no longer equivalent — flip a
sign, swap a boundary, drop a case — confirm the property reports and
shrinks a counterexample, then restore `After`. A property that does
not fail under mutation is testing the generator, not the refactoring.
The lens examples are especially well protected: the laws are stated
for the *lens itself*, so a setter that drops the other fields fails
the laws before it ever reaches the equality property.

To run everything on this page yourself, from a checkout of
[the site repository](https://github.com/Constructive-Programming/website):

```sh
sh pages/refactorings/replace-mutable-fields-with-lenses/run.sh
```

It needs [scala-cli](https://scala-cli.virtuslab.org/) and either GHC
with hedgehog installed or Docker, and ends with `all properties passed`.

## References

<ol>
<li id="ref-1">Martin Fowler. <em>Refactoring: Improving the Design of Existing Code</em>. Addison-Wesley, 1999. Chapter on self-encapsulation and the <em>Encapsulate Field</em> catalogue entry. <a href="https://martinfowler.com/books/refactoring.html">https://martinfowler.com/books/refactoring.html</a></li>
<li id="ref-2">Martin Fowler. <em>Encapsulate Variable</em> (formerly <em>Encapsulate Field</em>). Refactoring.com, online edition. <a href="https://refactoring.com/catalog/encapsulateField.html">https://refactoring.com/catalog/encapsulateField.html</a></li>
<li id="ref-3">Martin Fowler. <em>Remove Setting Method</em>. Refactoring.com, online edition. <a href="https://refactoring.com/catalog/removeSettingMethod.html">https://refactoring.com/catalog/removeSettingMethod.html</a></li>
<li id="ref-4">J. Nathan Foster, Michael B. Greenwald, Jonathan T. Moore, Benjamin C. Pierce and Alan Schmitt. &ldquo;Combinators for Bidirectional Tree Transformations: A Linguistic Approach to the View-Update Problem&rdquo;. <em>ACM Transactions on Programming Languages and Systems</em> 29(3):17, 2007 (also POPL 2005). <a href="https://doi.org/10.1145/1232420.1232424">https://doi.org/10.1145/1232420.1232424</a></li>
<li id="ref-5">Edward Kmett and contributors. <em>lens: Lenses, Folds and Traversals</em>. The library documentation states the three lens laws (get-put, put-get, put-put) that a lens must satisfy. <a href="https://hackage.haskell.org/package/lens">https://hackage.haskell.org/package/lens</a></li>
<li id="ref-6">Russell O&rsquo;Connor. &ldquo;Functor is to Lens as Applicative is to Biplate: Introducing Multiplate&rdquo;. In <em>Proceedings of the ACM SIGPLAN Workshop on Generic Programming (WGP 2011)</em>, pp. 25&ndash;36. <a href="https://arxiv.org/abs/1103.2841">https://arxiv.org/abs/1103.2841</a> (also the costate-comonad characterisation, arXiv version)</li>
<li id="ref-7">Jeremy Gibbons and Michael Johnson. &ldquo;Relating Algebraic and Coalgebraic Descriptions of Lenses&rdquo;. <em>Electronic Communications of the EASST</em> 49:1&ndash;16, 2012 (Workshop on Bidirectional Transformations 2012). <a href="https://doi.org/10.14279/tuj.eceasst.49.726">https://doi.org/10.14279/tuj.eceasst.49.726</a></li>
<li id="ref-8">Twan van Laarhoven. &ldquo;Talk on Lenses&rdquo;. Slides, Radboud University Nijmegen, 17 May 2011. Introduced the functor-based (van Laarhoven) representation. <a href="https://www.twanvl.nl/blog/news/2011-05-19-lenses-talk">https://www.twanvl.nl/blog/news/2011-05-19-lenses-talk</a></li>
<li id="ref-9">Edward Kmett. <em>Control.Lens</em>. Hackage package documentation for the <em>lens</em> library. <a href="https://hackage.haskell.org/package/lens/docs/Control-Lens.html">https://hackage.haskell.org/package/lens/docs/Control-Lens.html</a></li>
<li id="ref-10">Matthew Pickering, Jeremy Gibbons and Nicolas Wu. &ldquo;Profunctor Optics: Modular Data Accessors&rdquo;. <em>The Art, Science, and Engineering of Programming</em> 1(2):7, 2017. <a href="https://doi.org/10.22152/programming-journal.org/2017/1/7">https://doi.org/10.22152/programming-journal.org/2017/1/7</a></li>
<li id="ref-11">Mirko Stocker. <em>Scala Refactoring</em>. Master&rsquo;s thesis, HSR Hochschule f&uuml;r Technik Rapperswil, 2010. Catalogues pure-function accessor refactorings including field encapsulation. <a href="https://eprints.ost.ch/id/eprint/286/">https://eprints.ost.ch/id/eprint/286/</a></li>
<li id="ref-12">Julien Truffaut and contributors. <em>Monocle: Optics Library for Scala</em>. <a href="https://www.optics.dev/Monocle/">https://www.optics.dev/Monocle/</a></li>
<li id="ref-13">Koen Claessen and John Hughes. &ldquo;QuickCheck: a lightweight tool for random testing of Haskell programs&rdquo;. In <em>Proceedings of the ACM SIGPLAN International Conference on Functional Programming (ICFP 2000)</em>, pp. 268&ndash;279. <a href="https://doi.org/10.1145/351240.351266">https://doi.org/10.1145/351240.351266</a></li>
<li id="ref-14">Jacob Stanley and contributors. <em>Hedgehog: release with confidence, state-of-the-art property testing</em>. <a href="https://github.com/hedgehogqa/haskell-hedgehog">https://github.com/hedgehogqa/haskell-hedgehog</a> and <a href="https://github.com/hedgehogqa/scala-hedgehog">https://github.com/hedgehogqa/scala-hedgehog</a></li>
</ol>
