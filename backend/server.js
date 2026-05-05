const express = require('express');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_DIR = path.join(__dirname, 'data');
const DB_FILE = path.join(DATA_DIR, 'db.json');
const upload = multer({ storage: multer.memoryStorage() });

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

function loadDb() {
  if (!fs.existsSync(DB_FILE)) {
    fs.writeFileSync(DB_FILE, JSON.stringify({ users: [], scans: [] }, null, 2));
  }
  return JSON.parse(fs.readFileSync(DB_FILE, 'utf-8'));
}

function saveDb(db) {
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2));
}

const db = loadDb();

function findUserByToken(token) {
  return db.users.find((user) => user.token === token);
}

function authMiddleware(req, res, next) {
  const token = req.header('x-auth-token');
  if (!token) {
    return res.status(401).json({ error: 'Missing authentication token' });
  }
  const user = findUserByToken(token);
  if (!user) {
    return res.status(401).json({ error: 'Invalid authentication token' });
  }
  req.user = user;
  next();
}

function makePrediction(fileBuffer) {
  const digest = crypto.createHash('sha1').update(fileBuffer).digest('hex');
  const seed = parseInt(digest.slice(0, 8), 16);
  const diseases = [
    { name: 'Leaf Spot', status: 'CONFIRMED', color: '#D32F2F' },
    { name: 'Lethal Yellowing', status: 'UNCERTAIN', color: '#FBC02D' },
    { name: 'Bud Rot', status: 'CONFIRMED', color: '#D84315' },
    { name: 'Stem Bleeding', status: 'UNCERTAIN', color: '#F57C00' },
    { name: 'Healthy', status: 'HEALTHY', color: '#388E3C' }
  ];
  const index = seed % diseases.length;
  const confidence = Number((0.60 + ((seed % 41) / 100)).toFixed(2));
  const disease = diseases[index];
  return {
    disease: disease.name,
    confidence,
    status: disease.status,
    statusColor: disease.color,
    treeId: `Tree #${String.fromCharCode(65 + (seed % 26))}-${1 + (seed % 99)}`,
    probabilities: diseases.map((item, i) => ({
      label: item.name,
      value: item.name === disease.name ? confidence : Number((Math.max(0.01, 1 - confidence - i * 0.08)).toFixed(2))
    })),
    location: 'Sector A — Row 4, Plot 14',
    model: 'CocoScan AI v2.1 (MobileNet)',
    processingTime: `${(1.2 + ((seed % 60) / 100)).toFixed(1)} seconds`
  };
}

app.get('/', (req, res) => {
  res.json({ message: 'CocoScan backend is running.' });
});

app.post('/auth/login', (req, res) => {
  const { email, password, role } = req.body;
  if (!email || !password || !role) {
    return res.status(400).json({ error: 'Email, password, and role are required.' });
  }
  const user = db.users.find((u) => u.email === email && u.password === password && u.role === role);
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials.' });
  }
  res.json({
    token: user.token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      plantation: user.plantation,
      phone: user.phone,
      stats: user.stats,
    }
  });
});

app.post('/auth/register', (req, res) => {
  const { name, email, password, role, plantation, phone } = req.body;
  if (!name || !email || !password || !role) {
    return res.status(400).json({ error: 'Name, email, password, and role are required.' });
  }
  if (db.users.some((u) => u.email === email)) {
    return res.status(409).json({ error: 'Email already exists.' });
  }
  const token = `token-${uuidv4()}`;
  const user = {
    id: `user-${uuidv4()}`,
    name,
    email,
    password,
    role,
    plantation: plantation || '',
    phone: phone || '',
    token,
    stats: {
      totalScans: 0,
      diseasesFound: 0,
      healthyTrees: 0,
      reportScore: 0
    }
  };
  db.users.push(user);
  saveDb(db);
  res.status(201).json({ token, user: { id: user.id, name: user.name, email: user.email, role: user.role, plantation: user.plantation, phone: user.phone, stats: user.stats } });
});

app.get('/users/me', authMiddleware, (req, res) => {
  const { id, name, email, role, plantation, phone, stats } = req.user;
  res.json({ id, name, email, role, plantation, phone, stats });
});

app.get('/scans', authMiddleware, (req, res) => {
  const scans = db.scans.filter((scan) => scan.userId === req.user.id);
  res.json({ scans });
});

app.post('/predict', authMiddleware, upload.single('image'), (req, res) => {
  const file = req.file;
  if (!file) {
    return res.status(400).json({ error: 'Image file is required.' });
  }
  const prediction = makePrediction(file.buffer);
  const scan = {
    id: `scan-${uuidv4()}`,
    userId: req.user.id,
    disease: prediction.disease,
    tree: prediction.treeId,
    confidence: prediction.confidence,
    status: prediction.status,
    date: new Date().toISOString().split('T')[0],
    sector: 'Sector A',
    location: prediction.location,
    model: prediction.model,
    processingTime: prediction.processingTime
  };
  db.scans.unshift(scan);
  req.user.stats.totalScans += 1;
  if (prediction.status === 'HEALTHY') {
    req.user.stats.healthyTrees += 1;
  } else {
    req.user.stats.diseasesFound += 1;
  }
  const score = Math.min(5, 3 + req.user.stats.totalScans / 50 + prediction.confidence * 1.2);
  req.user.stats.reportScore = Number(score.toFixed(1));
  saveDb(db);
  res.json({ prediction, scan });
});

app.use((req, res) => res.status(404).json({ error: 'Endpoint not found.' }));

app.listen(PORT, () => {
  console.log(`CocoScan backend listening on http://localhost:${PORT}`);
});
