# Liquid Glass Documentation

## Overview

Liquid Glass is Apple's new design language introduced in iOS 26, iPadOS 26, macOS 26 (Tahoe), tvOS 26, visionOS 26, and watchOS 26. It features a translucent material that reflects and refracts surroundings with dynamic transformations.

## Official Resources

### Apple Developer Documentation
- **API Reference**: https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
- **Applying Liquid Glass Guide**: https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views
- **Adopting Liquid Glass**: https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass
- **Glass Structure**: https://developer.apple.com/documentation/swiftui/glass
- **GlassEffectContainer**: https://developer.apple.com/documentation/swiftui/glasseffectcontainer/
- **Landmarks Sample App**: https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass

### WWDC 2025 Sessions
- **WWDC25 Session 323**: "Build a SwiftUI app with the new design"
  - Video: https://developer.apple.com/videos/play/wwdc2025/323/
- **Related Session 356**: "Get to know the new design system"

## Design Philosophy

> "Liquid Glass is exclusively for the navigation layer that floats above app content. Never apply to content itself (lists, tables, media). This maintains clear visual hierarchy: content remains primary while controls provide functional overlay."

### Key Principles
1. **Navigation Layer Only**: Apply to toolbars, sidebars, and floating controls
2. **Content Stays Clear**: Lists, tables, and primary content should NOT have glass
3. **Automatic Adaptation**: Glass adapts to colorful content beneath it
4. **System Integration**: Use standard components to get automatic glass effects

## SwiftUI API

### Basic Usage

```swift
import SwiftUI

struct BasicGlassView: View {
    var body: some View {
        Text("Hello, Liquid Glass!")
            .padding()
            .glassEffect() // Default: .regular variant, .capsule shape
    }
}
```

### Custom Shapes

```swift
Text("Custom Shape")
    .padding()
    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
```

### Tinted Glass (Use Sparingly)

```swift
Text("Important Action")
    .padding()
    .glassEffect()
    .tint(.blue) // Only use to convey meaning, not for visual effect
```

### Interactive Glass (iOS)

```swift
Button("Tap Me") {
    // action
}
.glassEffect(.interactive) // Scales, bounces, and shimmers on interaction
```

### Glass Effect Container

For multiple glass elements that need to interact and blend:

```swift
GlassEffectContainer {
    VStack {
        Button("First") { }
            .glassEffect()
            .glassEffectID("first", in: namespace)
        
        Button("Second") { }
            .glassEffect()
            .glassEffectID("second", in: namespace)
    }
}
```

### Backward Compatibility

```swift
extension View {
    @ViewBuilder
    func glassBackground() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect()
        } else {
            self.background(.ultraThinMaterial)
        }
    }
}
```

## Automatic Updates in Standard Components

When building with Xcode 26 SDK, these components automatically use Liquid Glass:

### App Structure
- **NavigationSplitView**: Floating Liquid Glass sidebar above content
- **TabView**: Floating tab bar that can minimize on scroll
- **Sheets**: Inset with Liquid Glass background, transitions to opaque at full height
- **Menus, Alerts, Popovers**: Flow smoothly from glass controls

### Toolbars
- Toolbar items on Liquid Glass surface
- Automatic grouping of related actions
- Monochrome icons by default
- Automatic scroll edge effect for legibility

### Controls
- Buttons: Capsule shape by default, new `.glass` and `.glassProminent` styles
- Sliders: Support tick marks and neutral value starting points
- Menus: Consistent icon placement across platforms
- All controls transform into liquid glass during interaction

## macOS-Specific Features

### Corner Concentricity

Align custom controls with container corners:

```swift
RoundedRectangle(cornerRadius: .containerConcentric)
    .fill(.blue)
```

### Search Placement

```swift
NavigationSplitView {
    // content
}
.searchable(text: $searchText) // Appears in top-trailing on macOS
```

### Toolbar Customization

```swift
.toolbar {
    ToolbarItem {
        Button("Action") { }
    }
    ToolbarSpacer(.fixed(16)) // Create visual grouping
    ToolbarItem {
        Button("Another") { }
    }
}
```

## Best Practices

### DO
✅ Use for navigation layers (sidebars, toolbars, floating controls)
✅ Build with Xcode 26 SDK to get automatic updates
✅ Remove custom backgrounds behind sheets and toolbars
✅ Use standard components when possible
✅ Test with colorful content underneath (glass needs content to reflect)

### DON'T
❌ Apply to primary content (lists, tables, text editors, media)
❌ Use tints for pure visual effect (only for meaning/emphasis)
❌ Add extra backgrounds that interfere with scroll edge effects
❌ Over-apply glass to every element
❌ Ignore backward compatibility for older macOS versions

## User Preferences

Users can customize Liquid Glass in System Settings:
- **macOS 26.1+**: System Settings → Appearance
  - "Liquid Glass: Clear"
  - "Liquid Glass: Tinted"
- **Reduce Transparency**: Respects accessibility settings

## Implementation Checklist for PDFScribe

When ready to adopt Liquid Glass:

1. ✅ Build with Xcode 26 SDK
2. ✅ Test on macOS 26 (Tahoe)
3. ✅ Apply `.glassEffect()` to navigation panels:
   - PDF viewer panel (left)
   - AI assistant panel (right)
4. ✅ Keep content layer as-is:
   - Note editor (center) - paper background
5. ✅ Remove any custom backgrounds behind glass elements
6. ✅ Implement backward compatibility for macOS 12-25
7. ✅ Test with loaded PDFs to see glass adapt to colors
8. ✅ Verify accessibility with "Reduce Transparency" enabled

## Community Resources

- **GitHub Reference**: https://github.com/conorluddy/LiquidGlassReference
- **Reddit Discussions**:
  - r/SwiftUI: Glass effect documentation and beta changes
  - r/Xcode: Implementation tips for iOS 26

## Notes

- macOS 26 (Tahoe) implementation is noted as "the least consistent and polished" compared to other platforms
- `.clear` variant of `.glassEffect()` is mentioned in WWDC but not yet available in current documentation
- Liquid Glass is a divisive design - some users love it, others find it distracting
- Consider offering users a toggle to disable glass effects in app preferences

---

*Last updated: January 8, 2026*
*Source: Apple WWDC25 Session 323, Apple Developer Documentation*
