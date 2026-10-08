const jwt = require("jsonwebtoken");
const User = require("../models/User");
const { error } = require("../helpers/response");

const verifyJWT = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return error(res, "Access denied. No token provided.", 401);

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id).select("-password");
    if (!user || user.isDeleted) return error(res, "User not found or account deactivated.", 401);

    req.user = user;
    next();
  } catch (err) {
    return error(res, "Invalid or expired token.", 401);
  }
};

module.exports = { verifyJWT };
