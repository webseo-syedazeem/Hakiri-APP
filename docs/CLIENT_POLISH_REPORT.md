# Hakkiri App — Polish & Fixes Report

**Date:** 3 November 2026  
**Scope:** Onboarding, UI consistency, practice questions, scoring, Debate Me, and copy updates  

---

## 1. Onboarding spacing and sizing

Adjusted onboarding / landing screens for clearer layout and more consistent spacing, including:

- Feedback preview page: spacing above the Clarity / Structure cards and the Focus Next card  
- Focus Next card: replaced the redundant **Start** button with a softer **Next up** cue (primary CTA remains **Explore exercises**)  
- Get started screen: **Skip** removed from the first page; Skip appears from the following screens only  

---

## 2. Font and size consistency (app-wide pass)

Reviewed screens to keep typography closer to one family and more consistent sizing across the app, so headings, body text, and labels feel like one product rather than mixed styles.

*Note: A full visual redesign was not the goal; this was a consistency pass on existing screens.*

---

## 3. Repeating questions (Debate Me and other drills)

**Issue:** Users saw the same practice question again and again (especially after **Begin** / **Try again**, and in Debate Me).

**Fix:**

- Every **Begin** / **Try again** fetches a fresh prompt and excludes the current one  
- Local fallback pools are blended when a career track has too few unique prompts  
- Backend prompt generation improved so questions stay shorter and better match the user’s level (beginner / intermediate / pro)  

---

## 4. Feedback scores in decimal points

**Issue:** Whole-number scores (e.g. overall `3` vs content/structure `2`) looked inconsistent and made averages hard to trust.

**Fix:** Scores are shown to **one decimal place** (e.g. `3.2`, `2.5`) across feedback and related views, so overall and per-metric values align and users are less confused by rounding.

---

## 5. Debate Me icon consistency

Debate Me now uses the **same icon treatment** as elsewhere in the app (aligned with other activity icons), so the drill looks consistent on home, practice, and detail screens.

---

## 6. UK English copy pass (app-wide)

Reviewed and adjusted user-facing copy to **UK English** spelling and wording (e.g. clearer British phrasing), so language stays consistent across onboarding, practice, feedback, and related screens.

---

## 7. Search screen: “drill” → “exercise”

Updated search / discovery copy so activities are referred to as **exercises** (not “drills”), matching the language used in the rest of the product.

---

## Summary

- Onboarding spacing, Skip placement, and Focus card polish  
- App-wide font and size consistency pass  
- Repeating questions fixed in Debate Me and other modules  
- Decimal scores in feedback for clearer averages  
- Debate Me icon aligned with the rest of the app  
- UK English copy polish across key user-facing screens  
- Search screen text updated from drill to exercise

---

## Follow-up (if needed)

- Redeploy backend when AI prompt length / level rules or Debate pushback fixes are still pending on production  
- Spot-check Begin + Try again on each exercise after a full app restart  
- Optional later: deeper font redesign if a full design system pass is required  

---

*Prepared for client / stakeholder review.*
