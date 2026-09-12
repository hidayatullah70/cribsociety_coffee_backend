const authService = require('../services/authService');
const { sendSuccess } = require('../utils/response');

async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    const result = await authService.login({ email, password });
    return sendSuccess(res, result, 200);
  } catch (error) {
    next(error);
  }
}

async function logout(req, res, next) {
  try {
    // Stateless JWT logout confirmation
    return sendSuccess(res, { message: 'Logged out successfully' }, 200);
  } catch (error) {
    next(error);
  }
}

async function getMe(req, res, next) {
  try {
    const user = await authService.getMe(req.user.id);
    return sendSuccess(res, { user }, 200);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  login,
  logout,
  getMe,
};
