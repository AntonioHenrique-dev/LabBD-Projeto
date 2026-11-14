require('dotenv').config();
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'condominio',
  connectionLimit: 10,
  dateStrings: true,
});

async function usuarioConectado() {
  const [linhas] = await pool.query(
    'SELECT CURRENT_USER() AS usuario, DATABASE() AS banco, VERSION() AS versao'
  );
  return linhas[0];
}

module.exports = { pool, usuarioConectado };
