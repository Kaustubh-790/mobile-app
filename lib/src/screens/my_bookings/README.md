# My Bookings Screen

This directory contains the My Bookings screen implementation for the Flutter mobile app.

## Overview

The My Bookings screen displays all user bookings with comprehensive details including:

- Booking information (ID, status, amount, date, location)
- Service details with individual status tracking
- Worker assignment information
- Progress tracking for completed services
- Actions like reschedule, cancel, rate, and report

## Files Structure

```
widgets/
├── index.dart                    # Exports all widgets
├── booking_card.dart            # Main booking card with expandable details
├── service_details_section.dart # Services list section
├── service_item_card.dart       # Individual service item card
├── rating_modal.dart            # Rating and review modal
├── reschedule_modal.dart        # Service reschedule modal
└── cancel_booking_modal.dart    # Booking cancellation modal
```

## Features

### 1. Booking Display

- Shows booking ID, status, total amount, and completion progress
- Displays booking date, time, and location
- Progress bar showing completed vs total services

### 2. Service Management

- Expandable service details
- Individual service status tracking
- Service-specific actions (reschedule, rate, report)
- Worker assignment information

### 3. Actions Available

- **View Details**: Expand/collapse service information
- **Pay Now**: For unpaid bookings
- **Reschedule**: Reschedule services (max 2 times)
- **Cancel**: Cancel entire booking with reason
- **Rate & Review**: Rate completed services
- **Report**: Report issues with services

### 4. Status Tracking

- Visual status indicators with colors
- Progress tracking for service completion
- Real-time status updates

## Usage

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'path/to/my_bookings_screen.dart';

// Navigate to My Bookings screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MyBookingsScreen(),
  ),
);
```

### Required Providers

Make sure these providers are available in your app:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => BookingProvider()),
  ],
  child: MyApp(),
)
```

## API Integration

The screen integrates with the following API endpoints:

- `GET /bookings/user/{userId}` - Fetch user bookings
- `POST /bookings/{id}/services/{index}/rate` - Rate service
- `POST /bookings/{id}/services/{index}/reschedule` - Reschedule service
- `DELETE /bookings/{id}` - Cancel booking

## Styling

The screen uses a dark theme with:

- Primary color: `#8C11FF` (Purple)
- Background: `#0F0F23` (Dark blue)
- Card backgrounds: Semi-transparent whites
- Status-specific colors for different states

## Future Enhancements

- Real-time updates using WebSocket/SSE
- Push notifications for status changes
- Offline support with local caching
- Advanced filtering and sorting options
- Export booking history
- Integration with calendar apps

## Dependencies

- `provider` - State management
- `flutter` - Core Flutter framework

## Notes

- All modals are currently using placeholder API calls
- Worker location tracking is not implemented
- Payment integration needs to be connected
- Error handling can be enhanced for production use
