// Firebase Demo Data Setup Script
// Run this in Firebase Console or create a Node.js script to populate demo data

// Demo Users for Firestore (users collection)
// Note: Firebase Auth users must be created through Firebase Console or Admin SDK

const demoUsers = [
  {
    id: 'demo_farmer_001',
    name: 'Kasun Perera',
    email: 'farmer@cocoscan.lk',
    role: 'Farmer',
    plantation: 'Kurunegala Coconut Plantation',
    phone: '+94 77 123 4567',
    createdAt: new Date(),
    stats: {
      totalScans: 47,
      diseasesFound: 12,
      healthyTrees: 35,
      reportScore: 4.8,
    },
  },
  {
    id: 'demo_officer_001',
    name: 'Dr. Nimal Fernando',
    email: 'officer@cocoscan.lk',
    role: 'Agricultural Officer',
    plantation: '',
    phone: '+94 77 987 6543',
    createdAt: new Date(),
    stats: {
      totalScans: 156,
      diseasesFound: 28,
      healthyTrees: 128,
      reportScore: 4.9,
    },
  },
];

// Demo Scans for Firestore (scans collection)
const demoScans = [
  {
    userId: 'demo_farmer_001',
    disease: 'Leaf Spot',
    tree: 'Tree #A-15',
    confidence: 0.87,
    status: 'CONFIRMED',
    sector: 'Sector A',
    location: 'Row 4, Plot 14',
    model: 'CocoScan AI v2.1 (MobileNet)',
    processingTime: '1.3 seconds',
    createdAt: new Date(Date.now() - 86400000), // 1 day ago
  },
  {
    userId: 'demo_farmer_001',
    disease: 'Healthy',
    tree: 'Tree #B-22',
    confidence: 0.94,
    status: 'HEALTHY',
    sector: 'Sector B',
    location: 'Row 7, Plot 8',
    model: 'CocoScan AI v2.1 (MobileNet)',
    processingTime: '1.1 seconds',
    createdAt: new Date(Date.now() - 172800000), // 2 days ago
  },
  {
    userId: 'demo_officer_001',
    disease: 'Bud Rot',
    tree: 'Tree #C-5',
    confidence: 0.91,
    status: 'CONFIRMED',
    sector: 'Sector C',
    location: 'Row 2, Plot 19',
    model: 'CocoScan AI v2.1 (MobileNet)',
    processingTime: '1.4 seconds',
    createdAt: new Date(Date.now() - 259200000), // 3 days ago
  },
];

// Instructions for setting up demo data:
//
// 1. Create Firebase Auth users manually in Firebase Console:
//    - Email: farmer@cocoscan.lk, Password: demo123
//    - Email: officer@cocoscan.lk, Password: demo123
//
// 2. Copy the user IDs from Firebase Auth and update the demoUsers array
//
// 3. Run this script in Firebase Console or create a Node.js script:
//    - Install Firebase Admin SDK: npm install firebase-admin
//    - Initialize Firebase Admin with your service account key
//    - Run the script to populate Firestore collections
//
// Example Node.js script:
/*
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function populateDemoData() {
  try {
    // Add demo users
    for (const user of demoUsers) {
      await db.collection('users').doc(user.id).set(user);
      console.log(`Added user: ${user.name}`);
    }

    // Add demo scans
    for (const scan of demoScans) {
      await db.collection('scans').add(scan);
      console.log(`Added scan for user: ${scan.userId}`);
    }

    console.log('Demo data populated successfully!');
  } catch (error) {
    console.error('Error populating demo data:', error);
  }
}

populateDemoData();
*/

export { demoUsers, demoScans };