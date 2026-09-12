const jwt = require('jsonwebtoken');
const config = require('../config/env');

function signToken(payload, expiresIn = config.JWT.EXPIRES_IN) {
  return jwt.sign(payload, config.JWT.SECRET, { expiresIn });
}

function verifyToken(token) {
  return jwt.verify(token, config.JWT.SECRET);
}

module.exports = {
  signToken,
  verifyToken,
};
