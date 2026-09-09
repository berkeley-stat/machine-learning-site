---
name: roster-maintenance
description: Audit or update the whole people roster at once — sweeping faculty/postdocs/students/alumni cards for stale entries, filling in missing personal-site URLs, or adding missing headshots. Use for "check everyone", "find out-of-date cards", "add their websites", "get photos for people who don't have one". Covers the roster-first search order, where a student's personal URL actually lives, and the Windows image pipeline. For verifying one person's title before writing it, use person-lookup instead.
---

# Maintaining the people roster

`person-lookup` governs whether a *fact* about one person is safe to write. This
skill is about doing it for ~80 people without missing things — which is a
different problem, and the failures are different.

## Do the roster sweep before touching individuals

Individual name searches are the slowest and least reliable tool available. Group
and directory pages resolve many people in one fetch and are more accurate.
Sweep these first, then chase only the residual:

| Page | What it settles |
|---|---|
| Advisor's own group page (`~mmahoney/`, `~songmei/group.html`) | **Personal site URLs**, join/leave years, "onto \<employer\>" |
| `statistics.berkeley.edu/people/{faculty,postdocs,students/phd}` | Who is still on the books; **headshots**; name spellings |
| The rendered site itself (`_site/contents/*.html`) | Who is actually missing a photo |

One fetch of Mahoney's group page resolved six postdoc URLs, corrected two name
spellings, and surfaced a departure that eight individual web searches had missed.

## A student's personal URL lives on their advisor's page, not in a search index

This is the single highest-value habit here. Personal academic sites have almost
no inbound links and rank terribly; searching `"<name>" website homepage` returns
Google Scholar, ResearchGate, and LinkedIn, and you will conclude — wrongly —
that no site exists.

Before writing off anyone's URL, fetch their advisor's group page and grep for
the surname. Extract every member link in one pass:

```sh
sed -e 's/<a href="/\n@@LINK@@/g' page.html \
  | grep -oE '@@LINK@@[^"]+"[^>]*>[^<]+</a>[^<]*\((postdoc|grad|student)[^)]*\)'
```

The parenthetical annotation is a bonus: `(postdoc, UC Berkeley / ICSI,
2022-2026; onto ZGC AI)` is a departure *and* a destination in one line.

## "My search didn't find it" is not "it does not exist"

`person-lookup` says a stale source is silent, not negative. The sibling rule:
**absence of search results is a fact about your query, not about the world.**
Report it as "no site found via X, Y, Z" and name what you tried, so the gap is
auditable rather than sounding settled.

Before declaring a URL dead, test the variants — with and without trailing
slash, `www`, `http` vs `https`. A GitHub user page can 404 while that user's
project pages (`ameli.github.io/freealg/`) serve fine; that means the account is
real and the personal site is not.

## Chase past tense to resolution

A person's own page saying "I **was** a postdoc working with…" is a departure
signal, not an ambiguity to note and move past. Filing it as "current position
unclear" and moving on is how a stale card survives an audit. Resolve it the
same visit: check the advisor's page for the leave year and destination.

If the person's page and the advisor's page disagree on *where they went*, that
is a `person-lookup` contradiction — write neither destination, and say so.

## Directory staleness is directional

Institutional directories lag on status but not on existence:

- **Trust** them for: does this person exist here, name spelling, headshot.
- **Distrust** them for: current title, still-enrolled, promotions.

Observed: the Statistics directory still listed three graduated students as
current PhDs, and listed a full Associate Professor as Assistant — while its
photos and spellings were correct throughout.

## Name spellings

A card misspelling usually came from somewhere. When two independent pages share
the *same* odd spelling ("Max Meinichenko" on both this site and the advisor's
page), you have found the copy source, not a confirmation. The authorities, in
order: the person's own domain (`maksimmelnichenko.com`), their email local-part
(`mmelnich@`), the department directory. Fix the card and mention the upstream
page is wrong too.

## Headshots

**Find who is missing one from the rendered HTML, never by guessing slugs.**
`person-sort.lua`'s `slug()` folds accents (`João` → `joao`), and hand-rolled
bash slugification gets this wrong:

```sh
for p in faculty postdocs students alumni; do
  grep -A3 'images-resized/stat_bear.jpg' _site/contents/$p.html \
    | grep -oE '600;[^>]*>[^<]+</span>' | sed 's/.*>\([^<]*\)<.*/  \1/'
done
```

**Source order:** the person's own site → their advisor's group page → the
department directory → the hosting institute (Simons, ICSI, LBNL). LinkedIn is a
dead end — profiles return HTTP 999 or an auth wall and carry no reachable
`licdn` URLs. Do not keep trying it.

For Drupal directories, strip the image-style prefix to get the full-res
original: `/sites/default/files/styles/crop_person/public/students/X.jpg?itok=…`
→ `/sites/default/files/students/X.jpg`.

**Always view the image after cropping, at 400×400, before installing it.**
The center crop is unforgiving: a wide landscape shot with a person off to one
side becomes a photo of a hillside. Two of twelve candidates failed this way and
would have shipped as scenery. Conversely, judge by the pixels and not the
filename — `rocks.png` turned out to be a perfectly good profile photo, and its
placement inside `<div id="image">` confirmed it.

### The pipeline on Windows

`resize-image.lua` shells out to `sips`, which is macOS-only; ImageMagick is not
installed here either. So the filter silently falls back to the unprocessed
original and you must generate the derivative yourself. Write **both**:

- `images/<slug>.<ext>` — the original as downloaded
- `images-resized/<slug>.jpg` — 400×400 center-cropped JPEG, committed, because
  CI reuses it rather than reprocessing

`find_image` checks `images-resized/` **first**, so a hand-tuned crop placed
there overrides the naive center crop — that is the supported way to fix a
subject who sits off-centre.

A working PowerShell equivalent of the `sips` crop (System.Drawing,
`HighQualityBicubic`, quality 90) is what to reach for; parameterise the crop
rect so an off-centre subject can be framed by hand.

Bash `/tmp` maps to `%TEMP%`, which the Read tool cannot open by that path — run
`cygpath -w` (or `pwd -W`) and Read the Windows path when viewing downloads.

## Before reporting done

- [ ] Advisor group pages swept, not just per-person searches
- [ ] Every "not found" names the sources actually tried
- [ ] Every past-tense bio chased to a leave year or an explicit contradiction
- [ ] Every installed image viewed at 400×400 and confirmed to be that person
- [ ] Both `images/` and `images-resized/` written
- [ ] Site re-rendered; placeholder list re-derived from the built HTML
- [ ] All card URLs return 200/301/302 (`curl -o /dev/null -w '%{http_code}'`)
