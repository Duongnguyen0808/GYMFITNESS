import nodemailer from "nodemailer";
import dotenv from "dotenv";

dotenv.config();

/**
 * Email Service
 * Sử dụng Gmail SMTP để gửi email
 */
class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD, // App Password từ Google
      },
    });
  }

  /**
   * Tạo mã OTP 6 số ngẫu nhiên
   * @returns {string} Mã OTP 6 số
   */
  generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  /**
   * Gửi email xác thực OTP
   * @param {string} toEmail - Email người nhận
   * @param {string} otp - Mã OTP
   * @param {string} userName - Tên người dùng
   * @returns {Promise<boolean>} Kết quả gửi email
   */
  async sendVerificationEmail(toEmail, otp, userName = "User") {
    try {
      const mailOptions = {
        from: {
          name: "ViPT Fitness App",
          address: process.env.EMAIL_USER,
        },
        to: toEmail,
        subject: "🔐 Mã xác thực tài khoản ViPT",
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Xác thực tài khoản ViPT</title>
          </head>
          <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
            <table role="presentation" style="width: 100%; border-collapse: collapse;">
              <tr>
                <td align="center" style="padding: 40px 0;">
                  <table role="presentation" style="width: 600px; border-collapse: collapse; background-color: #ffffff; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                      <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 16px 16px 0 0;">
                        <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;">
                          💪 ViPT Fitness
                        </h1>
                        <p style="margin: 10px 0 0; color: rgba(255,255,255,0.9); font-size: 16px;">
                          Xác thực tài khoản của bạn
                        </p>
                      </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                      <td style="padding: 40px;">
                        <p style="margin: 0 0 20px; color: #333333; font-size: 16px; line-height: 1.6;">
                          Xin chào <strong>${userName}</strong>,
                        </p>
                        <p style="margin: 0 0 30px; color: #666666; font-size: 15px; line-height: 1.6;">
                          Cảm ơn bạn đã đăng ký tài khoản ViPT! Để hoàn tất quá trình đăng ký, vui lòng nhập mã xác thực bên dưới:
                        </p>
                        
                        <!-- OTP Box -->
                        <div style="text-align: center; margin: 30px 0;">
                          <div style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px 40px; border-radius: 12px;">
                            <span style="font-size: 36px; font-weight: 700; color: #ffffff; letter-spacing: 8px;">
                              ${otp}
                            </span>
                          </div>
                        </div>
                        
                        <p style="margin: 30px 0 10px; color: #666666; font-size: 14px; line-height: 1.6; text-align: center;">
                          ⏰ Mã xác thực có hiệu lực trong <strong>10 phút</strong>
                        </p>
                        
                        <hr style="border: none; border-top: 1px solid #eeeeee; margin: 30px 0;">
                        
                        <p style="margin: 0; color: #999999; font-size: 13px; line-height: 1.6;">
                          ⚠️ Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email này. Tài khoản của bạn sẽ không bị ảnh hưởng.
                        </p>
                      </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                      <td style="padding: 30px 40px; background-color: #f8f9fa; border-radius: 0 0 16px 16px; text-align: center;">
                        <p style="margin: 0; color: #999999; font-size: 12px;">
                          © 2024 ViPT Fitness App. All rights reserved.
                        </p>
                        <p style="margin: 10px 0 0; color: #999999; font-size: 12px;">
                          Email này được gửi tự động, vui lòng không trả lời.
                        </p>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>
          </body>
          </html>
        `,
        text: `
          Xin chào ${userName},
          
          Cảm ơn bạn đã đăng ký tài khoản ViPT!
          
          Mã xác thực của bạn là: ${otp}
          
          Mã này có hiệu lực trong 10 phút.
          
          Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email này.
          
          © 2024 ViPT Fitness App
        `,
      };

      await this.transporter.sendMail(mailOptions);
      console.log(`✅ Email xác thực đã gửi đến: ${toEmail}`);
      return true;
    } catch (error) {
      console.error("❌ Lỗi gửi email:", error.message);
      throw new Error(`Không thể gửi email xác thực: ${error.message}`);
    }
  }

  /**
   * Gửi email reset password
   * @param {string} toEmail - Email người nhận
   * @param {string} otp - Mã OTP
   * @param {string} userName - Tên người dùng
   * @returns {Promise<boolean>} Kết quả gửi email
   */
  async sendPasswordResetEmail(toEmail, otp, userName = "User") {
    try {
      const mailOptions = {
        from: {
          name: "ViPT Fitness App",
          address: process.env.EMAIL_USER,
        },
        to: toEmail,
        subject: "🔑 Đặt lại mật khẩu ViPT",
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
          </head>
          <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
            <table role="presentation" style="width: 100%; border-collapse: collapse;">
              <tr>
                <td align="center" style="padding: 40px 0;">
                  <table role="presentation" style="width: 600px; border-collapse: collapse; background-color: #ffffff; border-radius: 16px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);">
                    <tr>
                      <td style="padding: 40px 40px 20px; text-align: center; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); border-radius: 16px 16px 0 0;">
                        <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;">
                          🔑 Đặt lại mật khẩu
                        </h1>
                      </td>
                    </tr>
                    <tr>
                      <td style="padding: 40px;">
                        <p style="margin: 0 0 20px; color: #333333; font-size: 16px;">
                          Xin chào <strong>${userName}</strong>,
                        </p>
                        <p style="margin: 0 0 30px; color: #666666; font-size: 15px;">
                          Chúng tôi nhận được yêu cầu đặt lại mật khẩu. Sử dụng mã bên dưới:
                        </p>
                        <div style="text-align: center; margin: 30px 0;">
                          <div style="display: inline-block; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); padding: 20px 40px; border-radius: 12px;">
                            <span style="font-size: 36px; font-weight: 700; color: #ffffff; letter-spacing: 8px;">
                              ${otp}
                            </span>
                          </div>
                        </div>
                        <p style="margin: 30px 0 10px; color: #666666; font-size: 14px; text-align: center;">
                          ⏰ Mã có hiệu lực trong <strong>10 phút</strong>
                        </p>
                      </td>
                    </tr>
                    <tr>
                      <td style="padding: 30px 40px; background-color: #f8f9fa; border-radius: 0 0 16px 16px; text-align: center;">
                        <p style="margin: 0; color: #999999; font-size: 12px;">
                          © 2024 ViPT Fitness App
                        </p>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>
          </body>
          </html>
        `,
      };

      await this.transporter.sendMail(mailOptions);
      console.log(`✅ Email reset password đã gửi đến: ${toEmail}`);
      return true;
    } catch (error) {
      console.error("❌ Lỗi gửi email:", error.message);
      throw new Error(`Không thể gửi email: ${error.message}`);
    }
  }

  /**
   * Kiểm tra kết nối email
   * @returns {Promise<boolean>}
   */
  async verifyConnection() {
    try {
      await this.transporter.verify();
      console.log("✅ Email service đã sẵn sàng");
      return true;
    } catch (error) {
      console.error("❌ Email service lỗi:", error.message);
      return false;
    }
  }
}

export default new EmailService();
