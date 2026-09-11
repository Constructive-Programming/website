---
layout: page
title: Replace Inheritance with Natural Transformation
subtitle: "Replace inheritance with natural transformation: the is-a between two generic containers becomes a named conversion, polymorphic in the element and lawful by parametricity — make the arrow implicit again, and it dissolves back into an is-a"
permalink: /refactorings/replace-inheritance-with-natural-transformation/
tags: [refactorings, replace-inheritance-with-natural-transformation]
hide: true   # entry pages are reached from the catalogue, not the top-right nav
---

<p class="rf-crumb"><a href="{{ '/refactorings/' | relative_url }}">← The refactoring catalogue</a> · 7 of 35</p>

Inheritance between container types is the object-oriented world's
best-documented regret — `java.util.Stack extends Vector` (the
Javadoc itself now steers users elsewhere [[5](#ref-5)]), `Properties extends
Hashtable` (Bloch's standing violations of *favor composition over
inheritance* [[4](#ref-4)], [[3](#ref-3)]), Smalltalk-80's `Dictionary` as a subclass of
`Set` [[6](#ref-6)], [[7](#ref-7)] — and the theory agrees with the folklore: inheritance
is not subtyping [[8](#ref-8)], [[9](#ref-9)]. Where Fowler's *Replace Superclass with
Delegate* discards the is-a [[1](#ref-1)], [[2](#ref-2)], the functional reading keeps
what it truly asserted — that at every element type `A` a `Stack[A]`
can stand for a `Vector[A]`, uniformly, because the coercion never
looks at the elements — and names it: a *natural transformation*
[[10](#ref-10)], [[11](#ref-11)], in code a rank-1 polymorphic function
`toVector: Stack[A] => Vector[A]`, whose law — converting then
mapping equals mapping then converting — is Wadler's theorem for
free [[12](#ref-12)], [[13](#ref-13)]; no higher-kinded types until you abstract over
*which* containers (`FunctionK`, `F ~> G`), which is the next group
of this catalogue. The equation reads in both directions: where the
is-a holds strictly and universally — every Applicative *is* a
Functor, every Circle *is* a Shape — the coercion is total and
lawful, and the inverse move, making the arrow implicit again, is
just as legitimate.

## Motivation

Reach for the arrow when the is-a is a lie that exposes unexpected
behaviour.
A subclass (or alias) of a container inherits the whole container
API, so the specialized type's invariant lives in the callers'
discipline rather than in the type: nothing stops list surgery on an
undo history, or a `Set`-style insertion that gives a dictionary two
values for one key. Every operation the supertype gains, the subtype
gains too, meaningful or not — the fragile-base-class problem is this
leak seen over time. And the representation is frozen: a `Stack` that
is-a `Vector` can never become a linked list. Naming the coercion
fixes all three at once. The specialized type exports exactly its
discipline; the general API is reachable only through an explicit,
typed conversion, so the compiler lists every place the two worlds
touch; and the law the is-a only ever promised — that the coercion is
uniform in the elements — becomes a theorem of the arrow's type.

Reach for the inverse when the wrapper protects nothing, or when the
is-a relationship holds universally true. If every call site converts
immediately, the arrow is noise — `toList` at every seam, a name that
adds a hop, not meaning.
Making the type transparent again (an alias, an exported underlying
API, or a genuine subtype where the language has one) says the same
thing more briefly. The precondition is the one Liskov and Wing
state: the is-a must be total — every general operation meaningful on
the specialized value and harmless to its invariants [[9](#ref-9)]. Where that
holds, the arrow was an isomorphism in waiting, and inlining it loses
nothing; where it does not, the "inverse" is not a refactoring but a
regression to the smell.

## The move

Fowler's mechanics for *Replace Superclass with Delegate* — a field
holding an instance of the former superclass, a forwarding method for
each operation the subclass really supports, then remove the
`extends` [[1](#ref-1)] — carry over almost verbatim: declare the specialized
type as its own type (a `newtype`, a `final case class`, an `opaque
type`) holding the general representation privately, give it exactly
the operations of its discipline, and define the arrow — one line,
the accessor, `toList`, `entries`, `toOption`, polymorphic in the
element. Then follow the type errors: every place that used the
specialized value *as* the general one is now either an operation the
type should own (move it inside) or a genuine departure into the
general world (apply the arrow) — the alias made those crossings
invisible, the wrapper makes them a checklist. Where the inverse
arrow is total — `fromList` is just the constructor — define it too,
and the pair witnesses that the wrapper forgets nothing; where it is
not (a set of pairs is not a map), its absence is the point: the
invariant now has an owner.

## To and from

<figure class="rf-figure">
{% include_relative replace-inheritance-with-natural-transformation/diagrams/koan.svg %}
<figcaption>The koan. One equation, read in two directions: replace
(name the coercion the is-a made implicit; hide the representation)
to the right, inline (make the conversion implicit again; expose the
representation) to the left. The named arrow α has one component per
element type, and the naturality square — α then map equals map then
α — holds for any function of α's type, by parametricity.</figcaption>
</figure>

The catalogue lists each refactoring in both directions because the
two moves are one equation read left to right and right to left. To
the right: the is-a between `S[A]` and `G[A]` becomes an arrow
`α : S[A] => G[A]`, applied wherever a specialized value used to pass
silently as a general one. To the left: where α is one half of an
isomorphism and no invariant separates the two types, erase the
wrapper and let the coercion be implicit — in Haskell the `newtype`
erases at runtime already, so inlining it is purely a source-level
act. Both directions are checked by the same property: for all
generated inputs, the before-program and the after-program agree on
the entry point.

## Three examples

Each example is the same program twice, `Before` and `After`, in
Scala 3 and in Haskell. The entry point keeps its name and its type,
the replacement of an is-a by an arrow is the only difference, and a
hedgehog property generates inputs and demands that both versions
agree on every one of them; a second property states the naturality
square itself, the law the is-a only ever implied. The three escalate
by what the arrow preserves: everything (a wrapper whose two arrows
forget nothing), an invariant (every map is a set of pairs; not every
set of pairs is a map), and finally only part of the structure (the
error channel forgotten, and the way back needs a chosen default).
The sources below are included verbatim from the files the tests run
against.

### 1 · An undo history: the textbook move

Java's `Stack extends Vector` in miniature. `Before` writes the is-a
the way a functional language writes it — a transparent alias — and
the history's API is the whole list API: `undo` is `dropRight`,
nothing distinguishes the stack's discipline from arbitrary list
surgery on it, and `replay` hands the stack itself to the UI — the
body `build(cmds)` type-checks only because a `Stack` literally *is*
the list. `After` makes `Stack` its own type owning `push` and
`undo`, and the old is-a survives as the one-line arrow `toList`,
applied exactly where the program genuinely leaves the stack world:
the old body of `replay` no longer compiles, which is the move doing
its job. The arrow back, `fromList`, is the constructor: this pair
forgets nothing, which is why the inverse refactoring stays available
here.

<figure class="rf-figure">
{% include_relative replace-inheritance-with-natural-transformation/01-stack-vector/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-inheritance-with-natural-transformation/01-stack-vector/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-inheritance-with-natural-transformation/01-stack-vector/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-inheritance-with-natural-transformation/01-stack-vector/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-inheritance-with-natural-transformation/01-stack-vector/After.hs %}{% endhighlight %}
</div>
</div>

Note what the Haskell `newtype` buys: the arrow is free at runtime —
`toList` erases entirely — so the conversion costs what the
inheritance cost, nothing, while the source now marks every crossing.

<details class="rf-spec">
<summary>The properties: <code>Before.replay == After.replay</code>,
and <code>toList</code> commutes with <code>map</code></summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-inheritance-with-natural-transformation/01-stack-vector/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-inheritance-with-natural-transformation/01-stack-vector/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

### 2 · A phone book: the arrow guards an invariant

Smalltalk-80's `Dictionary` is-a `Set` in miniature [[6](#ref-6)], [[7](#ref-7)].
`Before` stores a phone book as a set of pairs, so *one value per
key* belongs to no type: `put` re-imposes it by hand — filter the old
key out, insert the new pair — and every future operation must
remember to do the same, forever. (The representation also demands an
ordering on the *values* in Haskell, which a map never needs.)
`After` gives the invariant an owner, `Map`, and keeps the honest
half of the old is-a as the arrow `entries` — every map *is* a set of
pairs — applied exactly where the program wants set algebra: the
intersection of two books. The other half is gone by design: a set of
pairs with colliding keys is not a map until someone chooses a merge
policy, and choosing one is a design decision, not a refactoring.

<figure class="rf-figure">
{% include_relative replace-inheritance-with-natural-transformation/02-dictionary-set/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-inheritance-with-natural-transformation/02-dictionary-set/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-inheritance-with-natural-transformation/02-dictionary-set/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-inheritance-with-natural-transformation/02-dictionary-set/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-inheritance-with-natural-transformation/02-dictionary-set/After.hs %}{% endhighlight %}
</div>
</div>

The naturality property here is worth reading twice: `entries`
commutes with mapping a function over the *values*, even a
non-injective one, because the keys keep the pairs apart. The same
square drawn for *keys* fails on collisions — naturality is a
statement about the parameter you kept polymorphic, not about the
type constructor wholesale. The pitfalls return to this.

<details class="rf-spec">
<summary>The properties: <code>Before.common == After.common</code>,
and <code>entries</code> commutes with mapping values</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-inheritance-with-natural-transformation/02-dictionary-set/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-inheritance-with-natural-transformation/02-dictionary-set/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

### 3 · A parsed form field: the arrow forgets

The escalation completes: here the inheritance is *multiple*. One
result class is-a both views — the diagnosis (`err`) and the presence
(`value`) — so every caller sees both protocols, and the class must
answer both, forever: each new consumer view is another supertype
bolted onto the hierarchy. `Before` writes that god-type out (in
Haskell, which has no subtyping, the merged sum type with a
hand-rolled function per view is the same design). `After` keeps one
canonical type at the boundary — `Either`, the shape with all the
information — and renders each view as an arrow instead of a
superclass: `toOption` (`toMaybe`) forgets the error channel, and the
caller that wanted presence gets exactly `Option[Int]`. The standard
libraries are full of this arrow's relatives — `listToMaybe` and
`maybeToList` in `Data.Maybe`, `.toOption`, `.toList`, `.toSet` in
Scala — everyday natural transformations nobody bothers to name as
such. The arrow is lossy, and the way back, `note(e)` / `toRight(e)`,
must invent an error value: `toOption(note(e)(o)) == o` for every
`o`, but the composite the other way is not the identity. Forgetting
is one-way, and the type records it.

<figure class="rf-figure">
{% include_relative replace-inheritance-with-natural-transformation/03-either-option/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-inheritance-with-natural-transformation/03-either-option/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-inheritance-with-natural-transformation/03-either-option/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-inheritance-with-natural-transformation/03-either-option/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-inheritance-with-natural-transformation/03-either-option/After.hs %}{% endhighlight %}
</div>
</div>

<details class="rf-spec">
<summary>The properties: <code>Before.quantity == After.quantity</code>,
and <code>toOption</code> commutes with <code>map</code></summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-inheritance-with-natural-transformation/03-either-option/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-inheritance-with-natural-transformation/03-either-option/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

## Pitfalls

The equation has hypotheses, and most of them attach to the *inverse*
direction — the replace direction is protected by parametricity, the
inline direction by nothing but your judgement.

- **The way back may need a policy.** `entries` is an equation;
  "set of pairs to map" is not, until a merge for colliding keys is
  chosen — and a merge that inspects values breaks the naturality
  square (two pairs a function `f` maps to the same value need not
  merge to the image of the merge). Likewise `Option` to `Either`
  needs an invented error. Choosing a policy or a default is design;
  do not present it as a refactoring, and test it as a change.
- **Naturality is per type parameter.** A `Map[K, V]` is a functor in
  `V` at fixed `K`; `entries` commutes with mapping values, not with
  mapping keys, where collisions merge entries. State the law in the
  parameter the arrow is polymorphic in, and keep the other fixed.
- **Conversions cost what inheritance hid.** The subtype view was
  free; the arrow may be O(n) — `entries` walks the map, `.toSet`
  allocates. Convert once at the seam, not inside a loop that the
  is-a used to cross silently. Where the arrow is a `newtype`
  accessor it is free, and Haskell erases it at runtime.
- **Wrapper versus alias changes strictness in Haskell.** A `newtype`
  is the honest inheritance-eraser: same representation, same
  strictness. A `data` wrapper adds a lift — `Stack ⊥` is not `⊥` —
  so swapping one for the other can change what a program forces.
- **Do not rebuild cross-type equality across the arrow.** Cook's
  survey found methods with the same name and unrelated behaviours in
  one hierarchy [[7](#ref-7)]; the two-type version of that bug is an `equals`
  that converts and compares. After the move, cross-type equality
  does not typecheck. Let that stand.
- **A natural transformation is not a type class.** A type class
  replaces *dispatch* — which implementation runs for this type; the
  arrow replaces *coercion* — this shape passed off as that one. The
  shape-hierarchy examples (circle, square, one `area` method) belong
  to *Replace subtypes with type class instances*, not here. Reaching
  for `F ~> G` as a first-class value — abstracting over the
  containers, not the elements — is the moment higher-kinded types
  arrive, and that is the next group of this catalogue.

<details class="rf-spec">
<summary>The functional reading</summary>
<div markdown="1">

A natural transformation between functors `F` and `G` is a family of
maps `α[A]: F[A] → G[A]`, one per object `A`, such that for every
`f: A → B` the square commutes: `α ∘ F.map(f) = G.map(f) ∘ α`.
Eilenberg and Mac Lane defined it in 1945 — the paper that introduced
categories and functors did so, by its own account, in order to say
*natural* precisely [[10](#ref-10)], [[11](#ref-11)]. The programming reading is
plain: `α` rearranges, duplicates, discards or repackages structure,
and never inspects the elements. `reverse`, `concat`, `listToMaybe`,
`Map.toList`, `Either.toOption` — the standard libraries are full of
natural transformations that nobody introduces as such.

In a parametrically polymorphic language the naturality square is not
a proof obligation. Reynolds's abstraction theorem says a term of
type `∀a. F a → G a` relates related inputs to related outputs
[[12](#ref-12)]; Wadler's *Theorems for Free!* turns the crank: every function
of that type satisfies the square, no matter how it is written
[[13](#ref-13)]. That is why the move is safe in the only direction that
matters. Inheritance promised uniformity behaviourally — Liskov and
Wing's substitutability [[9](#ref-9)] — and the type system could not check
it; Cook, Hill and Canning showed the two hierarchies come apart
[[8](#ref-8)]. The arrow keeps the part of the promise that was true and gets
the law for free.

Note the quantifier. One arrow between two *fixed* containers is
rank-1 polymorphism — `def toList[A](s: Stack[A]): List[A]`,
`toList :: Stack a -> [a]` — available in any language with generics,
Java included. Higher-kinded types enter only when the *functors*
become the parameters: Scala's polymorphic function types
`[A] => Stack[A] => List[A]` and cats' `FunctionK` (`F ~> G`), or
Haskell's `type f ~> g = forall a. f a -> g a`, name the concept so
that interpreters and effect stacks can abstract over it. That is
deliberately out of scope here: this entry needs no higher kinds,
which is why it sits in this group of the catalogue, with the
final-tagless and type-class entries next door.

</div>
</details>

## Verification

Because the replacement is an equation, its correctness is a
property: for all inputs *x* in the domain of the entry point,
`Before x == After x`. That is a one-line property in the sense
Claessen and Hughes introduced with QuickCheck [[14](#ref-14)], stated here
with hedgehog in both languages [[15](#ref-15)], whose integrated shrinking
reports a minimal failing input that obeys the generators'
invariants. Each example carries a second property, the naturality
square of its arrow. Parametricity makes the square a theorem, so
the property cannot fail while the arrow stays honestly polymorphic —
it is the tripwire that fires if someone later specializes the
conversion to inspect elements (an `instanceof`, an `asInstanceOf`, a
type test) and silently breaks the contract the is-a once implied.

A property is only worth having if it can fail, so each spec is
mutation-checked before an entry ships: change `After` so it is no
longer equivalent — drop the key-filter in `put`, swap `dropRight(1)`
for `drop(1)`, invert the sign guard — and confirm the property reports
and shrinks a counterexample, then restore `After`. A property that
does not fail under mutation is testing the generator, not the
refactoring.

To run everything on this page yourself, from a checkout of
[the site repository](https://github.com/Constructive-Programming/website):

```sh
sh pages/refactorings/replace-inheritance-with-natural-transformation/run.sh
```

It needs [scala-cli](https://scala-cli.virtuslab.org/) and either GHC
with hedgehog installed or Docker, and ends with `all properties passed`.

## References

<ol>
<li id="ref-1">Martin Fowler. <em>Refactoring: Improving the Design of Existing Code</em>, second edition. Addison-Wesley, 2018. Catalogue entry &ldquo;Replace Superclass with Delegate&rdquo; (alias &ldquo;Replace Inheritance with Delegation&rdquo;). <a href="https://refactoring.com/catalog/replaceSuperclassWithDelegate.html">https://refactoring.com/catalog/replaceSuperclassWithDelegate.html</a></li>
<li id="ref-2">Martin Fowler, with contributions by Kent Beck, John Brant, William Opdyke and Don Roberts. <em>Refactoring: Improving the Design of Existing Code</em>. Addison-Wesley, 1999. Catalogue entry &ldquo;Replace Inheritance with Delegation&rdquo;. <a href="https://martinfowler.com/books/refactoring.html">https://martinfowler.com/books/refactoring.html</a></li>
<li id="ref-3">Erich Gamma, Richard Helm, Ralph Johnson and John Vlissides. <em>Design Patterns: Elements of Reusable Object-Oriented Software</em>. Addison-Wesley, 1994. &ldquo;Favor object composition over class inheritance.&rdquo; <a href="https://www.informit.com/store/design-patterns-elements-of-reusable-object-oriented-9780201633610">https://www.informit.com/store/design-patterns-elements-of-reusable-object-oriented-9780201633610</a></li>
<li id="ref-4">Joshua Bloch. <em>Effective Java</em>, third edition. Addison-Wesley, 2018. Item 18: &ldquo;Favor composition over inheritance&rdquo;, naming <code>Stack</code>/<code>Vector</code> and <code>Properties</code>/<code>Hashtable</code> as violations. <a href="https://www.informit.com/store/effective-java-9780134685991">https://www.informit.com/store/effective-java-9780134685991</a></li>
<li id="ref-5">Java Platform, Standard Edition API Specification, class <code>java.util.Stack</code>: &ldquo;A more complete and consistent set of LIFO stack operations is provided by the Deque interface and its implementations, which should be used in preference to this class.&rdquo; <a href="https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Stack.html">https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Stack.html</a></li>
<li id="ref-6">Adele Goldberg and David Robson. <em>Smalltalk-80: The Language and its Implementation</em>. Addison-Wesley, 1983. In the collection hierarchy, <code>Dictionary</code> is a subclass of <code>Set</code>. <a href="http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf">http://stephane.ducasse.free.fr/FreeBooks/BlueBook/Bluebook.pdf</a></li>
<li id="ref-7">William R. Cook. &ldquo;Interfaces and Specifications for the Smalltalk-80 Collection Classes&rdquo;. In <em>OOPSLA 1992</em>, pp. 1&ndash;15. <a href="https://doi.org/10.1145/141936.141938">https://doi.org/10.1145/141936.141938</a></li>
<li id="ref-8">William R. Cook, Walter L. Hill and Peter S. Canning. &ldquo;Inheritance Is Not Subtyping&rdquo;. In <em>POPL 1990</em>, pp. 125&ndash;135. <a href="https://doi.org/10.1145/96709.96721">https://doi.org/10.1145/96709.96721</a></li>
<li id="ref-9">Barbara H. Liskov and Jeannette M. Wing. &ldquo;A Behavioral Notion of Subtyping&rdquo;. <em>ACM Transactions on Programming Languages and Systems</em> 16(6):1811&ndash;1841, 1994. <a href="https://doi.org/10.1145/197320.197383">https://doi.org/10.1145/197320.197383</a></li>
<li id="ref-10">Samuel Eilenberg and Saunders Mac Lane. &ldquo;General Theory of Natural Equivalences&rdquo;. <em>Transactions of the American Mathematical Society</em> 58:231&ndash;294, 1945. <a href="https://doi.org/10.1090/S0002-9947-1945-0013131-6">https://doi.org/10.1090/S0002-9947-1945-0013131-6</a></li>
<li id="ref-11">Saunders Mac Lane. <em>Categories for the Working Mathematician</em>, second edition. Graduate Texts in Mathematics 5, Springer, 1998. <a href="https://doi.org/10.1007/978-1-4757-4721-8">https://doi.org/10.1007/978-1-4757-4721-8</a></li>
<li id="ref-12">John C. Reynolds. &ldquo;Types, Abstraction and Parametric Polymorphism&rdquo;. In <em>Information Processing 83</em> (IFIP), pp. 513&ndash;523, 1983. <a href="https://www.cs.cmu.edu/afs/cs/user/jcr/ftp/typesabpara.pdf">https://www.cs.cmu.edu/afs/cs/user/jcr/ftp/typesabpara.pdf</a></li>
<li id="ref-13">Philip Wadler. &ldquo;Theorems for Free!&rdquo;. In <em>Functional Programming Languages and Computer Architecture (FPCA 1989)</em>, pp. 347&ndash;359. <a href="https://doi.org/10.1145/99370.99404">https://doi.org/10.1145/99370.99404</a></li>
<li id="ref-14">Koen Claessen and John Hughes. &ldquo;QuickCheck: a lightweight tool for random testing of Haskell programs&rdquo;. In <em>Proceedings of the ACM SIGPLAN International Conference on Functional Programming (ICFP 2000)</em>, pp. 268&ndash;279. <a href="https://doi.org/10.1145/351240.351266">https://doi.org/10.1145/351240.351266</a></li>
<li id="ref-15">Hedgehog, property-based testing with integrated shrinking: <a href="https://github.com/hedgehogqa/scala-hedgehog">scala-hedgehog</a> and <a href="https://github.com/hedgehogqa/haskell-hedgehog">haskell-hedgehog</a>.</li>
</ol>
