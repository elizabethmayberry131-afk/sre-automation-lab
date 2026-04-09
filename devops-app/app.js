const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({
    message: "DevOps Project Running 🚀",
    status: "Healthy",
    server_time: new Date()
  });
});

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});
