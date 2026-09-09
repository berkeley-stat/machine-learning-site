---
name: person-lookup
description: Look up a real person's current position, title, or affiliation before writing it into a file — alumni-card, student-card, faculty/postdoc cards, bios, acknowledgements, anything published. Use whenever a card field is unknown or may be stale, whenever the user says "look it up online," and before writing any biographical claim about a named person. Enforces primary-source verification, hiring-side search, and leaving a field blank rather than guessing.
---

# Looking up where someone ended up

Facts about real people go onto a public website under the lab's name. A wrong
employer is a real-world error about a real person, and it outlives the chat
where you hedged about it.

## The one rule

**A search-engine summary is not a source.** WebSearch returns two things: a list
of links, and a synthesized paragraph. Only the links are evidence. Open the page
and read it before any fact from it reaches a file.

The synthesized paragraph is generated from snippets and cheerfully conflates
people with similar names. It states everything in the same confident voice
whether it is quoting a directory page or inventing.

## Source tiers

**Tier 1 — publishable on its own, once you have actually fetched the page:**
- The hiring institution's own directory page (`stat.cornell.edu/people/first-last`)
- An official announcement from that institution ("Bowers welcomes 13 new faculty")
- The person's own site or CV, *if* it reflects the new status

**Tier 2 — needs a Tier 1 to confirm the employer name:**
- The granting department's alumni/placement page, dissertation records
- LinkedIn, ResearchGate, Google Scholar affiliations
- Conference/seminar bios

**Tier 0 — never write this into a file:**
- The WebSearch answer paragraph
- Anything you cannot point to a specific fetched URL for

## Search the hiring side, not just the person

Academic placements are usually announced by the institution doing the hiring,
not by the person. The person's own site is often a year stale. So:

- Guess the directory URL directly: `<dept>.<school>.edu/people/<first>-<last>`
- `"<full name>" assistant professor` / `"<full name>" joins` / `"<full name>" new faculty`
- `"<full name>" site:<candidate institution>`
- Department "new faculty <year>" announcement pages
- Search the name *alone* in quotes — extra terms like `postdoc` bias retrieval
  toward a story you have already half-invented

If three queries return the same synthesized paragraph, the queries are the
problem. Change the target, not the wording: go looking for a directory page.

## Two rules that would have caught the miss

**Contradiction invalidates the whole source.** If a summary gets a checkable
detail wrong — advisors, degree, institution, year — discard everything else it
says. It is describing a different person, or several. Do not keep the parts you
liked. Common surnames make this frequent.

**A stale source is silent, not negative.** A personal site that still says "PhD
student" is not evidence that there is no new job. Absence of an update means the
person has not updated their site. Never reason "their CV doesn't mention it, so
this search result must be what happened."

## When it does not verify

Leave the field empty and ask the user. Do not write a plausible guess and flag
it in chat — **the caveat stays in the conversation, the guess ships in the
file.** If you would need a sentence of hedging next to it, it does not go in.

## Before writing the line

- [ ] I fetched a Tier 1 page, or two independent Tier 2 sources agreeing on the employer
- [ ] I can name the URL each field came from
- [ ] Nothing in those sources contradicted a detail I could check
- [ ] Title and institution are quoted from the source, not paraphrased from memory
- [ ] Start date noted — a future start ("beginning summer 2027") may change the wording
- [ ] Formatting matches the neighbouring cards in the same file

## Site-specific

Cards live in `contents/*.qmd`. Position wording follows the existing pattern:
`Assistant Professor of Statistics @ University of Toronto`,
`Research Scientist @ BlackRock AI Lab`.

A person graduating out of `students.qmd` or `postdocs.qmd` gets **moved**, not
copied — every other alum appears in exactly one file. Headshots resolve
automatically from the name via `images/firstname_lastname.*`; do not add an
`image` argument.

Sweeping the whole roster rather than checking one person? Use
`roster-maintenance` — it covers the search order that stops you concluding
"no personal website exists" when the link is on the advisor's group page.
