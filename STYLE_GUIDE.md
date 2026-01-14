# 📘 KEDA - Style Guide v1.0

## 1. Brand Identity
* **Name:** KEDA
* **Domain:** getkeda.app
* **Slogan:** "What matters is what's left"
* **Visual Concept:** Data-driven minimalism. The budget is visualized as energy that depletes.

---

## 2. Color Palette (Hex Codes)

* **Primary (Success):** #22C55E (Healthy budget / positive numbers)
* **Secondary (Warning):** #FACC15 (Low budget < 30%)
* **Danger (Over):** #EF4444 (Over-budget / negative numbers)
* **Background (App):** #F8FAFC (Slate 50)
* **Surface (Cards):** #FFFFFF (Pure White)
* **Text (Main):** #0F172A (Slate 900)
* **Text (Muted):** #64748B (Slate 500)

---

## 3. Typography

* **Interface (Sans-Serif):** 'Inter' or 'Roboto'.
* **Amounts & Numbers (Monospace):** 'JetBrains Mono' or 'Roboto Mono'.
* **Weights:** Regular (400), Medium (500), Semi-bold (600), Bold (700).

---

## 4. UI Components (Technical Specs)

### A. Category Card (Home)
* **Layout:** 2-column responsive grid.
* **Border Radius:** 24px.
* **Shadow:** 0 4px 6px -1px rgba(0, 0, 0, 0.05).
* **Key Element:** 4px high progress bar at the bottom base of the card with dynamic color coding.

### B. Expense Input (Quick Entry)
* **Auto-focus:** Numeric keypad open by default upon entry.
* **Impact Preview:** Show projected calculation (Remaining - Input) in real-time.

---

## 5. UX Rules (Zero Friction)
1. **Priority:** The "Remaining" amount is always the largest visual element.
2. **Navigation:** Tapping a category triggers the entry flow immediately.
3. **Language:** Non-accounting terms. Use "Left" or "Remaining" instead of "Available Balance".

---

## 6. Iconography
* **Style:** Outline (Line).
* **Stroke Weight:** 2px.
* **Suggested Library:** Lucide Icons / Heroicons.