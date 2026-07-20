---
layout: page
title: Libraries
subtitle: Open engineering output from the practice
permalink: /libraries/
bootstrap: true
tags: libraries
---

These are the libraries Constructive Programming has built in the open
— code that puts the methodology into production, and the research
artefacts that justify the methodology in the first place. Each one is
independently versioned at
[github.com/Constructive-Programming](https://github.com/Constructive-Programming).

{% include libraries.html %}

[**cats-eo**](https://eo.constructive.dev/) is the flagship: an
existential-optics library for Scala 3 with discipline-checked laws,
JMH benchmarks against Monocle, and circe + avro integrations. It is
what we reach for when a client needs the same lens to work over an
in-memory record, a JSON byte buffer, and an Avro wire payload — and
when they need that lens to keep its laws under change.

[**scala-cardinality**](https://github.com/Constructive-Programming/scala-cardinality)
is the research artefact behind the *Total Program Cardinality* thesis
— the metric that counts the inhabitants of an ADT and informs the
*narrowing* work we do on client codebases.
[**surreals**](https://github.com/Constructive-Programming/surreals)
is an algebraic exploration of Conway's surreal numbers using cats
algebra and droste recursion schemes; it is the proving ground for
the recursion-scheme techniques that show up later in production
pipelines.

The home page introduces another, longer-running output:
[**Fixed**]({{ '/#fixed' | relative_url }}) — a new functional
language being designed around the same constructive principles. Phase 0
of that design is in flight; the implementation will follow.

## Working with us

If your team is putting optics, effects, or typed-FP into production,
or moving toward agent-native development with constructive guardrails,
[book a 30-minute scoping call](https://cal.constructive.dev/rhansen)
or email
[consulting@constructive.dev](mailto:consulting@constructive.dev?subject=Scoping%20call).
The libraries above are the ground we stand on; the [consulting offer]({{ '/#consulting' | relative_url }})
is how we bring it to your codebase.
