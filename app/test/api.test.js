const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const app = require('../app');

let mongoServer;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri(), { useNewUrlParser: true, useUnifiedTopology: true });
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('API Tests', () => {
  test('GET /health should return UP status', async () => {
    const response = await request(app).get('/health');
    expect(response.statusCode).toBe(200);
    expect(response.body).toEqual({ status: 'UP' });
  });

  test('GET /metrics should return Prometheus metrics', async () => {
    const response = await request(app).get('/metrics');
    expect(response.statusCode).toBe(200);
    expect(response.text).toContain('requests_total');
  });

  test('POST /api/appointment should create appointment', async () => {
    const appointmentData = {
      nom: 'Dupont',
      prenom: 'Jean',
      motif: 'Consultation',
      date: '2025-01-01'
    };

    const response = await request(app)
      .post('/api/appointment')
      .send(appointmentData);

    expect(response.statusCode).toBe(200);
    expect(response.body.message).toContain('Rendez-vous enregistré');

    // Verify appointment was saved to MongoDB
    const savedAppointment = await mongoose.model('Appointment').findOne({ nom: 'Dupont' });
    expect(savedAppointment).toBeTruthy();
    expect(savedAppointment.prenom).toBe('Jean');
  });
});