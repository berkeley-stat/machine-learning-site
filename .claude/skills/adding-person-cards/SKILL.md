---
name: adding-person-cards
description: Add one or more new people to the roster end to end — write the student/postdoc/faculty/alumni card AND source, crop, and install their headshot. Use whenever someone is joining the group ("I have four new postdocs", "add X as a new student", "Bin Yu sent a list"), when moving someone to alumni, or when a card is stuck on the bear placeholder. Covers card field conventions, the headshot source order, the Drupal and SPA download tricks, and the Windows crop pipeline. For auditing everyone at once use roster-maintenance; for verifying a single fact use person-lookup.
---

# Adding a new person card

A new card is two deliverables, and the second one is the one that gets
forgotten: the card fields, and the headshot. A card added without a headshot
renders the Berkeley bear, so "I added the card" is only half done. Do both in
the same visit.

`person-lookup` governs whether a fact is safe to write. `roster-maintenance`
covers sweeping all ~80 people. This skill is the per-person mechanics.

## Trust order when a request comes from the advisor

An advisor emailing "I have four new postdocs" outranks their own group page —
the page is usually months stale and will not list the new people at all. But
the advisor is **not** the authority on spelling. Observed in one email: three
of the four names needed correcting against institutional sources.

Order of authority, per field:

| Field | Authority |
|---|---|
| Exists / joined / who advises them | The advisor's email or their group page |
| Name spelling | Person's own domain > hosting institute roster > dept directory > the email |
| Department / affil | Dept directory or hosting institute roster |
| Where an alum went | Hiring institution only — see `person-lookup` |

If the email says "Katerine" and the Simons roster says "Katherine", the roster
wins. Say so in the summary rather than silently changing it.

**Resolve nearest-antecedent ambiguity before writing.** "A, B, C, and D
(jointly with Bartlett and housed at Simons)" may scope the parenthetical to D
alone or to all four. One fetch of the hosting institute's roster settles it —
do not guess from grammar.

## Card fields

Cards live in `contents/{faculty,postdocs,students,alumni}.qmd`. Postdocs use
`student-card`, not a postdoc-specific shortcode.

- **Multiple advisors** are joined by this exact separator, and ordered
  **alphabetically by last name** (`Elizabeth Purdom` before `Bin Yu`):

  ```
  advisors = "Peter Bartlett<br style='display: block; margin-bottom: -0.5em; content:'';'>Bin Yu"
  ```

- **`affil` vocabulary** — reuse an existing string, do not coin one:
  `PhD, Stats` · `PhD, EECS` · `PhD, Math` · `PhD, Biostat` · `PhD, CPH` ·
  `PhD, CCB` · `Postdoc, Stats` · `Postdoc, Simons` · `Postdoc, EECS` ·
  `Postdoc, LBNL` · `Postdoc, Stats / LBNL`

  Berkeley **CS** PhD students are `PhD, EECS`. `CPH` is Computational
  Precision Health, **not** Public Health — Biostatistics is `PhD, Biostat`.

- **`url = ""`** when no personal site exists. Leave it empty rather than
  linking a directory profile or a Google Scholar page.

- **File position**: insert in last-name order to match the file, even though
  `person-sort.lua` re-sorts at render. `Sanchez` precedes `Sandoval`;
  `Netzorg` precedes `Nguyen`.

- **Never pass `image = "..."`** — headshots resolve from the name.

- **Moving someone to alumni** is a *move*, not a copy: delete the
  student/postdoc card, add an `alumni-card` with `year` (`PhD EECS 2026`,
  `Postdoc 2026`) and `position`. Their headshot already exists and keeps
  working; the slug is unchanged.

## Headshots

`find_image` in `_extensions/person-card/resize-image.lua` tries
`images-resized/<slug>.jpg` **first**, then `images/<slug>.{jpg,jpeg,png,...}`,
then the bear. The slug comes from `person-sort.lua`'s `slug()`: accent-folded,
lowercased, every non-alphanumeric run collapsed to one `_`
(`Aaron J. Li` → `aaron_j_li`, `João Vitor Romano` → `joao_vitor_romano`).
Never hand-slugify — read the function.

### Source order

1. **Their own site.** Grep for `<img>` and take the profile image.
2. **Advisor's group page.** Often has a `photos/<firstname>.jpg` convention —
   Tibshirani's group page yielded `photos/xueda.jpg` for a student with no site
   at all.
3. **Department directory** (Drupal — see below).
4. **Hosting institute**: Simons, ICSI, LBNL. For a Simons postdoc the research
   pod page lists the whole cohort, and each profile carries a photo.

LinkedIn is a dead end — HTTP 999 or an auth wall, no reachable `licdn` URLs.
Do not keep trying it.

### Drupal directories: two paths, try both

The documented trick is to strip the image-style prefix for the full-res
original:

```
/sites/default/files/styles/crop_person/public/students/X.jpg?h=…&itok=…
   → /sites/default/files/students/X.jpg
```

That works on `statistics.berkeley.edu`. It **404s on Simons**, whose originals
are not under `files/profiles/`. When stripping fails, request the styled URL
**with its `?h=…&itok=…` token intact** (decode `&amp;` → `&` first) — Simons's
`post_card_lg_2x` style returns a 1200×1200 JPEG, which is ample. A 232-byte
"JPEG" is an HTML 404 page; check `file` output, not just exit status.

### A personal site with no `<img>` is not a site with no photo

Modern academic sites are often JS SPAs whose HTML is a shell. Look in the
bundle:

```sh
curl -s "$site/assets/index-XXXX.js" | grep -oE '"[^"]*\.(jpg|jpeg|png|webp)"' | sort -u
```

That is how `Edoardo-Calvello-Professional-copy-BzCamwA1.jpg` turned up on a
site whose homepage HTML contained exactly one word. Conversely, a Cargo/
portfolio site may have dozens of `.jpg` paths that are all *project* images and
no headshot — enumerate before concluding either way.

### Crop, then look at it

`resize-image.lua` shells out to `sips` (macOS-only); ImageMagick is not
installed here either. On Windows the filter silently falls back to the
unprocessed original — that is the `The system cannot find the path specified`
line in every render, and it is not an error you introduced. Generate the
derivative yourself with `scripts/crop-headshot.ps1`:

```powershell
& .claude/skills/adding-person-cards/scripts/crop-headshot.ps1 `
    -In img/nicolas_sanchez.jpg -Out crop/nicolas_sanchez.jpg -OffsetYFrac 0.10
```

Write **both** files:

- `images/<slug>.<ext>` — the original as downloaded
- `images-resized/<slug>.jpg` — 400×400, committed, because CI reuses it

**View every crop at 400×400 with the Read tool before installing it.** The
centre crop is unforgiving. A tall portrait with the head near the top gets its
forehead sliced off — `-OffsetYFrac 0.10` fixes that and is the common case.
A wide landscape shot with the subject off to one side becomes a photo of
scenery.

Judge by the pixels, not the filename: `rocks.png` was a perfectly good
portrait. And check *what kind of image* it is — one profile image turned out to
be a cartoon avatar, which is that person's genuine choice on their own site but
is not a photograph and does not match a roster of headshots. Surface that to
the user instead of quietly installing it.

### When there is no photo

Leave the bear and say who is missing and which sources you tried. Common
genuine dead ends: a brand-new student with no web presence yet; anyone whose
only route was `people.eecs.berkeley.edu`, which has an ongoing outage that
302s every `~user` path to `iris.eecs.berkeley.edu` and then 404s.

Never install a photo for someone whose identity you could not confirm. If
search results contradict a checkable detail — a "PhD CS 2026" alum surfacing as
a Stanford ICME person — that is a different person or several, and a wrong face
on a public roster is worse than the bear.

## Before reporting done

- [ ] Name spelling checked against a source that outranks the requester
- [ ] `affil` reuses an existing string; advisors alphabetical with the exact separator
- [ ] Card inserted in last-name position; no `image =` argument
- [ ] Every crop viewed at 400×400 and confirmed to be that person
- [ ] Both `images/` and `images-resized/` written
- [ ] Site re-rendered and the placeholder list re-derived from the built HTML
- [ ] Every new `url` returns 200 (`curl -o /dev/null -w '%{http_code}'`)
- [ ] Anyone left on the bear named, with the sources tried
