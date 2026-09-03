---
layout: page
title: Replace Mutable Fields with Lenses
subtitle: "Replace mutable fields with lenses: package how to reach a field and what to do with it as one optic value — read becomes get, write becomes set or modify; inline the lens, and a projection no one composes becomes a field again"
permalink: /refactorings/replace-mutable-fields-with-lenses/
tags: [refactorings, replace-mutable-fields-with-lenses]
hide: true   # entry pages are reached from the catalogue, not the top-right nav
---

<p class="rf-crumb"><a href="{{ '/refactorings/' | relative_url }}">← The refactoring catalogue</a> · 2 of 35</p>

A mutable field is a place where a class's invariants can be broken:
any method can read it, any method can write it, and nothing stops a
write from putting the object into a state the other methods did not
anticipate. The object-oriented ladder up this smell is well worn —
Fowler's *Encapsulate Variable* (the catalogue entry that used to be
*Encapsulate Field*, and before that *Self-Encapsulate Field*) hides
the field behind accessor methods [[1](#ref-1)], [[2](#ref-2)], and *Remove Setting
Method* then deletes the setter once the field no longer needs to be
written from outside the class [[3](#ref-3)]. The field is still a field; it is
just reached through a corridor.

The functional reading starts at the same smell and goes further out.
A field of an immutable record is a *projection* — a way to reach
into a value — and the useful thing about the world of optics is that
these projections *compose*. A lens reaches one field of a record, a
prism one branch of a sum, a traversal every element of a container,
and the projection you need for a job is built by chaining smaller
ones: `prism .andThen lens`, `each .andThen prism .andThen lens`.
That separation is the whole point — it splits *how do I get to field
A* from *what should I do once I have it* — so the same tiny optic is
reused on one node, on every node of a tree, and against a branch of
a sum inside a list, without being rewritten. Replacing a mutable
field with a lens means making the record immutable and routing every
read through `get` and every write through `set` (or `modify`, which
reads, applies a pure function and writes in one step). The state
transition is a value again, and the optic combinators are lawful by
construction — the contract that makes a rewrite a refactoring is
built in, not hoped for — so correctness comes for free; the
libraries ship law-solvers that confirm any optic you write by hand
[[4](#ref-4)], [[11](#ref-11)].

The inverse direction is justified when the decoupling does not earn
its keep: a lens that is never composed, a projection whose separation
of *how* from *what* no one exploits, or — the strongest smell — a
codebase with no cross-domain boundaries, where the whole record
travels everywhere and only the target of the projection would ever
need to pass across a seam. Inlining the lens — replacing `get`,
`set` and `modify` at their use sites with direct field access —
removes indirection that no longer names anything. The catalogue
presents the two directions as one equation, readable both ways;
which way you go records a judgement about whether the field is part
of a *path* or a *leaf*. The [eo cookbook](https://eo.constructive.dev/cookbook)
is a worked, tested reference for the optics side of this: three jobs
optics do best — navigate structures, decouple modules, thread
effects — each recipe runnable against the library.

## Motivation

Reach for the lens when access to a field needs to be *decoupled from
its manipulation*. The smell is repetition of field handling: an
object-with-accessors whose setters are one-liners nothing intercepts,
a copy-update chain that grows a level for every record you descend,
or an update that must be re-derived by hand each time a field moves.
The optics version of the corridor is a *value*, so it can be passed
around, stored, and composed into paths that reach several levels
down without ever repeating the intermediate records; and a function
that needs "every `Instant` in whatever you hand me" can ask for the
optic instead of the type. When the invariant itself matters — a
balance that must never go negative, a size that must bracket its
children — the pure writer makes the transition a value the type
system and the tests can see, and a *bad* write is a failed check
rather than a corrupted object.

Reach for the inverse when the lens is speculative generality, or when
there is nothing for the decoupling to mediate. The smell that drives
Inline is the mirror image: a field whose updates are all one level
deep, a lens composed nowhere, a get/set pair whose writer is
`const`-like and whose reader is the identity — and no cross-domain
boundaries in sight, so the full structure may pass through every seam
and nothing is ever isolated to the target of the projection. The
abstraction costs a reader a detour — what is `set v₂ (set v₁ s)`
doing when the program only ever calls `set` once? — and it costs the
compiler nothing it can deduce. When all the code does with the field
is read it once, or write it once, a plain field or a pair of
functions is clearer.

## The move

Fowler's mechanics are short. *Encapsulate Variable*: create a
function that reads the field, create one that writes it, replace
every read with a call to the reader and every write with a call to
the writer, and test [[2](#ref-2)]; the precondition is that nothing reaches the
field directly. *Remove Setting Method*: once the field can be
initialised and never needs to be reassigned, delete the setter and
initialise at construction [[3](#ref-3)]. Read together they are the OO route to
what the lens packages: reads through a named getter, writes through a
named setter, and no bare `field = ...` anywhere. Stocker's Scala
refactoring catalogue has the same move — turning a mutable field into
a pure accessor pair moves the *writes*, and that is the whole
analysis [[10](#ref-10)].

In the functional reading the move is mechanical. Make the record
immutable. Define `get` as the field accessor and `set` as a function
returning a copy with the field replaced; package them as a lens
value. Replace reads with `get`, writes with `set`, read-modify-write
with `modify`. Where a field sits inside other records, compose the
lenses along the path; where it sits under a branch of a sum, compose
a prism first; where the field is one of many, compose a traversal.
The OO precondition — no direct access — is replaced by a type: the
only way to reach the field is through the optic, and the type
checker enforces it. In practice the optic for a field or branch is
often *auto-derivable* from the type — a library macro or generator
(`eo`'s `lens`/`prism`, Monocle's optics, `lens`'s Template Haskell)
writes the "how to reach" for you, and you keep the "what to do"
[[7](#ref-7)], [[11](#ref-11)].

## The functional reading

An optic is a value that knows how to reach a *focus* inside a source
and how to rebuild the source around a new focus. The families differ
in how many foci they address: a lens reaches exactly one field of a
product, a prism one branch of a sum, a traversal every element of a
container. They share one shape — see, modify, rebuild — which is what
makes them *compose*: `prism .andThen lens` says "that branch, then
that field", and `each .andThen prism .andThen lens` says "every
element, that branch, that field". The rewrite itself is a pure
function on the focus: how you get there is a value, what you do there
is a function, and the two are independent. This is the optics view of
the same ladder Fowler climbs — the corridor of accessor methods
becomes a composable value, and the precondition becomes a type.

The theoretical backbone is the same one that made lenses lawful,
not just convenient. Foster, Greenwald, Moore, Pierce and Schmitt
defined the well-behaved lens families and proved their combinators —
composition, map, recursion — preserve the laws, which is where
"lawful by construction" comes from [[4](#ref-4)]. O'Connor, and then Gibbons
and Johnson, gave the categorical reading — lenses are the coalgebras
for the store comonad — which is why the different encodings coincide
[[5](#ref-5)], [[6](#ref-6)]. Van Laarhoven's representation made the encoding
practical as a functor-polymorphic function, which is what Kmett's
*lens* library builds on [[7](#ref-7)], [[8](#ref-8)]; Pickering, Gibbons and Wu's
*profunctor optics* shows the same idea scales to prisms and
traversals [[9](#ref-9)]. The [eo library](https://eo.constructive.dev) is our
own working treatment: optics derived from the type with one
`.andThen` surface, and a [cookbook](https://eo.constructive.dev/cookbook)
of runnable recipes organised by the three jobs optics do best —
navigating structures, decoupling modules, and threading effects. The
three examples below follow its "contingent fields", "whole trees"
and "arbitrary structure" recipes.

## To and from

<figure class="rf-figure">
{% include_relative replace-mutable-fields-with-lenses/diagrams/koan.svg %}
<figcaption>The koan. One equation, read in two directions: replace
(package the reader and pure writer of a field as an optic value —
the "how to reach" and the "what to do") to the right, inline (drop
the optic, access the field directly) to the left. The move is
lawful by construction: the optic families are derived from the types
and compose, and the libraries ship solvers that check the ones you
write by hand.</figcaption>
</figure>

The catalogue lists each refactoring in both directions because the two
moves are one equation read left to right and right to left. Replace a
field with a lens: define `get` and `set` for the field, replace every
read with `get`, every write with `set` or `modify`, and where the
field is nested compose the lenses. Inline a lens: replace `get`,
`set` and `modify` at their use sites with direct access, and delete
the optic. Both directions are checked by the same property: for all
generated inputs, the before-program and the after-program agree on
the entry point.

## Three examples

Each example is the same program twice, `Before` and `After`, in Scala 3
and in Haskell, using a tiny self-contained optic encoding — a lens, a
prism, a traversal, and the compositions between them — so the sources
run with no dependencies. The entry point keeps its name and its type,
the optic is the only difference, and a hedgehog property generates
inputs and demands that both versions agree on every one of them. The
three are eo's "navigate structures" recipes, in increasing depth of
nesting.

### 1 · A single node: prism and lens composed

A variable's name in one node of an expression tree. The Before
version is a hand-written match that rebuilds the hit branch and lets
every other shape pass. The After version is one composed optic —
`prism .andThen lens`: the prism decides whether the value is a `Var`
(the hit), the lens edits the `name` inside it, and every miss passes
through untouched. The *how* and the *what* are separate values; the
second property checks that the hit is uppercased and every miss
passes through.

<figure class="rf-figure">
{% include_relative replace-mutable-fields-with-lenses/01-rename-var/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/01-rename-var/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/01-rename-var/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/01-rename-var/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/01-rename-var/After.hs %}{% endhighlight %}
</div>
</div>

<details class="rf-spec">
<summary>The property: <code>Before.upperVarName == After.upperVarName</code> on generated trees, and the hit/miss behaviour</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/01-rename-var/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/01-rename-var/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

### 2 · Every node of a tree: the same optic, deeper nesting

Now the same edit is applied at *every* node of the tree — the nesting
is what makes the hand-written version hurt. The Before version is a
recursive walk that rebuilds a hit by hand at each level of the
recursion; add a level to the tree and the rebuild appears again. The
After version reuses the *same* `varName` optic from example 1 inside
a bottom-up `everywhere` walk: "how to reach a variable name" is
written once, and the walk only decides *where* it applies. This is
eo's "visit across whole trees" recipe — one derivation and one
`.andThen`, rather than a rewrite.

<figure class="rf-figure">
{% include_relative replace-mutable-fields-with-lenses/02-rename-tree/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/02-rename-tree/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/02-rename-tree/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/02-rename-tree/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/02-rename-tree/After.hs %}{% endhighlight %}
</div>
</div>

<details class="rf-spec">
<summary>The property: <code>Before.renameAll == After.renameAll</code> on generated trees, and every name is uppercased afterwards</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/02-rename-tree/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/02-rename-tree/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

### 3 · A sparse walk over a list: traversal, prism and lens

A batch of results, some succeeded and some failed; bump only the
successes. The Before version is a `map` carrying the branch test and
the rebuild in the same step. The After version is one composed optic
— `each .andThen prism .andThen lens`: the traversal reaches every
element, the prism selects the succeeded branch, the lens edits its
value, and every failed element passes through untouched. This is eo's
[cookbook recipe "visit through arbitrary structure"](https://eo.constructive.dev/cookbook#visit-through-arbitrary-structure),
which notes that this sparse walk is the shape a hand-rolled loop gets
wrong — the container and the branch test fight over who owns the
loop; composed optics keep the two apart.

<figure class="rf-figure">
{% include_relative replace-mutable-fields-with-lenses/03-bump-oks/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/03-bump-oks/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/03-bump-oks/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/03-bump-oks/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/03-bump-oks/After.hs %}{% endhighlight %}
</div>
</div>

<details class="rf-spec">
<summary>The property: <code>Before.bumpSucceeded == After.bumpSucceeded</code> on generated batches, and only successes are bumped</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-mutable-fields-with-lenses/03-bump-oks/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-mutable-fields-with-lenses/03-bump-oks/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

## Pitfalls

The real pitfalls of this move are the ones that come from carrying
machinery that does not earn its keep, or from rebuilding more than
the focus.

- **Accidental complexity.** An optic is worth its indirection when
  the path composes or varies; a lens for a leaf field that only one
  caller reads and one writes is a detour — a plain field says the
  same thing. The same for a traversal where a plain `map` with an
  explicit match would do: if the container and the branch never
  change, the two-in-one loop is clearer. This is the inverse side of
  the equation; it is also the most common way the move goes wrong.
- **Rebuilding more than the focus.** When you write an optic by
  hand, the writer must rebuild only what was matched or selected. A
  prism's `review` that reconstructs a value with the wrong fields,
  or a `set` that touches a neighbouring field, silently changes the
  program — the composition is only as good as the instances you
  compose, which is why the law-solvers in Verification matter.
- **Laziness and evaluation count.** `modify` reads the focus,
  applies a function and writes it back. In Haskell the setter is
  lazy in the new value, and rewriting one element of a traversal
  must not force the others; in Scala a `def` recomputes and a `val`
  shares, so where a lens is stored and how it is applied changes how
  often its functions run.
- **Choosing the wrong family.** A lens addresses exactly one field,
  a prism one branch, a traversal many. "Focus a pair of fields" or
  "edit a field that may be absent" are different families (an affine
  traversal, a prism), and composing optics whose foci do not line up
  is a type error, not a runtime bug — the types reject the onesided
  composition, so the mistake shows up at compile time rather than in
  production.

In each case the fix is the same: choose the smallest optic that says
the path, derive it from the type when you can, and check the ones you
write by hand.

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
input of the program, not an artefact of a separate shrinker.

A property is only worth having if it can fail, so each spec above was
mutation-checked: change `After` so it is no longer equivalent — a sign
flip, a wrong target — confirm the property reports and shrinks a
counterexample, then restore `After`. A property that does not fail
under mutation is testing the generator, not the refactoring.

The optics themselves need no per-example law properties, because they
are lawful by construction — but the libraries ship *law-solvers* for
the instances you do write by hand, so you do not have to re-derive
the rules. [eo](https://eo.constructive.dev) ships `cats-eo-laws` with
`FooTests`/`FooLaws` for every optic family, Monocle ships
`monocle-law` with `LensLaws` and `PrismLaws` [[11](#ref-11)], and for Haskell
`genvalidity-hspec-optics` provides `lensSpec` and `prismSpec`
one-liners [[12](#ref-12)]. The property checks the refactoring; the solvers
check the optics you wrote to do it.

To run everything on this page yourself, from a checkout of
[the site repository](https://github.com/Constructive-Programming/website):

```sh
sh pages/refactorings/replace-mutable-fields-with-lenses/run.sh
```

It needs [scala-cli](https://scala-cli.virtuslab.org/) and either GHC
with hedgehog installed or Docker, and ends with `all properties passed`.

## References

<ol>
<li id="ref-1">Martin Fowler. <em>Refactoring: Improving the Design of Existing Code</em>. Addison-Wesley, 1999. <a href="https://martinfowler.com/books/refactoring.html">https://martinfowler.com/books/refactoring.html</a></li>
<li id="ref-2">Martin Fowler. <em>Encapsulate Variable</em> (formerly <em>Encapsulate Field</em>, before that <em>Self-Encapsulate Field</em>). Refactoring.com, online edition. <a href="https://refactoring.com/catalog/encapsulateField.html">https://refactoring.com/catalog/encapsulateField.html</a></li>
<li id="ref-3">Martin Fowler. <em>Remove Setting Method</em>. Refactoring.com, online edition. <a href="https://refactoring.com/catalog/removeSettingMethod.html">https://refactoring.com/catalog/removeSettingMethod.html</a></li>
<li id="ref-4">J. Nathan Foster, Michael B. Greenwald, Jonathan T. Moore, Benjamin C. Pierce and Alan Schmitt. &ldquo;Combinators for Bidirectional Tree Transformations: A Linguistic Approach to the View-Update Problem&rdquo;. <em>ACM Transactions on Programming Languages and Systems</em> 29(3):17, 2007. <a href="https://doi.org/10.1145/1232420.1232424">https://doi.org/10.1145/1232420.1232424</a></li>
<li id="ref-5">Russell O&rsquo;Connor. &ldquo;Functor is to Lens as Applicative is to Biplate: Introducing Multiplate&rdquo;. In <em>Proceedings of the ACM SIGPLAN Workshop on Generic Programming (WGP 2011)</em>, pp. 25&ndash;36. <a href="https://arxiv.org/abs/1103.2841">https://arxiv.org/abs/1103.2841</a></li>
<li id="ref-6">Jeremy Gibbons and Michael Johnson. &ldquo;Relating Algebraic and Coalgebraic Descriptions of Lenses&rdquo;. <em>Electronic Communications of the EASST</em> 49:1&ndash;16, 2012 (Workshop on Bidirectional Transformations 2012). <a href="https://doi.org/10.14279/tuj.eceasst.49.726">https://doi.org/10.14279/tuj.eceasst.49.726</a></li>
<li id="ref-7">Twan van Laarhoven. &ldquo;Talk on Lenses&rdquo;. Slides, Radboud University Nijmegen, 17 May 2011. <a href="https://www.twanvl.nl/blog/news/2011-05-19-lenses-talk">https://www.twanvl.nl/blog/news/2011-05-19-lenses-talk</a></li>
<li id="ref-8">Edward Kmett. <em>lens: Lenses, Folds and Traversals</em>, and <em>Control.Lens</em> documentation. <a href="https://hackage.haskell.org/package/lens">https://hackage.haskell.org/package/lens</a></li>
<li id="ref-9">Matthew Pickering, Jeremy Gibbons and Nicolas Wu. &ldquo;Profunctor Optics: Modular Data Accessors&rdquo;. <em>The Art, Science, and Engineering of Programming</em> 1(2):7, 2017. <a href="https://doi.org/10.22152/programming-journal.org/2017/1/7">https://doi.org/10.22152/programming-journal.org/2017/1/7</a></li>
<li id="ref-10">Mirko Stocker. <em>Scala Refactoring</em>. Master&rsquo;s thesis, HSR Hochschule f&uuml;r Technik Rapperswil, 2010. <a href="https://eprints.ost.ch/id/eprint/286/">https://eprints.ost.ch/id/eprint/286/</a></li>
<li id="ref-11">Julien Truffaut and contributors. <em>Monocle: Optics Library for Scala</em> (including <code>monocle-law</code>). <a href="https://www.optics.dev/Monocle/">https://www.optics.dev/Monocle/</a></li>
<li id="ref-12">Constructive Programming. <em>eo: optics library and cookbook for Scala 3</em>. <a href="https://eo.constructive.dev">https://eo.constructive.dev</a> (<a href="https://eo.constructive.dev/cookbook">cookbook</a>)</li>
<li id="ref-13">Koen Claessen and John Hughes. &ldquo;QuickCheck: a lightweight tool for random testing of Haskell programs&rdquo;. In <em>Proceedings of the ACM SIGPLAN International Conference on Functional Programming (ICFP 2000)</em>, pp. 268&ndash;279. <a href="https://doi.org/10.1145/351240.351266">https://doi.org/10.1145/351240.351266</a></li>
<li id="ref-14">Jacob Stanley and contributors. <em>Hedgehog: release with confidence, state-of-the-art property testing</em>. <a href="https://github.com/hedgehogqa/haskell-hedgehog">https://github.com/hedgehogqa/haskell-hedgehog</a> and <a href="https://github.com/hedgehogqa/scala-hedgehog">https://github.com/hedgehogqa/scala-hedgehog</a></li>
</ol>
