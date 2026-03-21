# Chlorophyll Tech Design System

### 1. Overview & Creative North Star
**Creative North Star: The Living Laboratory**
Chlorophyll Tech is a high-end technical design system that bridges the gap between cold artificial intelligence and organic agricultural science. It avoids the "industrial" look of traditional dashboards in favor of a "Living Laboratory" aesthetic—clean, precise, but deeply rooted in nature. It utilizes the sharp geometric qualities of Space Grotesk to convey technical rigor, while employing soft tonal layering and translucent materials to maintain an approachable, organic feel.

### 2. Colors
The palette is centered around a "Fidelity Green" (#2d7b31), representing growth and system health.
- **Primary Roles:** Used for high-priority actions and system indicators.
- **The "No-Line" Rule:** Structural separation is achieved through background shifts (e.g., using `surface_container_low` for section backgrounds) rather than 1px borders. If a border is required for contrast, it must use `primary/10` or `outline_variant` at low opacity.
- **Surface Hierarchy:** 
  - `surface` (#ffffff) for the main canvas.
  - `surface_container_low` (#f6f8f6) for secondary grouping.
  - `inverse_surface` (#2d322b) for high-intensity technical readouts (e.g., Server Health).
- **Glass & Gradient:** Navigation bars and floating panels utilize `backdrop-blur-lg` and 80% opacity to maintain a sense of lightness and depth.

### 3. Typography
The system uses **Space Grotesk** across all levels, leaning into its tabular-like numbers and geometric letterforms.
- **Display/Headline:** 1.5rem (24px) or 1.25rem (20px). Bold weights are used to define information architecture.
- **Body:** 0.875rem (14px) for standard readability.
- **Technical/Label:** 10px or 12px (0.75rem). Labels often use `uppercase` and `tracking-wider` to create a professional, blueprint-like quality.
- **Scale Ground Truth:** The system utilizes a rhythmic scale: 10px, 12px, 14px, 18px, 20px, 24px.

### 4. Elevation & Depth
Elevation is expressed through **Tonal Layering** and specific soft shadow profiles.
- **The Layering Principle:** Darker "Surface Inverse" cards are used to "punch through" the light background for mission-critical technical data.
- **Ambient Shadows:** 
  - `shadow-lg`: Used for primary action buttons (e.g., 0 10px 15px -3px rgba(45, 123, 49, 0.2)).
  - `shadow-xl`: Used for the main application container to separate it from the environment.
- **Glassmorphism:** The bottom navigation uses a semi-transparent white/slate blur to feel like a floating lens over the content.

### 5. Components
- **Primary Buttons:** High-saturation primary fill with a soft primary-colored shadow. Includes an internal "action icon" container with `white/20` background.
- **Status Cards:** Use a mix of `primary/5` fills and subtle 1px borders in the same hue.
- **Progress Bars:** Pill-shaped, using `primary` on a `slate-200` track for maximum visibility.
- **Technical Chips:** Small, square-rounded (8px) icons with background-tinted fills (e.g., green-100, blue-100) to categorize logs.
- **Navigation:** Icon-centric with 10px labels. Active states use full-color saturation; inactive states use `slate-400`.

### 6. Do's and Don'ts
- **Do:** Use `Space Grotesk` numbers in technical readouts—they are designed for clarity.
- **Do:** Use "Surface Inverse" (Dark) blocks within a "Surface" (Light) layout for visual punctuation.
- **Don't:** Use harsh black (#000000) for text; use `slate-900` or `on_surface` to keep the palette organic.
- **Don't:** Apply heavy drop shadows to every card; rely on subtle background color changes (`#f6f8f6` vs `#ffffff`) first.