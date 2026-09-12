const staffService = require('../services/staffService');
const { sendSuccess } = require('../utils/response');

async function getAllStaff(req, res, next) {
  try {
    const staff = await staffService.getAllStaff();
    return sendSuccess(res, { staff }, 200);
  } catch (error) {
    next(error);
  }
}

async function getStaffById(req, res, next) {
  try {
    const { id } = req.params;
    const staff = await staffService.getStaffById(id);
    return sendSuccess(res, { staff }, 200);
  } catch (error) {
    next(error);
  }
}

async function createStaff(req, res, next) {
  try {
    const staff = await staffService.createStaff(req.body, req.user);
    return sendSuccess(res, { staff }, 201);
  } catch (error) {
    next(error);
  }
}

async function updateStaff(req, res, next) {
  try {
    const { id } = req.params;
    const staff = await staffService.updateStaff(id, req.body, req.user);
    return sendSuccess(res, { staff }, 200);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllStaff,
  getStaffById,
  createStaff,
  updateStaff,
};
