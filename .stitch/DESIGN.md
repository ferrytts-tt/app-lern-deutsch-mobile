# Design System: Deutsch Fast
**Project ID:** 15088049692319025477

## 1. Visual Theme & Atmosphere

Deutsch Fast is a **serene, encouraging, and purposeful** mobile learning app. The aesthetic is deliberately calm — like a well-lit study corner with natural light, not a gamified casino. The mood is: *airy minimalism with warm encouragement*. Every screen has one job. Generous breathing room prevents cognitive overload. Rounded shapes feel approachable, not corporate. The palette references nature (forest green, sky blue, golden light) to signal growth, calm, and achievement without aggression.

**Anti-patterns deliberately avoided:** No red for errors. No flashing alerts. No cluttered sidebars. No dark aggressive gamification patterns.

## 2. Color Palette & Roles

- **Forest Growth Green (#2FA866)** — Primary action color. Used for main buttons, progress fills, success states, and the primary CTA. Communicates growth and forward momentum.
- **Deep Forest Green (#1F7A4A)** — Used for pressed states, hover on green elements, and strong emphasis text over light backgrounds.
- **Mint Mist (#E6F6EC)** — Extremely light green used as progress bar backgrounds, success notification backgrounds, and subtle surface tints.
- **Sky Clarity Blue (#2F80ED)** — Information and audio-related actions. The listen/speaker button color. Links, informational tags. Signals calm focus.
- **Deep Ocean Blue (#1D5FBF)** — Pressed/active states for blue elements. Used for article gender coloring: masculine "der" words.
- **Pale Sky Blue (#E8F1FD)** — Background tint for informational sections, audio indicators.
- **Warm Sunlight Yellow (#FFC83D)** — Accent and reward color. Streak flames, achievement badges, milestone highlights, "Phrase of the Day" accents. Never used for primary actions.
- **Golden Amber (#E0A800)** — Darker yellow for text on light backgrounds, pressed yellow states, and article gender coloring: feminine "die" words.
- **Cream Glow (#FFF6D9)** — Background for yellow-accented cards and reward sections.
- **Soft Sand (#F7FAF8)** — App background. Not pure white — gently warm to reduce eye strain.
- **Pure Cloud (#FFFFFF)** — Card surfaces, modal backgrounds, input fields.
- **Ink (#1F2A37)** — Primary text. Deep charcoal, not pure black. Easier on the eyes.
- **Slate Gray (#6B7785)** — Secondary text, captions, metadata, placeholder text.
- **Pebble Border (#E3EAE6)** — Subtle dividers, card outlines, inactive tabs.
- **Soft Tangerine (#F59E4B)** — "Gentle error" color. Used ONLY for soft corrections (not failures). Background: Peach Blush (#FFF1E2).
- **Masculine Blue (#2F80ED)** — Applied to "der" article labels in German phrases.
- **Feminine Gold (#E0A800)** — Applied to "die" article labels.
- **Neuter Green (#2FA866)** — Applied to "das" article labels.

## 3. Typography Rules

**Headings — Poppins SemiBold:**
All screen titles, section headers, and milestone labels use Poppins SemiBold. Size range: 24–28px. Letter-spacing is tight (0 to -0.3px) to feel confident and compact.

**German Phrase Cards — Nunito Bold:**
The central German phrase on any card uses Nunito Bold at 26–30px. This is the hero content of the app — always centered, always large. The generous x-height of Nunito makes it very readable at speed.

**Body & UI Text — Nunito Regular:**
All translations, instructions, explanations, and interface labels use Nunito Regular at 16px. Minimum font size anywhere in the app: 14px. Line height: 1.5 for comfortable reading.

**Translation text** uses Nunito Regular at 18px in Slate Gray (#6B7785) — visually subordinate to the German phrase but still readable.

## 4. Component Stylings

**Primary Button:**
- Shape: Full pill (border-radius 28px), full screen width, height 56px.
- Background: Forest Growth Green (#2FA866).
- Text: Pure Cloud White, Nunito Bold, 16px, centered.
- Shadow: Very subtle — 0px 2px 8px rgba(47, 168, 102, 0.15).
- Pressed state: Deep Forest Green (#1F7A4A).

**Secondary Button:**
- Shape: Generously rounded (border-radius 16px), full or half width.
- Background: Pure Cloud (#FFFFFF).
- Border: 1.5px solid Pebble Border (#E3EAE6).
- Text: Deep Forest Green (#1F7A4A), Nunito SemiBold, 16px.

**Listen Button (Audio):**
- Shape: Perfect circle, 64px diameter.
- Background: Sky Clarity Blue (#2F80ED).
- Icon: White speaker/headphone icon, centered.
- Active animation: Gentle pulsing glow ring in Pale Sky Blue (#E8F1FD), 200ms ease-out.

**Microphone Button (Shadowing):**
- Shape: Perfect circle, 80px diameter.
- Background: Warm Sunlight Yellow (#FFC83D).
- Icon: Dark microphone icon (Ink #1F2A37), centered.
- Active animation: Soft breathing pulse (scale 1.0 → 1.08 → 1.0), 800ms loop.

**Cards:**
- Background: Pure Cloud (#FFFFFF).
- Corner radius: Generously rounded (20px).
- Shadow: Whisper-soft — 0px 4px 16px rgba(31, 42, 55, 0.06).
- Internal padding: 20px on all sides.
- Border: Optional 1px Pebble Border (#E3EAE6) for definition on Soft Sand background.

**Progress Bar:**
- Track background: Mint Mist (#E6F6EC).
- Fill: Forest Growth Green (#2FA866).
- Height: 10px, fully pill-shaped (border-radius 5px).
- Transition: smooth linear fill animation, 300ms.

**Bottom Navigation Bar:**
- Background: Pure Cloud (#FFFFFF).
- Border top: 1px Pebble Border (#E3EAE6).
- Active tab: Forest Growth Green (#2FA866) icon + label.
- Inactive tab: Slate Gray (#6B7785) icon + label.
- Four tabs: Accueil · Phrases · Progrès · Réglages.

**Status Pills (phrase status):**
- Nouvelle: Pale Sky Blue background (#E8F1FD), Sky Blue text (#2F80ED).
- En cours: Cream Glow (#FFF6D9), Golden Amber text (#E0A800).
- Maîtrisée: Mint Mist (#E6F6EC), Forest Green text (#2FA866).
- À surveiller: Peach Blush (#FFF1E2), Tangerine text (#F59E4B).

**Input Fields:**
- Background: Pure Cloud (#FFFFFF).
- Border: 1.5px Pebble Border (#E3EAE6).
- Border-radius: 16px, subtly rounded.
- Focus border: Sky Clarity Blue (#2F80ED), 2px.
- Text: Ink (#1F2A37), Nunito Regular 16px.

## 5. Layout Principles

**Screen margins:** 20px left and right on all screens. Never let content touch the edges.

**Vertical rhythm:** All vertical spacing is a multiple of 8px. Common spacers: 8, 16, 24, 32, 48px.

**Single focus per screen:** Each screen communicates ONE primary action. Secondary content is visually de-emphasized. The user's eye should always know what to do first.

**Card-based structure:** Content lives in floating white cards on the Soft Sand (#F7FAF8) background. This layering creates gentle depth without heavy shadows.

**Touch targets:** Every interactive element has a minimum 48px touch target. Smaller icons (like 24px icons) have invisible padding to meet this requirement.

**Hierarchy through weight and size:** Primary content is large and bold (Nunito Bold 26-30px for German phrases). Secondary content is smaller and lighter (Slate Gray 16px). Never rely solely on color to convey importance.

**Animations:** All transitions: 200–300ms, ease-out curve. Success state: small sparkle/star burst in Warm Sunlight Yellow. Error state: gentle background shift to Peach Blush (#FFF1E2). Never jarring, never punishing.
