# Implementation Plan - Product Detail Screen

The user wants to recreate a mobile screen layout seen in an image. The screen features a large top section for an image and a bottom card with product details, a quantity selector, and a "Buy Now" button.

## Proposed Changes

### [Screens]

#### [NEW] [product_detail_screen.dart](file:///C:/Users/Admin/Desktop/JY%20School/JY%20ERP/JY-School/flutter_mobile/lib/screens/product_detail_screen.dart)
Create a new screen implementing the design from the provided image.

**Key Features:**
- **Top Image/Placeholder Area:** A large colored section at the top.
- **Bottom Information Card:**
    - Rounded top corners.
    - Product Title ("Sleep 30").
    - Product Subtitle ("Dissolvable Wafers").
    - Price Display ("$25.50").
    - Quantity Selector with increment/decrement buttons.
    - Styled "Buy Now" Button.

## Implementation Details

The screen will be structured using a `Stack` or a `Column` with an `Expanded` top section and a bottom fixed-height or wrap-content card.

### Layout structure:
- `Scaffold`
  - `body`: `Stack`
    - `Positioned.fill` (for the background image/color)
    - `Align(alignment: Alignment.bottomCenter)`
      - `Container` (The white card)
        - `Padding`
        - `Column`
          - Product Title (`Text` with bold style)
          - Product Subtitle (`Text`)
          - `SizedBox` (spacing)
          - `Row`
            - Price (`Text`)
            - `Spacer`
            - Quantity Selector (`Row` with `IconButton`s and `Text`)
          - `SizedBox` (spacing)
          - `ElevatedButton` ("Buy Now")

## Verification Plan

### Automated Tests
- N/A (UI-focused change)

### Manual Verification
- Navigate to the `ProductDetailScreen` to verify the layout matches the image.
- Since this is a standalone screen, I will provide a way to access it or set it as the `home` in `main.dart` temporarily for the user to see.
