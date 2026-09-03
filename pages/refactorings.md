---
layout: page
title: Refactorings
subtitle: The Constructive Programming refactoring catalogue
permalink: /refactorings/
tags: refactorings
---

Object-oriented developers have a shared vocabulary for reshaping code
without changing what it does — Fowler's catalogue, Opdyke's thesis, the
*Refactoring* menu in every IDE — as well as a history of doing so
informally or less structured before then. This is the same idea seen
through the functional-programming imagination: each move takes a program
from one
structure to an equivalent one, and in a referentially transparent
setting *equivalent* is something you can state and check.

Every entry that has a page shows the refactoring in **Scala 3** and in
**Haskell**, in both directions (the move and its inverse), with the
papers and study material behind it, a diagram of the structural change,
and a property-based test — [Hedgehog](https://github.com/hedgehogqa/scala-hedgehog)
in Scala and [Hedgehog](https://github.com/hedgehogqa/haskell-hedgehog) in Haskell —
that exercises the *before* and *after* on generated inputs and demands
the same answer. Entries without a link are queued; they will be filled
in the order listed.

{% for group in site.data.refactorings %}
## {{ group.group }}

<ol class="refactoring-list">
{% for item in group.items -%}
  <li>{% if item.slug %}<a href="{{ '/refactorings/' | append: item.slug | append: '/' | relative_url }}">{{ item.name }}</a>{% else %}<span class="refactoring-pending">{{ item.name }}</span>{% endif %}</li>
{% endfor -%}
</ol>
{% endfor %}
