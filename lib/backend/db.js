const mysql = require('mysql2/promise');

const pool = mysql.createPool({
    host: 'localhost',     
    user: 'root',           
    password: 'Li$eaga76', 
    database: 'futbol_pro', 
    waitForConnections: true,
    connectionLimit: 10,
});

module.exports = pool;