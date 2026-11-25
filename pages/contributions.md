---
layout: page
title: Contributions
subtitle: Open-source contributions from the practice
permalink: /contributions/
bootstrap: true
tags: libraries
---

**Everything here is open source.** These are Constructive Programming's
open-source contributions: libraries that put the methodology into
production, and the research artefacts that justify it in the first
place. Each one is free to use, independently versioned, and developed
in public at
[github.com/Constructive-Programming](https://github.com/Constructive-Programming).

{% include libraries.html %}

[**eo**](https://eo.constructive.dev/) is the flagship: an
existential-optics library for Scala 3 with discipline-checked laws,
JMH benchmarks against Monocle, and circe + avro integrations. It is
what we reach for when a client needs the same lens to work over an
in-memory record, a JSON byte buffer, and an Avro wire payload — and
when they need that lens to keep its laws under change.

[**cardinality**](https://cardinality.constructive.dev/)
is the research artefact behind the *Total Program Cardinality* thesis
— the metric that counts the inhabitants of an ADT and informs the
*narrowing* work we do on client codebases. Now under active
development, it keeps surprising us: it puts an actual number behind
YAGNI, it found a `flatTraverse` we had missed, our ScalaCheck suites
run much faster, and it roots out primitive obsession and string-based
programming.
[**surreals**](https://github.com/Constructive-Programming/surreals)
is an algebraic exploration of Conway's surreal numbers using cats
algebra and droste recursion schemes; it is the proving ground for
the recursion-scheme techniques that show up later in production
pipelines.

[**rivoli**](https://rivoli.constructive.dev/) is a research
artefact: a 744B mixture-of-experts decode engine running on a single
128 GB APU, where every milestone is gated on a measured number.

[**Fixed**](https://fixed.constructive.dev/) is the longest-running
output: a new functional language for multi-million-line codebases,
designed around the same constructive principles and for development
alongside coding agents. Phase 0 — design — is in flight; the
implementation will follow.

## Working with us

If your team is putting optics, effects, or typed-FP into production,
or moving toward agent-native development with constructive guardrails,
[book a 30-minute scoping call](https://cal.constructive.dev/rhansen)
or email
[consulting@constructive.dev](mailto:consulting@constructive.dev?subject=Scoping%20call).
The libraries above are the ground we stand on; the
[consulting offer]({{ '/#consulting' | relative_url }}) is how we
bring it to your codebase.
