---
layout: page
title: About
subtitle: The methodology and the team
permalink: /about/
tags: about
---

## The methodology

**Constructive Programming** is a methodology for building complex software,
inspired by constructive logic. It leverages the Curry–Howard–Lambek
correspondence to scale software that is formally verifiable from the way
it is written.

In practice, it is about the restrictions you impose on your code to make
it easier to understand, maintain, and evolve. There are three starting
criteria:

- **Referential Transparency** — the same input always yields the same output.
- **Totality** — every defined input produces a defined output.
- **Termination** — every computation eventually finishes.

The methodology is the lens through which we read code, design APIs, and
prepare a codebase to be co-piloted by LLMs. The
[Libraries]({{ '/libraries/' | relative_url }}) page lists the OSS that
puts the methodology into Scala practice, and the home page introduces
[Fixed](https://github.com/Constructive-Programming/fixed) — a new
language being designed around the same principles.

## The team

### Rodolfo Hansen — Head of Construction

Rodolfo founded Constructive Programming and currently leads the practice.
He's been writing software professionally for more than two decades —
across Scala, Rust, Haskell, Kotlin, JavaScript, and a number of paradigms
— and has been a CTO, a founder, an engineering manager, and an IC at
nearly every team scale below "100 engineers." He is currently the main
engineer behind the [cats-eo](https://eo.constructive.dev/) library and
is designing the new research language
[Fixed](https://github.com/Constructive-Programming/fixed), based in the
Netherlands, where he operates this consulting firm.

Earlier he was a **Global Software Quality &amp; Craftsmanship Expert at
Royal Philips**, developing static-analysis metrics around *Total Program
Cardinality* and driving software-craftsmanship practice across Europe.
Before that, he was a **Software Development Manager at Otravo**
(Amsterdam) — three teams under his lead, machine-learning shipped to
production, a core loading pipeline taken from eleven hours down to
fifteen minutes, defect reports cut by a third. He was **CTO of Bodireel**
(London), a health-and-fitness platform built on a stateless RESTful Scala
backend with Angular and Xamarin clients — 100% uptime, P95 under 20 ms,
and a 30% reduction in infrastructure cost.

His career as a builder of teams started in 2008 when he founded
**KindleIT Software Development** in Santo Domingo. Over the next eight
years his team shipped widely-used open-source infrastructure (the first
App Engine Maven plugin), maintained an international client base, and
kept turnover under 5% before he sold the company.

The thread through all of it: small, accountable, distributed teams
delivering at web scale and web speed, and constantly asking what the
type system could do to make wrong programs harder to write.

**Find Rodolfo:** [LinkedIn](https://www.linkedin.com/in/rodolfohansen/) ·
[GitHub](https://github.com/kryptt) · [Medium](https://rodolfohansen.medium.com/)

#### Talks

- **Serialization &amp; De-serialization without doing either** —
  *Scala Love*, Warsaw, 2024. A novel use of polymorphic lenses, with
  code drawn from [cats-eo](https://github.com/Constructive-Programming/eo).
- **Total Program Cardinality** — *Scala Love (online)*, 2023.
  A new code-quality metric grounded in counting the inhabitants of a
  program's types.
- **Correct by Construction** — *Better, Faster, Forever (Philips
  Innovation)*, Bangalore, 2019. Introduction to constructive programming
  practices; panel on software-architecture principles.
- **Type Refinement in Scala** — *Amsterdam Scala Meetup*, 2017. Optics
  from the perspective of object-oriented design.
- **Lenses, No Mutes** — *Barcamp PUCMM*, Santiago, 2016. The same idea,
  earlier and friendlier.

Longer-form writing on these themes lives at
[rodolfohansen.medium.com](https://rodolfohansen.medium.com/).

#### Education

- **MSc, Mathematics** — Instituto Tecnológico de Santo Domingo (INTEC),
  2007\. Real Analysis, then Topology and Category Theory pursued
  independently.
- **BSc, Computer Software Engineering** — Universidad APEC, 2004\. Full
  scholarship from a national competition.

### More consultants — coming

Constructive Programming is a single-consultant practice today; we are
selectively adding senior collaborators. If you work at the intersection
of typed functional design, dependent / refinement types, and
LLM-augmented engineering, and you want to take on client work under this
banner, get in touch at
[consulting@constructive.dev](mailto:consulting@constructive.dev).

## Working with us

We work on architecture-review, fractional-advisory, embedded-IC, and
workshops/training shapes — see the [home page]({{ '/' | relative_url }}#consulting)
for the engagement bullets. We are available for select engagements;
based in the Netherlands; comfortable with EU MSAs and standard NDAs.

The fastest path is
[booking a 30-minute scoping call](https://cal.constructive.dev/rhansen)
on the calendar, or emailing
[consulting@constructive.dev](mailto:consulting@constructive.dev?subject=Scoping%20call)
to set one up.
