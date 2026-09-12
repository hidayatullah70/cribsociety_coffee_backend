const dashboardService = require('../services/dashboardService');
const { sendSuccess } = require('../utils/response');

async function getSummary(req, res, next) {
  try {
    const { from, to } = req.query;
    const summary = await dashboardService.getSummary({ from, to });
    return sendSuccess(res, summary, 200);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getSummary,
};
