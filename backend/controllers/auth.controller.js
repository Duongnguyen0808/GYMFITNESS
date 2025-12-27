import User from "../models/User.model.js";
import { generateToken } from "../utils/generateToken.js";
import emailService from "../services/emailService.js";

/**
 * @desc    Register new user (Step 1: Create user and send OTP)
 * @route   POST /api/auth/register
 * @access  Public
 */
export const register = async (req, res) => {
  try {
    const {
      email,
      password,
      name,
      gender,
      dateOfBirth,
      currentWeight,
      currentHeight,
      goalWeight,
      weightUnit,
      heightUnit,
      activeFrequency,
      ...otherFields
    } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) {
      // Nếu user chưa verify, cho phép gửi lại OTP
      if (!userExists.isEmailVerified) {
        const otp = emailService.generateOTP();
        userExists.emailOTP = otp;
        userExists.emailOTPExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 phút
        await userExists.save();

        await emailService.sendVerificationEmail(email, otp, userExists.name);

        return res.status(200).json({
          success: true,
          message: "Mã xác thực đã được gửi lại đến email của bạn",
          data: {
            email: email,
            requireVerification: true,
          },
        });
      }

      return res.status(400).json({
        success: false,
        message: "Email này đã được đăng ký",
      });
    }

    const userName = name || email.split("@")[0] || "User";

    // Tạo OTP
    const otp = emailService.generateOTP();

    const user = await User.create({
      email,
      password,
      name: userName,
      gender: gender || "other",
      dateOfBirth: dateOfBirth || new Date("2000-01-01"),
      currentWeight: currentWeight || 70,
      currentHeight: currentHeight || 170,
      goalWeight: goalWeight || 65,
      weightUnit: weightUnit || "kg",
      heightUnit: heightUnit || "cm",
      activeFrequency: activeFrequency || "moderate",
      isEmailVerified: false,
      emailOTP: otp,
      emailOTPExpires: new Date(Date.now() + 10 * 60 * 1000), // 10 phút
      ...otherFields,
    });

    if (user) {
      // Gửi email xác thực
      await emailService.sendVerificationEmail(email, otp, userName);

      res.status(201).json({
        success: true,
        message:
          "Đăng ký thành công! Vui lòng kiểm tra email để lấy mã xác thực",
        data: {
          email: email,
          requireVerification: true,
        },
      });
    } else {
      res.status(400).json({
        success: false,
        message: "Không thể tạo tài khoản",
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * @desc    Verify email with OTP (Step 2)
 * @route   POST /api/auth/verify-email
 * @access  Public
 */
export const verifyEmail = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng cung cấp email và mã OTP",
      });
    }

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy tài khoản với email này",
      });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({
        success: false,
        message: "Email đã được xác thực trước đó",
      });
    }

    // Kiểm tra OTP hết hạn
    if (!user.emailOTPExpires || user.emailOTPExpires < new Date()) {
      return res.status(400).json({
        success: false,
        message: "Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới",
      });
    }

    // Kiểm tra OTP đúng không
    if (user.emailOTP !== otp) {
      return res.status(400).json({
        success: false,
        message: "Mã OTP không chính xác",
      });
    }

    // Xác thực thành công
    user.isEmailVerified = true;
    user.emailOTP = null;
    user.emailOTPExpires = null;
    await user.save();

    res.status(200).json({
      success: true,
      message: "Xác thực email thành công!",
      data: {
        user: user.toJSON(),
        token: generateToken(user._id),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * @desc    Resend OTP
 * @route   POST /api/auth/resend-otp
 * @access  Public
 */
export const resendOTP = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng cung cấp email",
      });
    }

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy tài khoản với email này",
      });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({
        success: false,
        message: "Email đã được xác thực",
      });
    }

    // Tạo OTP mới
    const otp = emailService.generateOTP();
    user.emailOTP = otp;
    user.emailOTPExpires = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();

    // Gửi email
    await emailService.sendVerificationEmail(email, otp, user.name);

    res.status(200).json({
      success: true,
      message: "Mã xác thực mới đã được gửi đến email của bạn",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * @desc    Forgot Password - Send OTP
 * @route   POST /api/auth/forgot-password
 * @access  Public
 */
export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng cung cấp email",
      });
    }

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy tài khoản với email này",
      });
    }

    // Tạo OTP
    const otp = emailService.generateOTP();
    user.resetPasswordOTP = otp;
    user.resetPasswordOTPExpires = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();

    // Gửi email
    await emailService.sendPasswordResetEmail(email, otp, user.name);

    res.status(200).json({
      success: true,
      message: "Mã xác thực đã được gửi đến email của bạn",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * @desc    Reset Password with OTP
 * @route   POST /api/auth/reset-password
 * @access  Public
 */
export const resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng cung cấp email, mã OTP và mật khẩu mới",
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Mật khẩu phải có ít nhất 6 ký tự",
      });
    }

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy tài khoản với email này",
      });
    }

    // Kiểm tra OTP hết hạn
    if (
      !user.resetPasswordOTPExpires ||
      user.resetPasswordOTPExpires < new Date()
    ) {
      return res.status(400).json({
        success: false,
        message: "Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới",
      });
    }

    // Kiểm tra OTP
    if (user.resetPasswordOTP !== otp) {
      return res.status(400).json({
        success: false,
        message: "Mã OTP không chính xác",
      });
    }

    // Đặt mật khẩu mới
    user.password = newPassword;
    user.resetPasswordOTP = null;
    user.resetPasswordOTPExpires = null;
    await user.save();

    res.status(200).json({
      success: true,
      message: "Đặt lại mật khẩu thành công!",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * @desc    Login user
 * @route   POST /api/auth/login
 * @access  Public
 */
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng nhập email và mật khẩu",
      });
    }

    const user = await User.findOne({ email }).select("+password");

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Email hoặc mật khẩu không đúng",
      });
    }

    const isMatch = await user.comparePassword(password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Email hoặc mật khẩu không đúng",
      });
    }

    // Kiểm tra email đã verify chưa
    if (!user.isEmailVerified) {
      // Email chưa verify - yêu cầu đăng ký lại
      return res.status(401).json({
        success: false,
        message:
          "Email chưa được xác thực. Vui lòng đăng ký lại để nhận mã xác thực mới.",
      });
    }

    res.status(200).json({
      success: true,
      data: {
        user: user.toJSON(),
        token: generateToken(user._id),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * @desc    Get current logged in user
 * @route   GET /api/auth/me
 * @access  Private
 */
export const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * @desc    Admin Login - only for admin role
 * @route   POST /api/auth/admin/login
 * @access  Public
 */
export const adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Please provide email and password",
      });
    }

    const user = await User.findOne({ email }).select("+password");

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Invalid credentials",
      });
    }

    // Check if user is admin
    if (user.role !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Admin privileges required.",
      });
    }

    const isMatch = await user.comparePassword(password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Invalid credentials",
      });
    }

    res.status(200).json({
      success: true,
      data: {
        user: user.toJSON(),
        token: generateToken(user._id),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * @desc    Create admin account (only existing admin can create)
 * @route   POST /api/auth/admin/create
 * @access  Private/Admin
 */
export const createAdmin = async (req, res) => {
  try {
    const { email, password, name } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({
        success: false,
        message: "User already exists",
      });
    }

    const user = await User.create({
      email,
      password,
      name: name || email.split("@")[0],
      role: "admin",
    });

    res.status(201).json({
      success: true,
      data: {
        user: user.toJSON(),
      },
      message: "Admin account created successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
