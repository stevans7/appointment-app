const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  nom: { 
    type: String, 
    required: true 
  },
  prenom: { 
    type: String, 
    required: true 
  },
  email: String,
  tel: String,
  motif: { 
    type: String, 
    required: true 
  },
  date: { 
    type: String, 
    required: true 
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('Appointment', appointmentSchema);