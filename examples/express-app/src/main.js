const express = require('express');
const morgan = require('morgan');
const winston = require('winston');

const HOST = process.env.APP_HOST || '0.0.0.0';
const PORT = process.env.APP_PORT || 3000;

const logger = winston.createLogger({
  transports: [
    new winston.transports.Console(),
  ]
});

const app = express();

app.use(morgan(':method :url :status :res[content-length] - :response-time ms'));

app.get('/', (req, res) => {
  res.json({ url: req.originalUrl });
});

app.listen(PORT, HOST, () => logger.info(`Listening on http://${HOST}:${PORT}`));
