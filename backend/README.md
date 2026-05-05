# CocoScan Backend

A simple Node.js Express backend for the CocoScan Flutter app.

## Features
- POST `/auth/login` — authenticate demo users
- POST `/auth/register` — create a new account
- GET `/users/me` — return authenticated user details
- GET `/scans` — return scan history for the signed-in user
- POST `/predict` — upload an image and receive a simulated plant disease prediction

## Run locally
1. Install dependencies
   ```bash
   cd backend
   npm install
   ```
2. Start server
   ```bash
   npm start
   ```
3. API runs on `http://localhost:3000`

## Example login request
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"farmer@cocoscan.lk","password":"demo123","role":"Farmer"}'
```

## Flutter integration notes
- Base URL: `http://10.0.2.2:3000` for Android emulator
- Send `x-auth-token` in request headers for authenticated endpoints
- Use `multipart/form-data` for `/predict` image uploads
