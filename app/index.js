require('dotenv').config();


const express = require('express');
const nodemailer = require('nodemailer');
const bodyParser = require('body-parser');
const path = require('path');
const mongoose = require('mongoose');
const promClient = require('prom-client');

// Prometheus metrics setup
const collectDefaultMetrics = promClient.collectDefaultMetrics;
const Registry = promClient.Registry;
const register = new Registry();
collectDefaultMetrics({ register });

// Custom metrics
const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status'],
  registers: [register]
});

const appointmentCounter = new promClient.Counter({
  name: 'appointments_created_total',
  help: 'Total number of appointments created',
  registers: [register]
});

const app = express();
const port = process.env.PORT || 3000;

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/appointments';
mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => {
  console.log('📊 Connected to MongoDB');
}).catch(err => {
  console.error('❌ MongoDB connection error:', err);
});

// Import models
const Appointment = require('./models/appointment');

// Middleware to count HTTP requests
app.use((req, res, next) => {
  res.on('finish', () => {
    httpRequestsTotal.inc({
      method: req.method,
      route: req.route ? req.route.path : req.path,
      status: res.statusCode
    });
  });
  next();
});

// Serve static frontend
app.use(express.static(path.join(__dirname, 'public')));
app.use(bodyParser.json());

// Simple in-memory rate limiter to avoid spam during demo (very small)
let lastSubmission = 0;

// Configure transporter using environment variables
const mailUser = process.env.MAIL_USER || '';
const mailPass = process.env.MAIL_PASS || '';
const mailTo   = process.env.MAIL_TO || mailUser; // receive at same user by default

if (!mailUser || !mailPass) {
  console.warn('⚠️ MAIL_USER or MAIL_PASS not set. Emails will fail until configured.');
}

const transporter = nodemailer.createTransport({
  service: process.env.MAIL_SERVICE || 'gmail',
  auth: {
    user: mailUser,
    pass: mailPass
  }
});

app.get('/health', async (req, res) => {
  // Check MongoDB connection
  const dbStatus = mongoose.connection.readyState === 1 ? 'UP' : 'DOWN';
  res.json({ 
    status: 'UP',
    database: dbStatus,
    timestamp: new Date().toISOString()
  });
});

app.get('/metrics', (req, res) => {
  res.set('Content-Type', register.contentType);
  register.metrics().then(metrics => res.end(metrics));
});

app.post('/api/appointment', async (req, res) => {
  try {
    const now = Date.now();
    if (now - lastSubmission < 3000) {
      return res.status(429).json({ error: 'Too many requests, please wait a few seconds.' });
    }

    const { nom, prenom, email, tel, motif, date } = req.body || {};
    if (!nom || !prenom || !motif || !date) {
      return res.status(400).json({ error: 'Tous les champs sont requis' });
    }

    // Save to MongoDB
    const appointment = new Appointment({
      nom,
      prenom,
      email,
      tel,
      motif,
      date
    });
    
    await appointment.save();
    appointmentCounter.inc(); // Increment appointment counter

    const mailOptions = {
      from: mailUser,
      to: mailTo,
      subject: '📅 Nouveau rendez-vous reçu',
      text: `Nouveau rendez-vous :\nNom : ${nom}\nPrénom : ${prenom}\nEmail : ${email || 'Non renseigné'}\nTéléphone : ${tel || 'Non renseigné'}\nMotif : ${motif}\nDate : ${date}`
    };

    if (!mailUser || !mailPass) {
      console.error('Mail credentials not set; skipping sendMail (demo mode).');
      lastSubmission = now;
      return res.json({ message: 'Rendez-vous enregistré (mode demo, mail non envoyé). Vérifiez les variables d\'environnement.' });
    }

    await transporter.sendMail(mailOptions);
    lastSubmission = now;
    res.json({ message: 'Rendez-vous enregistré et email envoyé ✅' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Erreur lors du traitement de la demande' });
  }
});

// API to get all appointments (for admin)
app.get('/api/appointments', async (req, res) => {
  try {
    const appointments = await Appointment.find().sort({ createdAt: -1 });
    res.json(appointments);
  } catch (err) {
    console.error('Error fetching appointments:', err);
    res.status(500).json({ error: 'Erreur lors de la récupération des rendez-vous' });
  }
});

// Fallback route serves index.html (SPA-like)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Export for testing
module.exports = app;

// Only start server if this file is run directly
if (require.main === module) {
  app.listen(port, () => {
    console.log(`📅 Appointment app listening on port ${port}`);
  });
}
