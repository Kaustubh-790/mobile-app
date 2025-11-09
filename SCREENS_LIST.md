# Mobile App Screens - Complete List

This document provides a quick reference list of all screens in the mobile application.

## Screen Inventory

### Authentication Screens (2)
1. **Login Screen** (`lib/src/screens/auth/login_screen.dart`)
   - Email/Password authentication tab
   - Phone number authentication tab
   - Google Sign-In integration
   - Registration link

2. **Onboarding Screen** (`lib/src/screens/auth/onboarding_screen.dart`)
   - Profile completion form
   - Name, email, address fields
   - Phone number display (read-only)

### Main Application Screens (10)
3. **Home Screen** (`lib/src/screens/home/home_screen.dart`)
   - Welcome header with user greeting
   - Popular services section
   - Quick actions grid
   - Navigation to cart, profile, settings, bookings

4. **Service Detail Screen** (`lib/src/screens/service/service_detail_screen.dart`)
   - Service information display
   - Available packages list
   - Package features
   - Quantity selector
   - Add to cart functionality

5. **Cart Screen** (`lib/src/screens/cart/cart_screen.dart`)
   - Shopping cart items list
   - Quantity controls
   - Item removal
   - Total price display
   - Checkout button

6. **Checkout Screen** (`lib/src/screens/checkout/checkout_screen.dart`)
   - Order summary
   - Address input
   - Date and time selection
   - Additional notes
   - Payment navigation

7. **Payment Screen** (`lib/src/screens/payment/payment_screen.dart`)
   - Payment method selection
   - Card details form
   - Payment processing
   - Success handling

8. **My Bookings Screen** (`lib/src/screens/my_bookings/my_bookings_screen.dart`)
   - Booking list with expandable cards
   - Booking status tracking
   - Service details
   - Actions: Pay, Reschedule, Cancel, Rate, Report

9. **Settings Screen** (`lib/src/screens/settings/settings_screen.dart`)
   - Account settings
   - Support options
   - App information
   - Logout functionality

10. **My Profile Screen** (`lib/src/screens/settings/my_profile.dart`)
    - User profile information
    - Name, email, phone, address
    - Profile refresh
    - Error handling

11. **Contact Us Screen** (`lib/src/screens/settings/contact_us.dart`)
    - Contact information
    - Support options
    - Help resources

12. **About Us Screen** (`lib/src/screens/about/about_us.dart`)
    - Company information
    - Mission and values
    - Team details (if applicable)

## Screen Categories

### By Function
- **Authentication**: Login, Onboarding
- **Discovery**: Home, Service Detail
- **Shopping**: Cart, Checkout, Payment
- **Management**: My Bookings, Settings, My Profile
- **Information**: Contact Us, About Us

### By User Flow
1. **First Time User**: Login → Onboarding → Home
2. **Returning User**: Login → Home
3. **Shopping Flow**: Home → Service Detail → Cart → Checkout → Payment
4. **Booking Management**: Home → My Bookings
5. **Profile Management**: Home → Settings → My Profile

## Design Style Requirements

All screens should follow these design principles:
- ✅ **Fluid**: Smooth transitions and animations
- ✅ **Modern**: Contemporary design patterns
- ✅ **Animated**: Micro-interactions and transitions
- ✅ **Clean**: Generous whitespace and clear hierarchy
- ✅ **Dark/Light Mode**: Full theme support
- ✅ **Card Designs**: Elevated cards with shadows and rounded corners

## Design Prompts

Detailed design prompts for each screen are available in:
📄 **[UI_DESIGN_PROMPTS.md](./UI_DESIGN_PROMPTS.md)**

---

**Total Screens**: 12
**Last Updated**: 2024

