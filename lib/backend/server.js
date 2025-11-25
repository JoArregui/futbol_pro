const express = require('express');
const authRoutes = require('./routes/auth'); 
const fieldRoutes = require('./routes/fields'); 
const leagueRoutes = require('./routes/leagues'); 
const userRoutes = require('./routes/users');
const chatRoutes = require('./routes/chats'); 
// 🟢 NUEVO: Importar las rutas de partidos
const matchRoutes = require('./routes/matches'); 

const app = express();
const PORT = 3000;

// Middleware para procesar JSON
app.use(express.json());

// Montar rutas de autenticación
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/fields', fieldRoutes); 
app.use('/api/v1/leagues', leagueRoutes); 
app.use('/api/v1/users', userRoutes); 
app.use('/api/v1/chats', chatRoutes); 

// 🟢 NUEVO: Montar rutas de partidos
app.use('/api/v1/matches', matchRoutes); 

app.listen(PORT, '0.0.0.0', () => { 
    console.log(`Servidor corriendo en http://localhost:${PORT}`);
});