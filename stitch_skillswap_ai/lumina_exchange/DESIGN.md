---
name: Lumina Exchange
colors:
  surface: '#f8f9ff'
  surface-dim: '#d0dbed'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e6eeff'
  surface-container-high: '#dee9fc'
  surface-container-highest: '#d9e3f6'
  on-surface: '#121c2a'
  on-surface-variant: '#3c4a42'
  inverse-surface: '#27313f'
  inverse-on-surface: '#eaf1ff'
  outline: '#6c7a71'
  outline-variant: '#bbcabf'
  surface-tint: '#006c49'
  primary: '#006c49'
  on-primary: '#ffffff'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#4edea3'
  secondary: '#006b5f'
  on-secondary: '#ffffff'
  secondary-container: '#6df5e1'
  on-secondary-container: '#006f64'
  tertiary: '#00687a'
  on-tertiary: '#ffffff'
  tertiary-container: '#00b2d0'
  on-tertiary-container: '#003f4b'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#71f8e4'
  secondary-fixed-dim: '#4fdbc8'
  on-secondary-fixed: '#00201c'
  on-secondary-fixed-variant: '#005048'
  tertiary-fixed: '#acedff'
  tertiary-fixed-dim: '#4cd7f6'
  on-tertiary-fixed: '#001f26'
  on-tertiary-fixed-variant: '#004e5c'
  background: '#f8f9ff'
  on-background: '#121c2a'
  surface-variant: '#d9e3f6'
  surface-bg: '#F9FAFB'
  surface-stroke: '#E5E7EB'
  ai-glow: 'linear-gradient(135deg, #10B981 0%, #14B8A6 50%, #06B6D4 100%)'
typography:
  headline-xl:
    fontFamily: Outfit
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Outfit
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Outfit
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
  headline-md:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 20px
  margin-desktop: 48px
  gutter: 16px
  stack-sm: 12px
  stack-md: 24px
  stack-lg: 48px
---

## Brand & Style

The design system is built for a peer-to-peer ecosystem that bridges human expertise with AI-driven discovery. The brand personality is **Intelligent, Collaborative, and Growth-oriented**, focusing on a high-trust environment where knowledge flows seamlessly.

The aesthetic follows a **Corporate / Modern** style influenced by "Stitch" principles: premium layout discipline, immense clarity, and motion-driven navigation. The UI uses a mobile-first approach, prioritizing thumb-friendly interactions and a "glanceable" information hierarchy. AI elements are integrated through subtle visual cues—soft animated gradients and "neural" iconography—rather than heavy futuristic tropes, maintaining a professional and reliable atmosphere.

## Colors

The palette is rooted in a spectrum of greens and cyans to evoke growth and technical precision. **Emerald Green** serves as the primary action color, providing a vibrant, trustworthy anchor. **Teal** and **Cyan** are utilized for secondary UI elements and AI-assisted features.

**Gradients** should be used sparingly, reserved primarily for AI touchpoints (like magic-suggested skills or search bars) and high-level progress indicators. Neutrals leverage a **Deep Navy/Charcoal** for high-contrast typography against a **Soft White** background, ensuring the interface feels airy and premium. Purple is strictly prohibited to maintain brand distinctiveness within the EdTech/AI space.

## Typography

This design system employs a dual-font strategy. **Outfit** is used for headlines to provide a modern, geometric, and friendly character that feels approachable yet professional. **Inter** is used for all body copy and UI labels to ensure maximum legibility and functional neutrality across dense data views.

Scale typography intentionally to create clear entry points. Use `headline-xl` only for major hero sections. On mobile, headlines should automatically shift to their `-mobile` variants to prevent awkward line breaks while maintaining visual impact.

## Layout & Spacing

The layout follows a **fluid grid** model with a heavy emphasis on "intelligent spacing." 
- **Mobile:** 4-column grid with 20px side margins and 16px gutters.
- **Desktop:** 12-column grid with a max-width of 1280px, centered with 48px margins.

Spacing follows an 8px base unit. Vertical rhythm is established using "stacks" to group related content. Use `stack-lg` to separate distinct sections of a profile or landing page, and `stack-sm` for internal component spacing (e.g., header to body within a card).

## Elevation & Depth

Hierarchy is conveyed through **Tonal Layers** and **Ambient Shadows**. Surfaces are primarily flat or slightly elevated to maintain a "clean" look.

- **Level 0 (Background):** Soft White (#F9FAFB).
- **Level 1 (Cards/Containers):** Pure White (#FFFFFF) with a 1px Soft Gray (#E5E7EB) border and a very soft, diffused shadow (0px 4px 20px rgba(31, 41, 55, 0.04)).
- **Level 2 (Active/Floating):** Higher elevation shadow (0px 10px 30px rgba(31, 41, 55, 0.08)) used for modals and active cards.

Avoid heavy shadows; the goal is for elements to feel "placed" rather than "floating" high above the surface. Use subtle motion—slight vertical shifts on hover—to reinforce the feeling of depth.

## Shapes

The shape language is defined by significant **roundedness** to feel friendly and modern. 
- **Standard Components (Buttons, Inputs):** 0.5rem (8px).
- **Cards & Major Containers:** 1rem to 1.5rem (16px to 24px) to create the "premium card" feel.
- **Interactive Chips:** Fully rounded (pill-shaped) to distinguish them from buttons and inputs.

## Components

### Buttons
Primary buttons use a solid **Emerald Green** fill with white text. Secondary buttons use a transparent background with a 1px **Teal** border. Action-oriented icons should accompany text for better affordance.

### Cards
Cards are the primary content vehicle. They feature 16px-24px corner radii, white backgrounds, and subtle strokes. "AI-Suggested" cards should feature a 2px top-border gradient (Emerald to Cyan) to highlight their unique status.

### Interactive Chips
Used for skills and categories. Neutral chips (Default) use Light Gray backgrounds; Selected chips use a Teal tint. Animation should occur on tap to provide haptic-like feedback.

### Input Fields
Minimalist style. A 1px border that shifts from Light Gray to Emerald Green on focus. Labels should be small and sit above the field in `label-md` style.

### AI Indicators
Use a "Neural Pulse" icon—a subtle, glowing dot or a simplified node-line icon—next to AI-generated suggestions. Apply a very soft background blur (glassmorphism) to AI-specific overlays to separate them from standard content.