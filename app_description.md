# Cliply — App Visual & Design Description

Cliply is a premium, modern, and highly polished mobile clipboard manager and note-taking vault. The application's visual style is a fusion of the clean, content-first layout of Notion, the sleek dark aesthetic of Linear, the premium typography of Apple Notes, and the keyboard/search-first speed of modern productivity tools.

---

## 1. Design Language & Aesthetics

* **Aesthetic Philosophy:** Minimalist, high-contrast, structured, and modern. The interface prioritizes clean information hierarchy and spatial organization using large corner radii and subtle borders rather than heavy shadows or fills.
* **Component Geometry:** 
  * **Card Corner Radius:** 20px (generous, friendly rounded corners).
  * **Bottom Sheet Top Radius:** 32px (creating a distinct, soft drawer overlay).
  * **Interactive Inputs / Chips:** 12px and pill-shaped (capsule style).
  * **Floating Action Button (FAB):** 16px rounded square (Extended FAB that collapses dynamically on scroll).
* **Typography:** Inter by Google Fonts. Heavy emphasis on font weights and sizes to define hierarchy:
  * Headers: Bold, high-contrast, with tight letter spacing.
  * Body Text: Elegant, readable line height (1.5x) with muted secondary colors for previews.
  * Code/Mono: Strict monospace font blocks for code snippet cards.

---

## 2. Color Palettes

Cliply features a dual-theme system carefully curated to offer premium readability and a state-of-the-art look:

### Light Mode (Premium Minimalist)
* **Scaffold Background:** `#F8F7FA` (A clean, warm off-white that reduces glare).
* **Card & Sheet Surfaces:** `#FFFFFF` (Pure white, contrasting subtly against the off-white background).
* **Primary Accent Color:** `#6D5DFC` (A vibrant, rich electric purple used for active states, key CTA buttons, and highlights).
* **Secondary Accent Color:** `#A393FF` (A softer, lavender-purple used for secondary highlights and subtle borders).
* **Primary Text:** `#1A1A1A` (Near-black for crisp, legible reading).
* **Secondary/Muted Text:** `#666666` (Slate gray for metadata, dates, and card descriptions).
* **Borders & Dividers:** `#E8E8E8` (Light gray hairline borders, 1px width).

### Dark Mode (Linear-Inspired Charcoal)
* **Scaffold Background:** `#121214` (A deep, rich charcoal black).
* **Card & Sheet Surfaces:** `#1A1A1E` (A slightly lighter obsidian gray, giving depth to floating surfaces).
* **Primary Accent Color:** `#8B7EFF` (A glowing pastel violet/indigo, highly visible on dark backgrounds).
* **Secondary Accent Color:** `#B9AEFF` (A light pastel lavender for subtle active indicators).
* **Primary Text:** `#F3F3F5` (Crisp off-white for comfortable reading).
* **Secondary/Muted Text:** `#9E9EAF` (Muted silver-gray for secondary text and details).
* **Borders & Dividers:** `#2C2C35` (Dark slate hairline borders, 1px width, creating elegant separations).

---

## 3. Brand Identity & Vector Logo

Cliply's logo is a strictly black-and-white minimalist vector icon designed to look sharp on any background.
* **Icon Structure:** A clean, flat vector shape representing a classic clipboard.
* **Colors & Theme Adaptation:**
  * **Light Theme Representation:** The clipboard backing is solid charcoal/black (`#323232`) and features bold, horizontal white stripes (`#FFFFFF`) representing lines of text.
  * **Dark Theme Representation:** The clipboard backing is solid white (`#FFFFFF`) and features bold, horizontal charcoal/black stripes (`#1A1A1E`) representing lines of text.
* **Visual Presentation:** Placed cleanly inside the app bar header, aligned next to the brand name "Cliply" in semi-bold Inter typography.

---

## 4. Main Interface & Page Layout

### Header & Navigation Bar
* A clean, flat top app bar. On the left is the brand presentation: the vector clipboard logo side-by-side with the wordmark "Cliply" in custom Inter font.
* On the right side of the app bar, a subtle icon button allows users to toggle between Light Mode and Dark Mode instantly.

### Unified Search Bar
* Centered below the header is a full-width search input with 12px rounded corners.
* The search bar is filled with the scaffold background color (`#F8F7FA` in light, `#121214` in dark), featuring a subtle search icon on the left and placeholder text saying "Search notes, links, code..." in secondary muted gray.

### Horizontal Filter Chips Bar
* A horizontal scrolling list of pill-shaped chips acting as category filters.
* Available filter tags: `All`, `Recent`, `Favorites`, `Links`, `Code`.
* Unselected chips are transparent with a 1px border. Selected chips fill with the primary accent color (`#6D5DFC` or `#8B7EFF`) and have white text.

### Note & Clipboard Snippets Grid/List
* A flexible list or grid displaying saved items. Each note is housed inside a card with a 1px border and 20px rounded corners.
* **Note Cards Interior Design:**
  * **Header:** Features the title of the note in bold primary text. Next to it, an icon denotes the category (e.g., code bracket icon, link chain icon, normal page icon).
  * **Body:** The content preview of the note or clip (text paragraph, copyable URL link, or syntax-style text block).
  * **Footer:** Displays a relative timestamp (e.g., "2 hours ago") on the left and a floating, translucent circle button containing a clipboard copy icon on the right.
  * **Quick Copy Action:** Clicking the copy icon on the card initiates a one-click copy event, copying the note's text content to the device's clipboard immediately with a micro-feedback toast.
* **Card Gestures (Swipe Actions):**
  * Swiping a card horizontally reveals clean background action buttons underneath: `Edit` (purple), `Pin` (yellow), `Share` (blue), and `Delete` (red), allowing users to organize their clipboard quickly without opening details.

### Extended Floating Action Button (FAB)
* Located in the bottom-right corner. It is a capsule-shaped FAB filled with the primary accent color.
* When resting at the top of the page, it displays an add (`+`) icon and the text label "New Snippet".
* As the user scrolls down through the list of note cards, the FAB smoothly collapses into a compact circle containing only the `+` icon to save screen real estate.

### Note Editor Bottom Sheet
* When a user taps a card or the FAB, a bottom drawer slides up smoothly from the bottom, featuring a 32px top-corner radius.
* **Bottom Sheet Layout:**
  * **Header:** Title input, a pin toggle (star/pin icon), and a quick copy icon.
  * **Category Selector:** A row of chips to select the note type (Text, Link, Code).
  * **Content Editor:** A large text area with a clear caret for writing notes or pasting clipboard logs.
  * **Footer Action Bar:** Clean actions to "Save" or "Close".
