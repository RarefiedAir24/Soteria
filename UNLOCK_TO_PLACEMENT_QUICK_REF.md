# 🎓 Unlock-to-Placement Tutorial - Quick Reference

## 🎬 **3-Screen Flow:**

```
1. 🎉 CELEBRATION → "Place on Your Tree"
2. 🎨 PLACEMENT + TUTORIAL → Guided steps → "Done"
3. 🏠 HOME → Animal placed!
```

---

## 📱 **Screen 1: Celebration**
- Confetti animation
- Rotating animal icon with glow
- Bonus points display
- [Place on Your Tree →] button

## 📱 **Screen 2: Placement (with Tutorial - first time only)**
**Tutorial Steps:**
1. **Welcome:** "Let's place your cat!" [Let's Go!]
2. **Drag:** "Tap and drag to ground" → User drags
3. **Arrows:** "Use arrows for precision" → User taps 3x
4. **Confirm:** "Tap Done" → User confirms
5. **Future:** "How to move later" [Got it!]

**Controls:**
- **Drag:** Rough positioning
- **Arrow Pad:** Precision (10px per tap)
- **Undo:** Revert last move
- **Done:** Confirm and complete

## 📱 **Screen 3: Home**
- Animal now on tree
- Tutorial complete ✅

---

## 🔑 **Key Files:**

| Component | Path |
|-----------|------|
| Flow Coordinator | `Services/UnlockFlowCoordinator.swift` |
| Celebration | `Views/UnlockCelebrationView.swift` |
| Arrow Pad | `Views/Components/ArrowPad.swift` |
| Tutorial | `Views/InteractivePlacementTutorial.swift` |
| Placement View | `Views/AnimalPlacementView.swift` |
| Integration | `Views/MainTabView.swift` |
| Trigger | `Services/AchievementsService.swift` |

---

## 🧪 **Quick Test:**

1. Open Developer Testing menu
2. Add 25,000 points
3. Complete a goal → Achievement unlocks
4. Tap "Unlock" in Achievements View
5. Experience the flow!

---

## 💡 **Tutorial State:**

- **First unlock:** Full tutorial (5 steps)
- **Subsequent unlocks:** No tutorial, just placement
- **Reset tutorial:** Delete `UserDefaults` key `placement_tutorial_completed`

---

**This transforms confused users into confident decorators!** 🚀