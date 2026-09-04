---
layout: page
title: Replace Global State with Parameter
subtitle: "Replace global state with parameter: the hidden dependency becomes an argument the caller supplies — capture an invariant parameter back into one shared definition, and it becomes global again"
permalink: /refactorings/replace-global-state-with-parameter/
tags: [refactorings, replace-global-state-with-parameter]
hide: true   # entry pages are reached from the catalogue, not the top-right nav
---

<p class="rf-crumb"><a href="{{ '/refactorings/' | relative_url }}">← The refactoring catalogue</a> · 3 of 35</p>

A global is a value reachable from anywhere, appearing in no signature.
The object-oriented catalogue names it as a smell — *Global Data* in the
second edition's bad-smells list, whose only listed cure is
*Encapsulate Variable* [[1](#ref-1)] — and as a pattern, the Singleton,
whose intent is precisely "a global point of access" [[2](#ref-2)]. The
testing literature is harsher: singletons are "global state in sheep's
clothing", and the moment code traverses a global, its API "lies about
its true dependencies" [[4](#ref-4)]. The OO corrective is dependency
injection: wire collaborators in from the outside instead of letting
objects reach out for them [[3](#ref-3)].

The functional reading starts from the same smell and states it in one
sentence: a global is a free variable that no binder owns. A function
that reads one has a hidden dependency, and if the cell is mutable, two
identical calls need not return identical results — referential
transparency fails silently. The move is to make the dependency
explicit: the value becomes a parameter the caller supplies. Where the
global was mutable, the function becomes a *state transformer* — a
function from the state it reads to the state it returns, the shape
Launchbury and Peyton Jones give to stateful computation in Haskell
[[5](#ref-5)]. The inverse move exists and has its own smell, which is why
this entry, like every entry here, presents both directions as one
equation.

## Motivation

Reach for the parameter when the signature lies. A function that reads a
global needs something its type never mentions: the reader cannot see
the dependency, the caller cannot control it, and two callers are
coupled through the shared cell even though neither names the other.
Tests inherit the coupling — each must set the cell up, reset it, and
pray no other test runs concurrently against it; call order becomes
observable, because every call can leave the cell different from how it
found it. Making the value a parameter restores the truth: the signature
lists what the function needs, the function runs unchanged under any
value the caller supplies, and where the cell was mutable the returned
state records the effect instead of hiding it in a shared location.

Reach for the inverse when the parameter is noise. The smell that drives
it is parameter pollution: the same value threaded through a deep call
tree whose intermediate functions never inspect it, each signature
carrying an argument only to hand it on. Where the value is genuinely
invariant across the whole subtree, capturing it back into one shared
definition says the same thing more briefly, and the signatures shrink
to what each function actually decides. The precondition is the
invariance: capture a parameter that varies between calls and the
program has changed, not merely moved. When the value varies but the
plumbing still stings, the principled middle way — bundling the
environment into a computation rather than threading it by hand — is the
next entry in this catalogue.

## The move

The mechanics are short. Find every function that reads or writes the
global. Give each one a parameter for it — leading, by convention — and
replace every read with the parameter. Update the call sites to supply
the value; where several call sites shared the cell, each now supplies
its own. If the function wrote the cell, it returns the new value as
part of its result instead, and the caller threads that result into the
next call. Test. Fowler's catalogue stops one step short: its answer to
*Global Data* is *Encapsulate Variable*, which hides the cell behind
accessors but leaves it shared [[1](#ref-1)]; parameterisation removes the
sharing itself. Dependency injection performs the same move at
construction time, replacing a global lookup with a value handed in
[[3](#ref-3)].

In the functional reading the move is abstraction. A global is a free
variable of every definition that mentions it; replacing it with a
parameter is defining a new function whose parameters are the old free
variables and whose body is the old definition, then calling it with the
value the global held. Johnsson's lambda lifting is the same step pushed
to a whole program — nested definitions lifted to top level by adding
their free variables as leading parameters [[6](#ref-6)]. Where the global
was mutable, each read becomes an input and each write part of the
result, and the definition takes the shape of a state transformer, a
function from an initial state to a final one [[5](#ref-5)]. The
equation's hypotheses are the constructive criteria: every read sees the
value the caller supplied, every write is returned rather than lost, and
the calls happen exactly as often and in the same order as before.

## To and from

<figure class="rf-figure">
{% include_relative replace-global-state-with-parameter/diagrams/koan.svg %}
<figcaption>The koan. One equation, read in two directions: replace the
global with a parameter to the right — the definition that reached
aside for <em>g</em> receives it from its caller instead; capture the
parameter to the left — where it is invariant across the whole
subtree, one shared definition supplies it and the signatures shrink.
The two directions are the same equality between programs.</figcaption>
</figure>

The catalogue lists each refactoring in both directions because the two
moves are one equation read left to right and right to left. For a
definition *f* that reads a global *g* and a caller that supplies the
value *v*, *f* reaching for *g* equals *f′* applied to *v*, provided
every read of *g* inside *f* sees *v*, every write is returned, and the
call order is unchanged. Read from global to parameter it is this entry:
abstract over the hidden dependency, supply it at the call sites. Read
from parameter to global it is the inverse: where a parameter is
invariant across a call graph, drop it back into a shared definition —
Danvy and Schultz's lambda dropping, which restores block structure by
dropping invariant parameters back into scope [[7](#ref-7)]. The directions
serve different ends. Parameterisation is for truth and isolation: the
signature states the dependency, and the function can be tested and
reused under values the original cell never held. Capture is for
brevity: plumbing that carries a value nobody inspects is noise, and one
named definition replaces a dozen identical arguments.

## Three examples

Each example is the same program twice, `Before` and `After`, in Scala 3
and in Haskell. The entry point keeps its name, the parameterisation is
the only difference, and a hedgehog property generates inputs and
demands that both versions agree on every one of them. The sources below
are included verbatim from the files the tests run against.

### 1 · A hidden setting: the textbook move

A service fee lives in a global `val`; the function `fee` reads it, and
nothing in its signature says so. The move is one line: `fee` takes the
value it used to read as a leading parameter, and the entry point
`total` supplies the program's default. The default has not disappeared
— the refactoring does not delete the setting, it stops the code from
depending on it implicitly. The second property pins the gain: the fee
is now controlled by the parameter, so the spec exercises fee values the
`Before` version could never see.

<figure class="rf-figure">
{% include_relative replace-global-state-with-parameter/01-hidden-setting/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-global-state-with-parameter/01-hidden-setting/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-global-state-with-parameter/01-hidden-setting/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-global-state-with-parameter/01-hidden-setting/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-global-state-with-parameter/01-hidden-setting/After.hs %}{% endhighlight %}
</div>
</div>

<details class="rf-spec">
<summary>The property: <code>Before.total == After.total</code> on generated orders, and the parameter really controls the fee</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-global-state-with-parameter/01-hidden-setting/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-global-state-with-parameter/01-hidden-setting/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

### 2 · A shared policy: the whole record becomes one parameter

The step of a fold reads a policy record — overdraft limit and per
transaction fee — from a global `val`. The record becomes a leading
parameter of the step, and the entry point supplies it. Leading is the
useful position: in Haskell the step partially applies at exactly the
fold's boundary, `foldl' (applyTx policy) 0`, and the fold's type no
longer mentions the policy at all. The second property exercises a
different policy — no fee, a limit out of reach — and reduces the step
to plain addition. `Before` could not be tested against any policy but
its own; the parameter is what makes the question askable.

<figure class="rf-figure">
{% include_relative replace-global-state-with-parameter/02-shared-settings/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-global-state-with-parameter/02-shared-settings/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-global-state-with-parameter/02-shared-settings/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-global-state-with-parameter/02-shared-settings/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-global-state-with-parameter/02-shared-settings/After.hs %}{% endhighlight %}
</div>
</div>

The generators stay narrow on purpose: with a limit of 30 and
transactions between −30 and 30, the boundary where the next balance
equals the negated limit is hit within a handful of cases, which is
where a `<` quietly replaced by `<=` would hide (see Verification).

<details class="rf-spec">
<summary>The property: <code>Before.settle == After.settle</code> on generated transaction runs, and a neutral policy reduces the step to addition</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-global-state-with-parameter/02-shared-settings/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-global-state-with-parameter/02-shared-settings/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

### 3 · A fresh-number supply: the state itself becomes a parameter

Numbering every variable in an expression tree needs a supply of fresh
numbers. `Before` keeps the supply in a mutable global: a Scala `var`,
and in Haskell — where a mutable cell is an effect and cannot be
smuggled into pure code — a top-level `IORef` that forces the entry
point to live in `IO`. `After` threads the supply as a parameter through
the walk and returns the updated value with each result: each read is an
input, each write part of the answer, exactly the state-transformer
shape [[5](#ref-5)]. The order of reads and writes is no longer a fact
about when calls happen; it is recorded in the data flow, where the type
checker and the tests can see it. In Haskell the entry point is pure
again, and the signature records the improvement. In Scala the `var`
hid the effect all along, so the improvement shows only in the tests and
in what a reader no longer has to check.

<figure class="rf-figure">
{% include_relative replace-global-state-with-parameter/03-fresh-names/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative replace-global-state-with-parameter/03-fresh-names/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative replace-global-state-with-parameter/03-fresh-names/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative replace-global-state-with-parameter/03-fresh-names/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative replace-global-state-with-parameter/03-fresh-names/After.hs %}{% endhighlight %}
</div>
</div>

The walk still forces nothing it did not force before: the spec puts an
`undefined` payload in a `Lit` and confirms in both versions that the
numbering passes through without touching it. And the labels come out
exactly `x0, x1, …` in visit order — no skips, no repeats, no
reordering — whatever tree the generator builds.

<details class="rf-spec">
<summary>The property: <code>Before.number == After.number</code> on generated trees, the labels run in order, and laziness survives</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative replace-global-state-with-parameter/03-fresh-names/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative replace-global-state-with-parameter/03-fresh-names/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

## Pitfalls

The equation has hypotheses, and each is one of the constructive
criteria. Where a hypothesis fails, parameterisation changes the
program.

- **Update order and count.** With a mutable cell, every read sees
  whatever the last write left there; the program's meaning depends on
  when calls happen relative to one another. Parameterising one function
  while other code still writes the cell can change what its reads see.
  The state-passing translation removes the hazard by construction: the
  order of reads and moves into the data flow, and the property checks
  it.
- **Aliasing.** Two names for one cell — two globals, or a global and a
  field — defeat the move: parameterise one path and the other still
  mutates behind the parameter's back. The OO literature calls this the
  aliasing problem with global data [[1](#ref-1)]; the cure is to
  parameterise every path before deleting the cell.
- **Reset ceremony.** A global that must be re-initialised between uses
  forces every entry point to reset it — both `Before` programs above
  carry that line. The ceremony is the smell made visible; the move
  deletes it, because a parameter is fresh by construction on every
  call.
- **Capture's precondition.** The inverse move — replacing a parameter
  with a shared definition — is sound only where the value is invariant
  across every call in the subtree. Capture a parameter that varies and
  you have not refactored; you have changed the program. Lambda dropping
  states the condition formally [[7](#ref-7)].
- **Partiality is preserved, not fixed.** The examples use integer
  arithmetic that overflows at the edges in both versions alike. The
  move changes how the value is reached, never what the computation
  does with it.

In each case the fix is the same: restore the hypothesis, or admit that
this is not a refactoring and test it as a change.

<details class="rf-spec">
<summary>The functional reading</summary>
<div markdown="1">

In a referentially transparent language a definition depends only on its
free variables, and the type checker lists them. A global is the one
exception a language can offer: a free variable that no binder owns,
reachable without appearing in any signature. Replacing it with a
parameter is the abstraction step — define a function whose parameters
are the free variables the global stood for, and call it with the
value the global held. There is no environment to rebuild, because
there was never anything but the value.

The lineage is the same one the extract/inline entry draws on, applied
one scope level out. Johnsson's lambda lifting turns nested definitions
into top-level equations by adding their free variables as leading
parameters [[6](#ref-6)]; replacing a global with a parameter is the same
transformation where the enclosing scope is the whole program. Danvy and
Schultz's lambda dropping is the inverse, restoring block structure by
dropping parameters that are invariant across a call graph back into
scope [[7](#ref-7)] — the capture direction of this entry, with its
invariance precondition stated formally. Where the cell is mutable,
Launchbury and Peyton Jones give the shape the parameterised program
takes: a stateful computation is a state transformer, a function from
an initial state to a final one, and the encapsulation that keeps one
piece of state from leaking into another is assured by the type system
[[5](#ref-5)].

And when the parameter is threaded through a deep tree that never
inspects it — the very smell that motivates the inverse — the typed
answer is not to go back to a global but to bundle the environment into
the computation itself. Jones's tutorial defines the reader monad as
"computations that consult some fixed environment" and builds the
transformer `ReaderT` on top of it [[8](#ref-8)]. That is the next entry
in this catalogue.

That is the point. With referential transparency the precondition does
not become easier to satisfy; it disappears, because the transformation
is an instance of the language's own equational theory. The hidden
dependency becomes an argument, and the program that used to hope it
preserved behaviour becomes an equation you wrote down.

</div>
</details>

## Verification

Because the move is an equation, its correctness is a property: for all
inputs *x* in the domain of the entry point, `Before x == After x`.
That is a one-line property in the sense Claessen and Hughes introduced
with QuickCheck, where a generator produces inputs and the framework
searches for a counterexample and shrinks it to a minimal one
[[9](#ref-9)]. The catalogue states every entry this way, in Scala and in
Haskell, with hedgehog on both sides [[10](#ref-10)], [[11](#ref-11)]. Hedgehog
is used because its shrinking is integrated into the generator, so the
minimal failing input it reports is a real input of the program.

A property is only worth having if it can fail, so each spec above was
mutation-checked: change `After` so it is no longer equivalent, confirm
the property reports and shrinks a counterexample, then restore it.
Replacing `<` with `<=` at the overdraft boundary of example 2 was
caught within the first handful of tests and shrunk to the one
transaction list `[-30]` where the balance lands exactly on the limit;
that is why the generators stay narrow and the boundary property runs
500 tests. Mutants that ignore the new parameter — hard-coding the old
global's value — pass the agreement property on purpose and are caught
by the second, purpose property of examples 1 and 2. Incrementing the
supply twice, or never, and numbering the right subtree before the left
were each caught by example 3's label properties, and a Haskell mutant
that forces a `Lit` payload was caught by the laziness probe while the
other two properties still passed.

To run everything on this page yourself, from a checkout of
[the site repository](https://github.com/Constructive-Programming/website):

```sh
sh pages/refactorings/replace-global-state-with-parameter/run.sh
```

It needs [scala-cli](https://scala-cli.virtuslab.org/) and either GHC
with hedgehog installed or Docker, and ends with `all properties passed`.

## References

<ol>
<li id="ref-1">Martin Fowler. <em>Refactoring: Improving the Design of Existing Code</em>, second edition. Addison-Wesley, 2018. Chapter 3, &ldquo;Bad Smells in Code&rdquo;: <em>Global Data</em>, whose only listed cure is <em>Encapsulate Variable</em>.</li>
<li id="ref-2">Erich Gamma, Richard Helm, Ralph Johnson and John Vlissides. <em>Design Patterns: Elements of Reusable Object-Oriented Software</em>. Addison-Wesley, 1994. Singleton: &ldquo;Ensure a class only has one instance, and provide a global point of access to it.&rdquo;</li>
<li id="ref-3">Martin Fowler. &ldquo;Inversion of Control Containers and the Dependency Injection pattern&rdquo;. 2004. <a href="https://martinfowler.com/articles/injection.html">https://martinfowler.com/articles/injection.html</a></li>
<li id="ref-4">Mi&scaron;ko Hevery. &ldquo;Root Cause of Singletons&rdquo;. Google Testing Blog, 27 August 2008. &ldquo;Singletons are global state in sheep's clothing&rdquo;; &ldquo;The moment you traverse a global variable your API lies about its true dependencies.&rdquo; <a href="https://testing.googleblog.com/2008/08/root-cause-of-singletons.html">https://testing.googleblog.com/2008/08/root-cause-of-singletons.html</a></li>
<li id="ref-5">John Launchbury and Simon L. Peyton Jones. &ldquo;State in Haskell&rdquo;. <em>LISP and Symbolic Computation</em> 8(4):293&ndash;341, 1995. <a href="https://doi.org/10.1007/BF01018827">https://doi.org/10.1007/BF01018827</a></li>
<li id="ref-6">Thomas Johnsson. &ldquo;Lambda Lifting: Transforming Programs to Recursive Equations&rdquo;. In <em>Functional Programming Languages and Computer Architecture (FPCA 1985)</em>, LNCS 201, pp. 190&ndash;203. Springer, 1985. <a href="https://doi.org/10.1007/3-540-15975-4_37">https://doi.org/10.1007/3-540-15975-4_37</a></li>
<li id="ref-7">Olivier Danvy and Ulrik P. Schultz. &ldquo;Lambda-dropping: transforming recursive equations into programs with block structure&rdquo;. <em>Theoretical Computer Science</em> 248(1&ndash;2):243&ndash;287, 2000. <a href="https://www.sciencedirect.com/science/article/pii/S0304397500000542">https://www.sciencedirect.com/science/article/pii/S0304397500000542</a></li>
<li id="ref-8">Mark P. Jones. &ldquo;Functional Programming with Overloading and Higher-Order Polymorphism&rdquo;. In <em>Advanced Functional Programming (AFP 1995)</em>, LNCS 925, pp. 97&ndash;136. Springer, 1995. Reader monads as &ldquo;computations that consult some fixed environment&rdquo;; <code>ReaderT</code>. <a href="https://doi.org/10.1007/3-540-59451-5_4">https://doi.org/10.1007/3-540-59451-5_4</a></li>
<li id="ref-9">Koen Claessen and John Hughes. &ldquo;QuickCheck: a lightweight tool for random testing of Haskell programs&rdquo;. In <em>Proceedings of the ACM SIGPLAN International Conference on Functional Programming (ICFP 2000)</em>, pp. 268&ndash;279. <a href="https://doi.org/10.1145/351240.351266">https://doi.org/10.1145/351240.351266</a></li>
<li id="ref-10">Hedgehog for Scala. <a href="https://github.com/hedgehogqa/scala-hedgehog">https://github.com/hedgehogqa/scala-hedgehog</a></li>
<li id="ref-11">Hedgehog for Haskell. <a href="https://github.com/hedgehogqa/haskell-hedgehog">https://github.com/hedgehogqa/haskell-hedgehog</a></li>
</ol>
