# Firebase Authentication Flow

A complete Flutter authentication system using Firebase Authentication with email and password.

## Features

✅ **User Registration** - New users can create an account with email and password
✅ **User Login** - Existing users can log in with their credentials
✅ **Error Handling** - User-friendly error messages for all scenarios
✅ **Form Validation** - Email and password validation
✅ **Secure Passwords** - Password visibility toggle, minimum 6 characters
✅ **Session Management** - Users remain logged in across app restarts
✅ **Logout** - Users can securely log out from the app

## Business Rules

1. **New User Registration**
   - A new user must register first before logging in
   - Same email cannot be registered twice
   - Error: "Account already exists. Please log in."

2. **User Login**
   - Existing users can log in directly
   - Error for non-existent email: "User not found. Please register first."
   - Error for wrong password: "Incorrect password. Please try again."

3. **Account Protection**
   - Minimum password length: 6 characters
   - Error: "Password must be at least 6 characters"
   - Valid email format required
   - Error: "Please enter a valid email"

## File Structure

```
lib/
├── main.dart                          # App entry point & auth state management
├── services/
│   └── auth_service.dart             # Firebase authentication logic
├── screens/
│   ├── login_screen.dart             # Login form & logic
│   ├── register_screen.dart          # Registration form & logic
│   └── home_screen.dart              # Authenticated home screen
└── firebase_options.dart             # Auto-generated Firebase config
```

## Code Overview

### AuthService (`lib/services/auth_service.dart`)

Handles all Firebase authentication operations:

```dart
// Register new user
await authService.registerWithEmailPassword(
  email: 'user@example.com',
  password: 'password123'
);

// Login existing user
await authService.loginWithEmailPassword(
  email: 'user@example.com',
  password: 'password123'
);

// Logout
await authService.logout();

// Get current user
final user = authService.currentUser;

// Stream auth state changes
authService.authStateChanges.listen((user) {
  // Handle auth state changes
});
```

### Error Handling

All FirebaseAuthException codes are handled:

- `email-already-in-use` → "Account already exists. Please log in."
- `weak-password` → "The password provided is too weak."
- `invalid-email` → "The email address is invalid."
- `user-not-found` → "User not found. Please register first."
- `wrong-password` → "Incorrect password. Please try again."
- `invalid-credential` → "User not found. Please register first."

### Navigation Flow

```
LoginScreen ↔ RegisterScreen
     ↓
  HomeScreen
(after successful login/registration)
```

- **LoginScreen**: Entry point for existing users
- **RegisterScreen**: For new user sign-ups
- **HomeScreen**: Displays user's email and logout button
- Auto-redirect based on auth state using `StreamBuilder`

## Form Validation

Both screens include client-side validation:

- **Email**: Non-empty, valid email format
- **Password**: Non-empty, minimum 6 characters
- **Confirm Password** (Register only): Must match password field

## UI Components

- **TextField**: Email and password inputs with icons
- **ElevatedButton**: Login/Register actions with loading state
- **SnackBar**: Error/success messages
- **Text Links**: Navigate between Login/Register screens
- **Logout Dialog**: Confirmation before signing out

## Usage

### Running the App

```bash
flutter pub get
flutter run
```

### Testing the Flow

1. **Register a new account**
   - Click "Register" link on login screen
   - Enter email and password (min 6 chars)
   - Verify account with same email cannot register again

2. **Login**
   - Use registered email and password
   - Non-existent email shows proper error
   - Wrong password shows proper error

3. **Logout**
   - Click logout button in app bar
   - Confirm logout in dialog
   - Returns to login screen

## Error Messages

| Scenario | Error Message |
|----------|---------------|
| Register with existing email | "Account already exists. Please log in." |
| Login with non-existent email | "User not found. Please register first." |
| Login with wrong password | "Incorrect password. Please try again." |
| Weak password | "The password provided is too weak." |
| Invalid email format | "Please enter a valid email" |
| Empty email field | "Email is required" |
| Empty password field | "Password is required" |
| Password < 6 characters | "Password must be at least 6 characters" |
| Passwords don't match (register) | "Passwords do not match" |

## Dependencies

- `firebase_core: ^2.24.0` - Firebase core functionality
- `firebase_auth: ^4.14.0` - Firebase authentication

## Security Considerations

✅ Passwords never logged or displayed in console
✅ Email trimmed to prevent whitespace issues
✅ Password minimum length enforced (6 characters)
✅ Session persisted securely by Firebase
✅ Proper error handling without exposing sensitive info
✅ Loading states prevent multiple submissions
✅ Form validation before API calls

## Future Enhancements

- [ ] Email verification
- [ ] Password reset/forgot password
- [ ] Social login (Google, GitHub)
- [ ] Two-factor authentication
- [ ] User profile management
- [ ] Remember me checkbox
- [ ] Rate limiting for failed attempts
