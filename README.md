 หs,ำไำำำำำำำำำำำำำำำภำำำำำำำำำำeee# Clinic Membership App

A Flutter application for clinic membership management with Thai language support.

## Features

- **Login System**: Secure authentication with email/password
- **Home Dashboard**: Membership progress tracking and product management
- **Product Checkout**: Complete shopping cart with payment options
- **Rewards System**: Member rewards tracking and redemption
- **Profile Management**: User profile and settings
- **Membership Levels**: Progressive membership system with benefits
- **Thai Language Support**: Full Thai language interface

## Screens

1. **Login Screen** - User authentication
2. **Home Screen** - Main dashboard with membership progress
3. **Checkout Screen** - Shopping cart and payment processing
4. **Rewards Screen** - Reward management and history
5. **Profile Screen** - User profile and menu options

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Add required assets:
   - Place font files in `assets/fonts/`
   - Place image files in `assets/images/`
   - Place icon files in `assets/icons/`

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── constants/          # App constants (colors, text styles)
├── models/            # Data models
├── screens/           # Screen widgets
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── checkout_screen.dart
│   ├── rewards_screen.dart
│   └── profile_screen.dart
├── widgets/           # Reusable widgets
└── main.dart         # App entry point
```

## Assets Required

### Fonts
- Prompt-Regular.ttf
- Prompt-Medium.ttf
- Prompt-SemiBold.ttf

### Images
- white-logo.png
- exmember-logo.png
- product1.png - product4.png

## Key Features

### Membership System
- Progressive levels (Level 1, 2, 3)
- Progress tracking
- Reward benefits per level

### Product Management
- Product categories with quantities
- Shopping cart functionality
- Price calculations with discounts

### Payment Integration
- Multiple payment methods
- Credit/Debit cards
- Bank transfer
- PromptPay QR code

### Rewards System
- Reward item selection
- Usage tracking
- Redemption history
- Expiration management

## Customization

- Colors can be modified in `lib/constants/app_colors.dart`
- Text styles can be adjusted in `lib/constants/app_text_styles.dart`
- Add new screens in `lib/screens/`
- Create reusable widgets in `lib/widgets/`

## Thai Language Support

The app includes full Thai language support with proper font rendering using the Prompt font family.

## Navigation

The app uses a bottom navigation bar for main sections and standard navigation for detailed screens. All navigation is handled through Flutter's built-in navigation system.