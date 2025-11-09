# Multi-Directional Swipe Implementation

## Overview

Updated the swipe card interface to support **all 4 directions** (up, down, left, right) instead of just horizontal swipes.

## New Swipe Actions

### 4-Direction Swipe Map

```
         ↑ UP
     (Keep/Skip)
      🟠 Orange

← LEFT         RIGHT →
(Keep)         (Delete)
🟢 Green       🔴 Red

       ↓ DOWN
      (Redact)
      🔵 Blue
```

### Action Mapping

| Direction | Color  | Action | Description |
|-----------|--------|--------|-------------|
| ← Left    | 🟢 Green | **Keep** | Mark photo as safe, move to next |
| → Right   | 🔴 Red | **Delete** | Stage photo for deletion |
| ↑ Up      | 🟠 Orange | **Keep/Skip** | Alternative to left swipe |
| ↓ Down    | 🔵 Blue | **Redact** | Blur sensitive text (if available) |

## User Experience

### Visual Feedback

**Swipe Left (Keep):**
```
┌─────────────────────────┐
│ 🟢        [Card]         │  → Green glow from left edge
└─────────────────────────┘
```

**Swipe Right (Delete):**
```
┌─────────────────────────┐
│         [Card]        🔴 │  → Red glow from right edge
└─────────────────────────┘
```

**Swipe Up (Skip):**
```
       🟠
┌─────────────────────────┐
│         [Card]           │  → Orange glow from top
└─────────────────────────┘
```

**Swipe Down (Redact):**
```
┌─────────────────────────┐
│         [Card]           │  → Blue glow from bottom
└─────────────────────────┘
       🔵
```

### Swipe Detection Logic

The card follows your finger in **both X and Y directions** simultaneously. When you release:

1. **Compares horizontal vs vertical movement**
   - If `abs(X) > abs(Y)` → Horizontal action (left or right)
   - If `abs(Y) > abs(X)` → Vertical action (up or down)

2. **Checks if threshold crossed**
   - Threshold: 140 points
   - If movement > threshold → Execute action
   - If movement < threshold → Snap back to center

3. **Haptic feedback on threshold**
   - Medium impact when crossing threshold
   - Light impact on dismiss

### On-Screen Instructions

```
┌─────────────────────────────────────┐
│ 15 matched photo(s) to review       │
│                                     │
│ ← Keep  |  Delete →                 │
│ ↑ Skip  |  Redact ↓                 │
└─────────────────────────────────────┘
```

## Implementation Details

### Files Modified

**1. SwipeCardView.swift** (Lines 15-241)

**State Variables Updated:**
```swift
// Before: Single offset
@State private var offset: CGFloat = 0

// After: Separate X and Y
@State private var offsetX: CGFloat = 0
@State private var offsetY: CGFloat = 0
```

**New Properties:**
```swift
let onRedact: (() -> Void)?  // Optional redact callback

private var horizontalProgress: CGFloat  // For left/right glow
private var verticalProgress: CGFloat    // For up/down glow

private var isOverHorizontalThreshold: Bool
private var isOverVerticalThreshold: Bool
```

**Gesture Handler:**
```swift
DragGesture()
    .onChanged { value in
        offsetX = value.translation.width   // Horizontal movement
        offsetY = value.translation.height  // Vertical movement

        // Haptic when crossing any threshold
        if (isOverHorizontalThreshold || isOverVerticalThreshold) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    .onEnded { _ in
        // Determine dominant direction
        if abs(offsetX) > abs(offsetY) {
            // Horizontal action
            if offsetX > threshold { onDelete() }
            else if offsetX < -threshold { onKeep() }
        } else {
            // Vertical action
            if offsetY > threshold { onRedact?() }
            else if offsetY < -threshold { onKeep() }
        }
    }
```

**2. ContentView.swift** (Lines 178-228)

Updated instructions to show all 4 directions:
```swift
VStack(spacing: 8) {
    HStack {
        ← Keep  |  Delete →
    }
    HStack {
        ↑ Skip  |  Redact ↓
    }
}
```

### Visual Indicators

**4 Gradient Glows:**
```swift
// Left edge - green
if offsetX < 0 {
    LinearGradient(green → transparent)
        .frame(width: 150)
        .mask(Capsule())
}

// Right edge - red
if offsetX > 0 {
    LinearGradient(transparent → red)
        .frame(width: 150)
        .mask(Capsule())
}

// Top edge - orange
if offsetY < 0 {
    LinearGradient(orange → transparent)
        .frame(height: 150)
        .mask(Capsule())
}

// Bottom edge - blue
if offsetY > 0 {
    LinearGradient(transparent → blue)
        .frame(height: 150)
        .mask(Capsule())
}
```

### Dismiss Animation

```swift
func dismissCard(directionX: CGFloat, directionY: CGFloat) {
    let dismissOffsetX = directionX * 500  // Off-screen distance
    let dismissOffsetY = directionY * 500

    withAnimation(.spring()) {
        offsetX = dismissOffsetX
        offsetY = dismissOffsetY
    }

    // Call action after animation (0.4s)
}
```

## Usage Examples

### Example 1: Review Workflow
```
1. User sees flagged photo
2. Swipes left → Green glow appears
3. Releases → Card flies left → onKeep() called → Next photo
```

### Example 2: Delete Decision
```
1. User identifies sensitive content
2. Swipes right → Red glow appears
3. Crosses threshold → Haptic feedback
4. Releases → Card flies right → onDelete() called
```

### Example 3: Diagonal Swipe
```
1. User swipes diagonally (up-right)
2. Card follows finger in both directions
3. Releases at (X: 100, Y: -150)
4. abs(Y) > abs(X) → Vertical dominant
5. Y < 0 → Up action → onKeep() called
```

### Example 4: Below Threshold
```
1. User swipes slightly right (80 points)
2. Orange glow appears
3. Releases before threshold (140 points)
4. Card snaps back to center → No action
```

## Testing

### Test All 4 Directions

**Left Swipe (Keep):**
- [ ] Green glow appears from left
- [ ] Haptic at threshold
- [ ] Card dismisses left
- [ ] Next photo appears

**Right Swipe (Delete):**
- [ ] Red glow appears from right
- [ ] Haptic at threshold
- [ ] Card dismisses right
- [ ] Photo staged for deletion

**Up Swipe (Skip/Keep):**
- [ ] Orange glow appears from top
- [ ] Haptic at threshold
- [ ] Card dismisses up
- [ ] Next photo appears

**Down Swipe (Redact):**
- [ ] Blue glow appears from bottom
- [ ] Haptic at threshold
- [ ] Card dismisses down
- [ ] Redaction action (when implemented)

### Test Edge Cases

**Diagonal Swipes:**
- [ ] Up-left diagonal → Detects dominant direction
- [ ] Down-right diagonal → Detects dominant direction
- [ ] Equal X and Y → Vertical takes precedence

**Threshold Behavior:**
- [ ] Swipe 130 points → Snaps back (below threshold)
- [ ] Swipe 150 points → Dismisses (above threshold)
- [ ] Haptic only fires once per swipe

**Multiple Directions:**
- [ ] Can swipe in any direction on same photo
- [ ] Visual indicators only show for active direction
- [ ] Card follows finger smoothly in both axes

## Benefits

✅ **More Intuitive**: Natural gesture in all directions
✅ **More Actions**: 4 actions instead of 2 (left/right only)
✅ **Better UX**: Alternative ways to keep (left OR up)
✅ **Visual Clarity**: Color-coded glows for each direction
✅ **Smooth Animation**: Card follows finger in 2D space
✅ **Haptic Feedback**: Clear threshold indication

## Future Enhancements

Potential improvements:
1. Add redaction handler to actually redact on swipe down
2. Customize up action (skip vs keep vs something else)
3. Add diagonal actions (swipe up-right for specific action)
4. Configurable threshold per direction
5. Different haptics per action type
6. Velocity-based dismissal (fast swipe = instant)

## Migration Notes

### Backwards Compatibility

The old 2-direction swipe still works:
- Swipe left → Keep (green)
- Swipe right → Delete (red)

New functionality adds:
- Swipe up → Keep/Skip (orange)
- Swipe down → Redact (blue, when handler provided)

### API Changes

```swift
// Old initialization
SwipeCardView(
    content: { ... },
    onDelete: { ... },
    onKeep: { ... }
)

// New initialization (same signature, backward compatible)
SwipeCardView(
    content: { ... },
    onDelete: { ... },
    onKeep: { ... },
    onRedact: { ... }  // Optional, defaults to nil
)
```

---

**All 4 directions now work!** Swipe in any direction to interact with photos. 🎉
