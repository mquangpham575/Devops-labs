const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.json({
        message: "Hello from DevOps Lab 2 Microservice!",
        status: "healthy",
        timestamp: new Date()
    });
});

app.get('/health', (req, res) => {
    res.status(200).json({ status: "UP" });
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
