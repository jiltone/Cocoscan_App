# CocoScan - Firebase Integration Setup

## Overview
CocoScan is now integrated with Firebase for cloud-based authentication, database storage, and file uploads. This provides a more robust and scalable backend solution compared to the local Node.js server.

## Firebase Setup Instructions

### 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `cocoscan-app`
4. Enable Google Analytics (optional)
5. Choose your Google Analytics account
6. Click "Create project"

### 2. Enable Authentication
1. In Firebase Console, go to "Authentication" → "Get started"
2. Go to "Sign-in method" tab
3. Enable "Email/Password" provider
4. (Optional) Configure additional providers like Google, Facebook, etc.

### 3. Set up Firestore Database
1. Go to "Firestore Database" → "Create database"
2. Choose "Start in test mode" (for development)
3. Select a location for your database (e.g., `asia-south1` for Sri Lanka)
4. Click "Done"

### 4. Set up Firebase Storage
1. Go to "Storage" → "Get started"
2. Click "Next" to accept default rules (for development)
3. Select a location (same as Firestore)
4. Click "Done"

### 5. Add Flutter App to Firebase
1. In Firebase Console, click the Flutter icon to add an app
2. Enter app details:
   - Android package name: `com.example.cocoscan` (check your `android/app/build.gradle`)
   - iOS bundle ID: `com.example.cocoscan` (check your `ios/Runner.xcodeproj`)
3. Download and add configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

### 6. Update Firebase Configuration
The app already includes Firebase configuration files, but you may need to update them with your project details:

- `lib/firebase_options.dart` - Contains Firebase project configuration
- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config

## Demo Data Setup

### Option 1: Manual Setup (Recommended for Testing)
1. Create demo users in Firebase Console:
   - Go to Authentication → Users → Add user
   - Create two users:
     - Email: `farmer@cocoscan.lk`, Password: `demo123`
     - Email: `officer@cocoscan.lk`, Password: `demo123`

2. Copy the User UID from Firebase Console for each user

3. Add user profiles to Firestore:
   - Go to Firestore Database → Start collection
   - Collection ID: `users`
   - Document ID: [paste the User UID from step 2]
   - Add fields for each user (see `firebase_demo_setup.js` for sample data)

### Option 2: Programmatic Setup
1. Set up Firebase Admin SDK (requires Node.js)
2. Use the script in `firebase_demo_setup.js` as a reference
3. Update the user IDs with actual Firebase Auth UIDs

## Running the App

### Prerequisites
- Flutter SDK (3.0.0+)
- Android Studio / Xcode for mobile development
- Firebase project set up as above

### Steps
1. Ensure Firebase configuration files are in place
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

### Demo Accounts
- **Farmer**: `farmer@cocoscan.lk` / `demo123`
- **Officer**: `officer@cocoscan.lk` / `demo123`

## Features with Firebase

### Authentication
- User registration and login
- Password reset functionality
- Role-based access (Farmer/Officer)

### Database (Firestore)
- User profiles with stats
- Scan history storage
- Real-time data synchronization

### Storage
- Image upload for disease detection
- Secure file storage with Firebase Storage

### Data Migration
The app automatically migrates from the local backend to Firebase. Existing users and scans will be stored in Firebase going forward.

## Troubleshooting

### Common Issues
1. **Firebase initialization error**: Check that `google-services.json` and `GoogleService-Info.plist` are correctly placed
2. **Authentication fails**: Ensure Email/Password provider is enabled in Firebase Console
3. **Firestore permission denied**: Check Firestore security rules
4. **Storage upload fails**: Verify Storage security rules

### Debug Mode
The app includes debug logging. Check the console for Firebase-related errors.

## Security Notes
- For production, update Firestore and Storage security rules
- Enable Firebase Security Rules to restrict access
- Consider implementing additional security measures like email verification

## Next Steps
- Implement push notifications with Firebase Cloud Messaging
- Add offline data synchronization
- Integrate with Firebase ML for on-device AI processing
- Add analytics with Firebase Analytics

---

For more information, visit the [Firebase Documentation](https://firebase.google.com/docs).