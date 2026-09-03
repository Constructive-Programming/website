---
layout: page
title: Extract method
subtitle: "Extract method: name a sub-expression, and its free variables become the parameters"
permalink: /refactorings/extract-method/
tags: [refactorings, extract-method]
---

<p class="rf-crumb"><a href="{{ '/refactorings/' | relative_url }}">← The refactoring catalogue</a> · 1 of 35</p>

Extract Method is the refactoring everyone learns first: find a region of
a method body that does one nameable thing, move it into a new method,
and replace the region with a call. Fowler's 1999 catalogue gave it that
name [1]; the second edition renamed it Extract Function, lists Inline
Function as its inverse, and rewrote the mechanics for a language without
classes [2]. The lineage is older. Griswold's 1991 thesis treated
restructuring as meaning-preserving manipulation of a program dependence
graph, with a tool holding the semantics fixed while the programmer moved
code about [4]. Opdyke's 1992 thesis gave the first full treatment of
"refactoring" for the object-oriented setting, and stated each operation
as a transformation with explicit preconditions under which behaviour is
preserved [3].

## The move

Fowler's mechanics are short: create a method named for what the region
does, copy the region into it, pass the locals the region reads as
parameters, return the locals it writes or refuse, replace the region with
the call, test [1, 2]. "Refuse" is where the preconditions live. In an
imperative language a region of statements is not a value; it is a
sequence of effects on a mutable environment. The extracted method must
see the same environment the region saw, hand back every change the rest
of the method depends on, and run exactly as often, in the same position,
as the region ran. A region that assigns two locals, or whose reads are
interleaved with writes to the same fields elsewhere, cannot be lifted
without changing the program. Fowler's advice to reduce temps first pushes
the code toward the case where extraction is safe; Opdyke's precondition
list makes the same demand formally [3]. Every automated refactoring tool
since, including Stocker's Scala refactoring library behind the Scala IDE
[15], must perform exactly this analysis.

## The functional reading

In a referentially transparent language the region is an expression, and
an expression depends only on its free variables. Extracting it means
naming it: write a definition whose parameters are the free variables of
the region and whose body is the region, then replace the region with an
application of the new name to those variables. There is no environment
to rebuild because there is no environment; the free variables are the
whole of what the expression could see, and the type checker tells you
what they are.

This is not a new idea dressed up. It is the abstraction step of Burstall
and Darlington's 1977 fold/unfold system, where a program is a set of
equations and the permitted moves are to define a new equation, to unfold
a call by replacing it with its right-hand side, and to fold a
sub-expression back into a call wherever it matches one [5]. Extract is
definition followed by fold; Inline is unfold. Johnsson's lambda lifting,
which turns nested local functions into top-level equations by adding
their free variables as parameters, is extraction pushed to the whole
program [6]; Danvy and Schultz's lambda dropping is the inverse, restoring
block structure by dropping parameters that are invariant across a call
graph back into scope [7]. Let-floating in GHC moves bindings inward or
outward for sharing and allocation, relying on the same fact that a
binding may be placed anywhere its free variables are in scope [8]. And
GHC's inliner performs the inverse of extraction thousands of times a
build, unfolding and beta-reducing wherever the result is smaller or
faster; Peyton Jones and Marlow's account of it is, read from the other
side, an account of when extraction costs nothing at runtime [9].

The Haskell Refactorer, HaRe, offers the pair as tool operations:
*introduce definition*, which names a selected sub-expression;
*generalise definition*, which turns a sub-expression into a parameter;
and *unfold*, which replaces a call with the body [10, 11]. Thompson's
Advanced Functional Programming lecture notes set these out as equations
between programs and discuss where the equations hold [12].

That is the point. With referential transparency the OO precondition does
not become easier to satisfy; it disappears, because the transformation is
an instance of the language's own equational theory. Replacing an
expression with a name bound to it is the beta rule read backwards.
Extraction stops being something you hope preserved behaviour and becomes
an equation you wrote down.

## To and from

<figure class="rf-figure">
{% include_relative extract-method/diagrams/koan.svg %}
<figcaption>The koan. One equation, read in two directions: extract
(define and fold) to the right, inline (unfold and β-reduce) to the left.
The free variables of the region <em>e</em> are exactly the parameters
of the new definition.</figcaption>
</figure>

The catalogue lists each refactoring in both directions because the two
moves are one equation read left to right and right to left. For a
definition *f* with parameters *x₁ … xₙ* and body *e*, *f a₁ … aₙ* equals
*e* with each *xᵢ* replaced by *aᵢ*, provided no *aᵢ* is captured by a
binder inside *e*. Read from application to body it is Inline: unfold,
substitute, and if the arguments were variables the result is what stood
there before. Read from body to application it is Extract: choose the
region *e*, take its free variables as the *xᵢ*, and fold.

The directions serve different ends. Extract is for naming, so a reader
sees what the region means rather than how; for reuse, so a second
occurrence becomes a second call; and for generalisation, because once the
free variables are parameters any of them can be varied and a specific
expression becomes a function over a family. Inline is for
specialisation, because unfolding at a call site with known arguments
exposes constants and structure that further rewrites can act on, and for
removing indirection that no longer earns its name. Burstall and
Darlington's system gets almost all of its power from alternating the
two: unfold to expose a pattern, apply a law, fold to recover a recursion
with a better shape [5]. A compiler's simplifier works the unfolding half
at scale [9]. The programmer works at a larger grain with a different
objective, but the moves are the same moves.

## Three examples

Each example is the same program twice, `Before` and `After`, in Scala 3
and in Haskell. The entry point keeps its name and its type, the
extraction is the only difference, and a hedgehog property generates
inputs and demands that both versions agree on every one of them. The
sources below are included verbatim from the files the tests run against.

### 1 · Order total: the textbook move

A subtotal, a percentage discount, a percentage tax. The region `amount ×
pct / 100` appears twice with different free variables, so it becomes
`percent(pct, amount)`; the line sum has no free variables beyond the
list, so it becomes `subtotal(items)`. Nothing in the region closes over
anything the new functions cannot be handed as an argument.

<figure class="rf-figure">
{% include_relative extract-method/01-order-total/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative extract-method/01-order-total/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative extract-method/01-order-total/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative extract-method/01-order-total/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative extract-method/01-order-total/After.hs %}{% endhighlight %}
</div>
</div>

Note what did *not* change: `net` is still bound once, so `subtotal` is
still computed once. Extracting a function and then calling it twice
would have been a second, different refactoring.

<details class="rf-spec">
<summary>The property: <code>Before.total == After.total</code> on generated orders</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative extract-method/01-order-total/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative extract-method/01-order-total/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

### 2 · Running balance: the region closes over locals

The fold's step function reads `limit` and `fee`, which are parameters of
`settle` and not in scope at the top level. Extracting it means those free
variables become leading parameters: `step(limit, fee)` is partially
applied to give the fold exactly the two-argument function it wants. This
is Johnsson's lambda lifting done by hand [6], and HaRe's *generalise
definition* [10].

<figure class="rf-figure">
{% include_relative extract-method/02-running-balance/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative extract-method/02-running-balance/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative extract-method/02-running-balance/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative extract-method/02-running-balance/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative extract-method/02-running-balance/After.hs %}{% endhighlight %}
</div>
</div>

The lifted `step` is now a value in its own right, and the second
property says what it is: `settle` over a single transaction. That is the
generalisation payoff of the extract direction. Reading the equation the
other way, dropping `limit` and `fee` back into a local `where` is
Danvy and Schultz's lambda dropping [7].

<details class="rf-spec">
<summary>The property: <code>Before.settle == After.settle</code>, and <code>step</code> is a one-transaction <code>settle</code></summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative extract-method/02-running-balance/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative extract-method/02-running-balance/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

### 3 · Expression evaluator: extraction inside a recursive match

Three cases of a recursive evaluator share a shape: evaluate the left
operand, then the right, then combine, with division by zero yielding no
value rather than an exception. The shape becomes `binary`, parameterised
by the combining operation. The one design decision is that `binary`
takes the operands *unevaluated*: hand it `eval(l)` and `eval(r)` instead
and Scala would evaluate the right operand even when the left one has no
value, which `Before` never did. In Haskell the same choice keeps the
short-circuit exact under laziness, and the second property checks it by
putting `undefined` in the right operand. One partiality survives on both
sides: Haskell's `div` still overflows at `minBound` divided by `-1`. The
refactoring preserves that; it does not fix it, and the property confirms
that both versions throw on the same input.

<figure class="rf-figure">
{% include_relative extract-method/03-expression-eval/diagram.svg %}
</figure>

<div class="rf-pair">
<div><h4>Before · Scala</h4>
{% highlight scala %}{% include_relative extract-method/03-expression-eval/Before.scala %}{% endhighlight %}
</div>
<div><h4>Before · Haskell</h4>
{% highlight haskell %}{% include_relative extract-method/03-expression-eval/Before.hs %}{% endhighlight %}
</div>
</div>

<div class="rf-pair">
<div><h4>After · Scala</h4>
{% highlight scala %}{% include_relative extract-method/03-expression-eval/After.scala %}{% endhighlight %}
</div>
<div><h4>After · Haskell</h4>
{% highlight haskell %}{% include_relative extract-method/03-expression-eval/After.hs %}{% endhighlight %}
</div>
</div>

<details class="rf-spec">
<summary>The property: <code>Before.eval == After.eval</code> on generated trees, and the short-circuit survives</summary>
<div class="rf-pair">
<div><h4>Spec · Scala</h4>
{% highlight scala %}{% include_relative extract-method/03-expression-eval/Spec.scala %}{% endhighlight %}
</div>
<div><h4>Spec · Haskell</h4>
{% highlight haskell %}{% include_relative extract-method/03-expression-eval/Spec.hs %}{% endhighlight %}
</div>
</div>
</details>

## When it is not an equivalence

The equation has hypotheses, and each is one of the constructive
criteria. Where a hypothesis fails, extraction changes the program.

- **Side effects and evaluation order.** If the region performs effects,
  moving it into a definition can change when and how often they happen.
  This is the OO precondition, and the only one imperative languages need
  because it subsumes the rest. In Scala a `def` is re-evaluated at each
  call and a `val` once, so extracting an effectful expression into a
  `def` can multiply effects, and into a `val` can move them to
  initialisation.
- **Sharing and evaluation count.** In a pure language the value is the
  same but the work may not be. A Scala `def` recomputes; a `val` shares.
  In Haskell a `let`-bound expression is evaluated at most once per
  binding, a top-level constant applicative form is shared for the
  program's lifetime, and a function body is recomputed per call unless
  full laziness floats it out [8]. Extraction can change space and time,
  including turning a bounded computation into a leak, without changing
  the result.
- **Strictness.** A definition that pattern-matches on a parameter forces
  it when applied, even if the original expression only used it in a
  branch not taken. Extraction can introduce a force and inlining remove
  one; where the argument is bottom the two programs differ. Totality, no
  `undefined` and no partial functions, is exactly the condition under
  which this cannot arise. Example 3 is built around this.
- **Exceptions and non-termination.** An expression that throws or
  diverges is a value only in a language that models those outcomes as
  values. If the region can throw and the call site evaluates it in a
  different order, the exception observed changes; if it can diverge, the
  strictness argument applies. Termination removes the second case, total
  error handling the first.
- **Name capture.** Substituting the body for the call, or lifting the
  region past a binder, must not let a free variable of the region be
  captured by an inner binding of the same name. Tools rename; by hand
  this is the commonest way to make Inline wrong. A type checker catches
  most captures, since a captured variable usually has the wrong type,
  but not all.

In each case the fix is the same: restore the hypothesis, by making the
region pure, total and terminating and by renaming, or admit that this is
not a refactoring and test it as a change.

## Checking it

Because extraction is an equation, its correctness is a property: for all
inputs *x* in the domain of the entry point, `Before x == After x`. That is
a one-line property in the sense Claessen and Hughes introduced with
QuickCheck, where a generator produces inputs and the framework searches
for a counterexample and shrinks it to a minimal one [13]. The catalogue
states every entry this way, in Scala and in Haskell, with hedgehog on
both sides [14]. Hedgehog is used because its shrinking is integrated
into the generator, so a shrunk counterexample obeys the same invariants
as a generated one and the minimal failing input it reports is a real
input of the program, not an artefact of a separate shrinker.

A property is only worth having if it can fail, so each spec above was
mutation-checked: change `After` so it is no longer equivalent, by
dropping a parameter, altering a boundary or reordering a match, confirm
the property reports and shrinks a counterexample, then restore `After`.
A property that does not fail under mutation is testing the generator,
not the refactoring.

To run everything on this page yourself, from a checkout of
[the site repository](https://github.com/Constructive-Programming/website):

```sh
sh pages/refactorings/extract-method/run.sh
```

It needs [scala-cli](https://scala-cli.virtuslab.org/) and either GHC
with hedgehog installed or Docker, and ends with `all properties passed`.

## References

1. Martin Fowler, with contributions by Kent Beck, John Brant, William Opdyke and Don Roberts. *Refactoring: Improving the Design of Existing Code*. Addison-Wesley, 1999. <https://martinfowler.com/books/refactoring.html>
2. Martin Fowler. *Refactoring: Improving the Design of Existing Code*, second edition. Addison-Wesley, 2018. Catalogue entry "Extract Function" (formerly Extract Method; inverse of Inline Function). <https://refactoring.com/catalog/extractFunction.html>
3. William F. Opdyke. *Refactoring Object-Oriented Frameworks*. PhD thesis, University of Illinois at Urbana-Champaign, 1992 (Tech. Report UIUCDCS-R-92-1759). <https://www.laputan.org/pub/papers/opdyke-thesis.pdf>
4. William G. Griswold. *Program Restructuring as an Aid to Software Maintenance*. PhD thesis, University of Washington, 1991. Technical report 91-08-04. <https://cseweb.ucsd.edu/~wgg/Abstracts/gristhesis.pdf>
5. R. M. Burstall and John Darlington. "A Transformation System for Developing Recursive Programs". *Journal of the ACM* 24(1):44–67, 1977. <https://doi.org/10.1145/321992.321996>
6. Thomas Johnsson. "Lambda Lifting: Transforming Programs to Recursive Equations". In *Functional Programming Languages and Computer Architecture (FPCA 1985)*, LNCS 201, pp. 190–203. Springer, 1985. <https://doi.org/10.1007/3-540-15975-4_37>
7. Olivier Danvy and Ulrik P. Schultz. "Lambda-dropping: transforming recursive equations into programs with block structure". *Theoretical Computer Science* 248(1–2):243–287, 2000. <https://www.sciencedirect.com/science/article/pii/S0304397500000542>
8. Simon Peyton Jones, Will Partain and André Santos. "Let-floating: moving bindings to give faster programs". In *Proceedings of the ACM SIGPLAN International Conference on Functional Programming (ICFP 1996)*, pp. 1–12. <https://doi.org/10.1145/232627.232630>
9. Simon Peyton Jones and Simon Marlow. "Secrets of the Glasgow Haskell Compiler inliner". *Journal of Functional Programming* 12(4–5):393–434, 2002. <https://doi.org/10.1017/S0956796802004331>
10. Huiqing Li, Claus Reinke and Simon Thompson. "Tool support for refactoring functional programs". In *Proceedings of the ACM SIGPLAN Workshop on Haskell (Haskell 2003)*, pp. 27–38. <https://doi.org/10.1145/871895.871899>
11. Huiqing Li, Simon Thompson and Claus Reinke. "The Haskell Refactorer, HaRe, and its API". *Electronic Notes in Theoretical Computer Science* 141(4):29–34, 2005 (LDTA 2005). <https://doi.org/10.1016/j.entcs.2005.02.053>
12. Simon Thompson. "Refactoring Functional Programs". In *Advanced Functional Programming (AFP 2004), Revised Lectures*, LNCS 3622, pp. 331–357. Springer, 2005. <https://doi.org/10.1007/11546382_9>
13. Koen Claessen and John Hughes. "QuickCheck: a lightweight tool for random testing of Haskell programs". In *Proceedings of the ACM SIGPLAN International Conference on Functional Programming (ICFP 2000)*, pp. 268–279. <https://doi.org/10.1145/351240.351266>
14. Jacob Stanley and contributors. *Hedgehog: release with confidence, state-of-the-art property testing*. <https://github.com/hedgehogqa/haskell-hedgehog> and <https://github.com/hedgehogqa/scala-hedgehog>
15. Mirko Stocker. *Scala Refactoring*. Master's thesis, HSR Hochschule für Technik Rapperswil, 2010. <https://eprints.ost.ch/id/eprint/286/>
