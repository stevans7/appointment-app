require('dotenv').config();  // Charge les variables d'environnement

console.log('MAIL_USER:', process.env.MAIL_USER);
console.log('MAIL_PASS:', process.env.MAIL_PASS ? '***' : 'not set');

const app = require('./index');

module.exports = app;
