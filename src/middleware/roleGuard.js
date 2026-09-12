const { ApiError } = require('../utils/response');
const ERROR_CODES = require('../constants/errorCodes');
const ROLES = require('../constants/roles');

/**
 * Role authorization guard middleware
 * @param  {...string} allowedRoles 
 */
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return next(new ApiError(401, ERROR_CODES.UNAUTHORIZED, 'Authentication required'));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(
        new ApiError(
          403,
          ERROR_CODES.FORBIDDEN,
          `Access forbidden: requires one of the following roles: [${allowedRoles.join(', ')}]`
        )
      );
    }

    next();
  };
}

const requireOwner = requireRole(ROLES.OWNER);
const requireStaffOrOwner = requireRole(ROLES.OWNER, ROLES.STAFF);

module.exports = {
  requireRole,
  requireOwner,
  requireStaffOrOwner,
};
