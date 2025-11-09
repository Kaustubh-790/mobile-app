# UI Design Prompts for Mobile App Screens

This document contains comprehensive design prompts for all screens in the mobile application. Each prompt is tailored to create a **fluid, modern, animated, clean** interface that supports both **dark and light modes** with beautiful **card designs**.

---

## Design System Guidelines

### Core Style Principles

- **Fluid**: Smooth transitions, flowing animations, and seamless interactions
- **Modern**: Contemporary design patterns, clean typography, and minimalist aesthetics
- **Animated**: Subtle micro-interactions, page transitions, and loading states
- **Clean**: Generous whitespace, clear hierarchy, and uncluttered layouts
- **Dark/Light Mode**: Full support with adaptive colors and proper contrast ratios
- **Card Designs**: Elevated cards with subtle shadows, rounded corners, and hover effects

### Color Palette

- **Primary Colors**: Vibrant accent colors that adapt to theme
- **Background**: Light mode - soft whites/grays; Dark mode - deep dark blues/blacks
- **Cards**: Light mode - white with subtle shadows; Dark mode - dark cards with glow effects
- **Text**: High contrast ratios for accessibility (WCAG AA compliant)

### Typography

- **Headings**: Bold, modern sans-serif (e.g., Inter, Poppins)
- **Body**: Clean, readable sans-serif with proper line heights
- **Hierarchy**: Clear size differentiation (H1: 28-32px, H2: 24px, Body: 16px)

### Animation Guidelines

- **Transitions**: 200-300ms for micro-interactions
- **Page Transitions**: 300-400ms with easing curves
- **Loading States**: Smooth spinners and skeleton screens
- **Hover/Tap**: Subtle scale and elevation changes

---

## Screen Design Prompts

### 1. Login Screen

**Design Prompt:**
Create a modern, welcoming login screen with two authentication methods (Email/Password and Phone Number) presented in an elegant tabbed interface. The design should feature:

- **Hero Section**: Large, animated app logo or illustration at the top with a gentle fade-in animation
- **Tab Navigation**: Smooth, pill-shaped tab switcher with animated indicator that slides between tabs
- **Form Cards**: Each authentication method in a clean, elevated card with:
  - Rounded corners (16px radius)
  - Subtle shadow that adapts to theme
  - Smooth focus animations on input fields
  - Floating labels that animate upward on focus
- **Input Fields**:
  - Modern outlined style with animated borders
  - Icons that change color on focus
  - Password visibility toggle with smooth icon transition
  - Error states with gentle shake animation
- **Buttons**:
  - Primary button with gradient background and subtle hover effect
  - Google Sign-In button with brand colors and icon
  - Loading states with animated spinner
- **Dark Mode**:
  - Deep dark background (#0F0F23 or similar)
  - Cards with subtle glow effects
  - Input fields with dark backgrounds and light borders
- **Light Mode**:
  - Clean white/light gray background
  - Cards with soft shadows
  - Input fields with white backgrounds
- **Animations**:
  - Page entrance: Fade in from bottom (300ms)
  - Tab switch: Smooth slide transition (250ms)
  - Form submission: Button pulse animation
  - Error messages: Slide down with fade (200ms)

**Key Elements:**

- Welcome message with personalized greeting
- "Don't have an account? Sign Up" link at bottom
- Error handling with animated error cards
- Responsive layout that works on all screen sizes

---

### 2. Onboarding Screen

**Design Prompt:**
Design a clean, step-by-step profile completion screen that guides new users through providing essential information. The interface should feel:

- **Welcome Card**:
  - Prominent card at top with icon, welcome message, and brief description
  - Soft gradient background or subtle pattern
  - Animated entrance with scale and fade
- **Form Layout**:
  - Each field in its own card or section
  - Clear visual hierarchy with icons
  - Read-only phone number display in a distinct, muted card
- **Input Fields**:
  - Large, touch-friendly fields (minimum 48px height)
  - Clear labels with helpful hints
  - Validation feedback with animated checkmarks or error icons
  - Smooth transitions between fields
- **Submit Button**:
  - Prominent, full-width button at bottom
  - Loading state with progress indicator
  - Success animation on completion
- **Dark/Light Mode**:
  - Adaptive card backgrounds
  - Theme-aware icons and text colors
- **Animations**:
  - Sequential field appearance (staggered fade-in)
  - Button press feedback (scale down then up)
  - Success state: Confetti or checkmark animation

**Key Elements:**

- Clear indication of required vs optional fields
- Helpful placeholder text
- Info message about updating profile later
- Smooth keyboard handling

---

### 3. Home Screen

**Design Prompt:**
Create an engaging, dynamic home screen that serves as the main hub of the application. The design should be:

- **Welcome Header**:
  - Gradient banner with user's name and greeting
  - Animated profile icon or avatar
  - "View Profile" button with subtle hover effect
  - Smooth parallax effect on scroll
- **Quick Actions Grid**:
  - 2x3 or 3x2 grid of interactive cards
  - Each card with:
    - Icon in colored container (circular or rounded square)
    - Title and optional subtitle
    - Tap animation (scale + elevation change)
    - Hover/press state with color transition
  - Cards arranged with consistent spacing
  - Staggered entrance animation
- **Popular Services Section**:
  - Horizontal scrolling card list
  - Each service card with:
    - Image or icon placeholder
    - Service name and brief description
    - Price badge
    - "Add to Cart" button
  - Smooth horizontal scroll with momentum
  - Card scale animation on tap
- **Navigation Bar**:
  - Cart icon with animated badge (pulse when items added)
  - Settings, Profile, Bookings icons
  - Smooth icon transitions
- **Dark/Light Mode**:
  - Header gradient adapts to theme
  - Cards maintain contrast in both modes
  - Icons and text are theme-aware
- **Animations**:
  - Pull-to-refresh with custom animation
  - Card entrance: Staggered fade and slide
  - Scroll animations: Cards fade in as they enter viewport
  - Badge animations: Bounce when count changes

**Key Elements:**

- Pull-to-refresh functionality
- Empty states with helpful messages
- Loading skeletons for content
- Smooth infinite scroll (if applicable)

---

### 4. Service Detail Screen

**Design Prompt:**
Design a comprehensive service detail screen that showcases service packages with clear pricing and features. The interface should feature:

- **Service Header Card**:
  - Large, prominent service title
  - Description text with proper line height
  - Subtle background pattern or gradient
  - Smooth scroll-triggered animations
- **Package Cards**:
  - Each package in its own elevated card
  - Card structure:
    - Header with package name and price badge
    - Feature list with checkmark icons
    - Duration information
    - Quantity selector with animated +/- buttons
    - "Add to Cart" and "Book Now" buttons
  - Cards with hover/press effects
  - Price badge with accent color
- **Feature List**:
  - Bullet points with animated checkmarks
  - Smooth reveal animation on scroll
  - Clear typography hierarchy
- **Action Buttons**:
  - Primary "Book This Package" button
  - Secondary "Add to Cart" button
  - Loading states with spinners
  - Success feedback animations
- **Quantity Selector**:
  - Modern increment/decrement controls
  - Animated number changes
  - Visual feedback on limits (min/max)
- **Dark/Light Mode**:
  - Cards adapt to theme
  - Price badges maintain visibility
  - Feature icons are theme-aware
- **Animations**:
  - Page entrance: Fade in content
  - Package cards: Staggered entrance
  - Button interactions: Ripple effects
  - Quantity changes: Number counter animation

**Key Elements:**

- Clear pricing display
- Feature comparison (if multiple packages)
- Image placeholders or service icons
- Error handling for failed loads

---

### 5. Cart Screen

**Design Prompt:**
Create a clean, functional shopping cart screen that makes it easy to review and modify items. The design should include:

- **Cart Items List**:
  - Each item in a card with:
    - Service name and package details
    - Price per item and total
    - Quantity controls with smooth animations
    - Delete button with confirmation
  - Cards with subtle shadows
  - Swipe-to-delete gesture (optional)
  - Empty state with illustration and message
- **Quantity Controls**:
  - Modern +/- buttons
  - Animated number display
  - Disabled states for min/max
  - Smooth transitions
- **Bottom Summary Card**:
  - Fixed or sticky at bottom
  - Total price prominently displayed
  - "Proceed to Checkout" button
  - Smooth slide-up animation
- **Empty State**:
  - Large icon or illustration
  - Helpful message
  - "Browse Services" button
- **Dark/Light Mode**:
  - Cards adapt to theme
  - Summary card stands out
  - Icons and text maintain contrast
- **Animations**:
  - Item removal: Slide out animation
  - Quantity changes: Number counter animation
  - Total update: Smooth number transition
  - Empty state: Fade in animation

**Key Elements:**

- Clear item information
- Easy quantity modification
- Prominent total display
- Smooth checkout flow

---

### 6. Checkout Screen

**Design Prompt:**
Design a comprehensive checkout screen that guides users through finalizing their booking. The interface should be:

- **Order Summary Card**:
  - List of items with details
  - Quantity and price per item
  - Grand total prominently displayed
  - Subtle divider before total
  - Smooth scroll animations
- **Address Section Card**:
  - Multi-line text input
  - Location icon
  - Auto-fill from profile option
  - Validation feedback
- **Date & Time Selection Card**:
  - Two side-by-side pickers
  - Calendar icon for date
  - Clock icon for time
  - Selected values clearly displayed
  - Validation messages for constraints
  - Helpful hints (e.g., "No bookings before 9 AM")
- **Notes Section Card**:
  - Optional multi-line input
  - Character count (if needed)
  - Placeholder text
- **Total & Confirm Section**:
  - Large total amount display
  - Primary "Proceed to Payment" button
  - Terms and conditions text
  - Loading state during processing
- **Dark/Light Mode**:
  - All cards adapt to theme
  - Input fields maintain visibility
  - Buttons stand out appropriately
- **Animations**:
  - Card entrance: Staggered fade-in
  - Form validation: Smooth error appearance
  - Button press: Scale feedback
  - Success: Smooth navigation transition

**Key Elements:**

- Clear form sections
- Validation feedback
- Date/time constraints clearly communicated
- Smooth payment flow transition

---

### 7. Payment Screen

**Design Prompt:**
Create a secure, modern payment screen with a dark theme aesthetic. The design should feature:

- **Payment Summary Card**:
  - Dark card with subtle glow
  - Amount prominently displayed
  - Booking ID reference
  - Smooth entrance animation
- **Payment Method Selection**:
  - Radio button cards for each method
  - Icons for each payment type
  - Smooth selection animation
  - Active state with accent color
- **Card Details Form** (if card selected):
  - Dark-themed input fields
  - Card number with spacing
  - Expiry and CVV side-by-side
  - Cardholder name field
  - Smooth focus transitions
  - Validation feedback
- **Pay Button**:
  - Large, prominent button
  - Loading state with spinner
  - Success animation
- **Error Handling**:
  - Error cards with red accent
  - Clear error messages
  - Smooth appearance animation
- **Dark Theme Focus**:
  - Deep dark background (#0F0F23)
  - Cards with subtle glow effects
  - White/light text for contrast
  - Accent colors for highlights
- **Animations**:
  - Page entrance: Fade in
  - Method selection: Smooth transition
  - Form appearance: Staggered fade-in
  - Button press: Pulse effect
  - Success: Confetti or checkmark

**Key Elements:**

- Secure payment feel
- Clear amount display
- Easy method selection
- Smooth form interactions

---

### 8. My Bookings Screen

**Design Prompt:**
Design a comprehensive bookings management screen that displays all user bookings with expandable details. The interface should include:

- **Booking Cards**:
  - Each booking in an expandable card
  - Card header with:
    - Booking ID
    - Status badge (color-coded)
    - Total amount
    - Date and time
  - Expandable section with:
    - Service details list
    - Worker assignment info
    - Progress indicators
    - Action buttons (Pay, Reschedule, Cancel, Rate, Report)
  - Smooth expand/collapse animation
  - Tap to expand/collapse
- **Status Indicators**:
  - Color-coded badges
  - Progress bars for completion
  - Animated status changes
- **Service Details**:
  - Nested cards for each service
  - Individual service status
  - Service-specific actions
- **Action Buttons**:
  - Context-aware buttons
  - Loading states
  - Confirmation dialogs
- **Empty State**:
  - Illustration or icon
  - Helpful message
  - "Browse Services" button
- **Dark/Light Mode**:
  - Cards adapt to theme
  - Status colors maintain meaning
  - Text remains readable
- **Animations**:
  - Card entrance: Staggered fade-in
  - Expand/collapse: Smooth height transition
  - Status updates: Color transition
  - Button interactions: Scale feedback

**Key Elements:**

- Clear booking information
- Easy status tracking
- Quick actions
- Smooth interactions

---

### 9. Settings Screen

**Design Prompt:**
Create a clean, organized settings screen with grouped options. The design should feature:

- **Settings Groups**:
  - Clear section headers
  - Grouped related options
  - Visual separation between groups
- **Settings Tiles**:
  - Each option in a card/tile
  - Icon in colored container
  - Title and subtitle
  - Arrow indicator
  - Tap animation
  - Hover/press states
- **Sections**:
  - Account section
  - Support section
  - Account Actions section
  - App Information section
- **Logout Option**:
  - Distinct styling (red accent)
  - Confirmation dialog
  - Smooth transition
- **Dark/Light Mode**:
  - Tiles adapt to theme
  - Icons maintain visibility
  - Clear visual hierarchy
- **Animations**:
  - Page entrance: Fade in
  - Tile interactions: Scale feedback
  - Navigation: Smooth transitions

**Key Elements:**

- Clear organization
- Easy navigation
- Visual feedback
- Consistent styling

---

### 10. My Profile Screen

**Design Prompt:**
Design a personal profile screen that displays user information in a clean, organized manner. The interface should include:

- **Profile Header Card**:
  - Large avatar or icon
  - User name prominently displayed
  - Email address
  - Refresh button
  - Smooth pull-to-refresh
- **Profile Details Card**:
  - Information fields with icons
  - Clear labels and values
  - Organized layout
  - Read-only display (or edit mode)
- **Information Fields**:
  - Full Name
  - Email Address
  - Phone Number
  - Address (formatted)
- **Loading States**:
  - Skeleton screens
  - Smooth transitions
- **Error States**:
  - Clear error messages
  - Retry button
  - Helpful guidance
- **Dark/Light Mode**:
  - Cards adapt to theme
  - Text maintains contrast
  - Icons are visible
- **Animations**:
  - Page entrance: Fade in
  - Refresh: Pull animation
  - Data updates: Smooth transitions

**Key Elements:**

- Clear information display
- Easy refresh
- Error handling
- Smooth loading states

---

### 11. Contact Us Screen

**Design Prompt:**
Create a friendly, accessible contact screen that makes it easy for users to reach out. The design should feature:

- **Contact Information Cards**:
  - Each contact method in a card
  - Icons for email, phone, address
  - Clear labels and values
  - Tap-to-call/email functionality
- **Contact Form** (if applicable):
  - Name, email, subject fields
  - Message text area
  - Submit button
  - Validation feedback
- **Social Media Links** (if applicable):
  - Icon buttons
  - Brand colors
  - Smooth hover effects
- **Map/Location** (if applicable):
  - Embedded map or address
  - Clear location display
- **Dark/Light Mode**:
  - Cards adapt to theme
  - Icons maintain visibility
  - Form fields are readable
- **Animations**:
  - Card entrance: Staggered fade-in
  - Button interactions: Scale feedback
  - Form submission: Loading state

**Key Elements:**

- Clear contact options
- Easy interaction
- Professional appearance
- Helpful information

---

### 12. About Us Screen

**Design Prompt:**
Design an informative about us screen that tells the company's story. The interface should include:

- **Hero Section**:
  - Company logo or illustration
  - Tagline or mission statement
  - Smooth entrance animation
- **Content Cards**:
  - Story/History card
  - Mission/Vision card
  - Values card
  - Team card (if applicable)
- **Text Content**:
  - Clear typography
  - Proper spacing
  - Readable line lengths
  - Smooth scroll animations
- **Visual Elements**:
  - Icons or illustrations
  - Subtle background patterns
  - Brand colors
- **Dark/Light Mode**:
  - Content adapts to theme
  - Text remains readable
  - Visual elements maintain appeal
- **Animations**:
  - Page entrance: Fade in
  - Content reveal: Scroll-triggered animations
  - Smooth scrolling

**Key Elements:**

- Clear information hierarchy
- Engaging content presentation
- Professional appearance
- Easy reading experience

---

## Implementation Notes

### Animation Library Recommendations

- Use Flutter's built-in animation widgets (AnimatedContainer, AnimatedOpacity, etc.)
- Consider packages like `flutter_animate` for complex animations
- Use `Hero` widgets for shared element transitions

### Dark Mode Implementation

- Use Flutter's ThemeData with `brightness: Brightness.dark`
- Create custom color schemes that adapt to theme
- Test contrast ratios for accessibility

### Card Design Patterns

- Use `Card` widget with elevation
- Apply consistent border radius (12-16px)
- Use subtle shadows that adapt to theme
- Add hover/press states with `InkWell` or `GestureDetector`

### Responsive Design

- Use `MediaQuery` for screen size detection
- Implement flexible layouts with `Flex` and `Expanded`
- Test on multiple screen sizes
- Consider tablet layouts

### Performance Optimization

- Use `ListView.builder` for long lists
- Implement lazy loading for images
- Optimize animation performance
- Use `const` constructors where possible

---

## Design Checklist

For each screen, ensure:

- [ ] Smooth animations and transitions
- [ ] Dark and light mode support
- [ ] Card-based design with proper elevation
- [ ] Clear visual hierarchy
- [ ] Accessible color contrasts
- [ ] Touch-friendly interactive elements (min 48px)
- [ ] Loading and error states
- [ ] Empty states with helpful messages
- [ ] Consistent spacing and padding
- [ ] Responsive layout
- [ ] Performance optimized

---

## Resources

### Design Tools

- Figma for mockups
- Adobe XD for prototypes
- Flutter Inspector for debugging

### Color Tools

- Material Design Color Tool
- Contrast Checker (WebAIM)

### Animation Resources

- Flutter Animation Documentation
- Material Motion Guidelines
- Lottie for complex animations (if needed)

---

**Last Updated**: 2024
**Version**: 1.0
