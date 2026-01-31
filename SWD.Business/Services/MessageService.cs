using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MimeKit;
using SWD.Business.Interface;
using System;
using System.Collections.Generic;
using System.Linq;
using MailKit.Net.Smtp;
using MimeKit;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Business.Services
{
    public class MessageService: IMessageService
    {
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly ILogger<MessageService> _logger;

        public MessageService(IConfiguration configuration, IHttpClientFactory httpClientFactory, ILogger<MessageService> logger)
        {
            _configuration = configuration;
            _httpClientFactory = httpClientFactory;
            _logger = logger;
        }

        public async Task SendConfirmationEmailAsync(string toEmail, string userId, string token)
        {
            try
            {
                _logger.LogInformation("Sending confirmation email to {Email}", toEmail);

                var frontendBaseUrl = _configuration["Urls:FrontendBaseUrl"] ?? "http://localhost:5173";
                var confirmationLink = $"{frontendBaseUrl}/confirmation-email?userId={userId}&token={token}";

                var email = new MimeMessage();
                email.From.Add(new MailboxAddress(_configuration["SmtpSettings:SenderName"] ?? "SWD392", _configuration["SmtpSettings:SenderEmail"]));
                email.To.Add(new MailboxAddress(toEmail, toEmail));
                email.Subject = "Please confirm your email";
                var body = new BodyBuilder
                {
                    HtmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
</head>
<body style='margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, ""Segoe UI"", Roboto, ""Helvetica Neue"", Arial, sans-serif; background-color: #f3f4f6;'>
    <table role='presentation' style='width: 100%; border-collapse: collapse;'>
        <tr>
            <td style='padding: 40px 20px; text-align: center;'>
                <table role='presentation' style='max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); overflow: hidden;'>
                    <!-- Header -->
                    <tr>
                        <td style='background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); padding: 40px 30px; text-align: center;'>
                            <div style='display: inline-block; background-color: rgba(255, 255, 255, 0.2); padding: 16px; border-radius: 12px; margin-bottom: 16px;'>
                                <div style='width: 48px; height: 48px; background-color: #ffffff; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 24px; color: #2563eb; font-weight: bold;'>✓</div>
                            </div>
                            <h1 style='margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;'>Chào mừng đến với SWD!</h1>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style='padding: 40px 30px;'>
                            <p style='margin: 0 0 20px 0; font-size: 16px; line-height: 1.6; color: #1f2937;'>
                                Cảm ơn bạn đã đăng ký tài khoản tại <strong style='color: #2563eb;'>SWD</strong>!
                            </p>
                            <p style='margin: 0 0 30px 0; font-size: 16px; line-height: 1.6; color: #4b5563;'>
                                Để hoàn tất quá trình đăng ký và kích hoạt tài khoản, vui lòng xác nhận địa chỉ email của bạn bằng cách nhấn vào nút bên dưới:
                            </p>
                            
                            <!-- CTA Button -->
                            <div style='text-align: center; margin: 32px 0;'>
                                <a href='{confirmationLink}' style='display: inline-block; background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); color: #ffffff; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; box-shadow: 0 4px 6px rgba(37, 99, 235, 0.3); transition: all 0.3s ease;'>
                                    ✓ Xác nhận email
                                </a>
                            </div>
                            
                            <p style='margin: 24px 0 0 0; font-size: 14px; line-height: 1.6; color: #6b7280; text-align: center;'>
                                Hoặc copy và dán link sau vào trình duyệt:<br>
                                <a href='{confirmationLink}' style='color: #2563eb; word-break: break-all;'>{confirmationLink}</a>
                            </p>
                            
                            <!-- Warning Box -->
                            <div style='margin-top: 32px; padding: 16px; background-color: #fef3c7; border-left: 4px solid #f59e0b; border-radius: 8px;'>
                                <p style='margin: 0; font-size: 14px; color: #92400e; line-height: 1.6;'>
                                    <strong>⚠️ Lưu ý:</strong> Link xác nhận này chỉ có hiệu lực trong <strong>24 giờ</strong>. Nếu bạn không xác nhận trong thời gian này, bạn sẽ cần yêu cầu gửi lại email xác nhận.
                                </p>
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style='padding: 30px; background-color: #f9fafb; border-top: 1px solid #e5e7eb; text-align: center;'>
                            <p style='margin: 0 0 8px 0; font-size: 14px; color: #6b7280;'>
                                Email này được gửi tự động từ hệ thống <strong style='color: #2563eb;'>SWD</strong>.
                            </p>
                            <p style='margin: 0; font-size: 12px; color: #9ca3af;'>
                                Vui lòng không trả lời email này. Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email.
                            </p>
                            <p style='margin: 16px 0 0 0; font-size: 12px; color: #9ca3af;'>
                                © {DateTime.UtcNow.Year} SWD. Tất cả quyền được bảo lưu.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>"
                };
                email.Body = body.ToMessageBody();

                using var smtp = new SmtpClient();
                await smtp.ConnectAsync(_configuration["SmtpSettings:Server"], int.Parse(_configuration["SmtpSettings:Port"]!), MailKit.Security.SecureSocketOptions.StartTls);
                await smtp.AuthenticateAsync(_configuration["SmtpSettings:SenderEmail"], _configuration["SmtpSettings:Password"]);
                await smtp.SendAsync(email);
                await smtp.DisconnectAsync(true);

                _logger.LogInformation("Confirmation email sent to {Email} successfully", toEmail);
            }catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send confirmation email to {Email}", toEmail);
            }
        }

        public async Task SendPasswordResetEmailAsync(string toEmail, string resetToken)
        {
            try
            {
                _logger.LogInformation("Sending password reset email to {Email}", toEmail);

                var frontendBaseUrl = _configuration["Urls:FrontendBaseUrl"] ?? "http://localhost:5173";
                var resetLink = $"{frontendBaseUrl}/reset-password?email={Uri.UnescapeDataString(toEmail)}&token={Uri.UnescapeDataString(resetToken)}";

                var email = new MimeMessage();
                email.From.Add(new MailboxAddress(_configuration["SmtpSettings:SenderName"] ?? "SWD", _configuration["SmtpSettings:SenderEmail"]));
                email.To.Add(new MailboxAddress(toEmail, toEmail));
                email.Subject = "Reset Password";

                var body = new BodyBuilder
                {
                    HtmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
</head>
<body style='margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, ""Segoe UI"", Roboto, ""Helvetica Neue"", Arial, sans-serif; background-color: #f3f4f6;'>
    <table role='presentation' style='width: 100%; border-collapse: collapse;'>
        <tr>
            <td style='padding: 40px 20px; text-align: center;'>
                <table role='presentation' style='max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); overflow: hidden;'>
                    <!-- Header -->
                    <tr>
                        <td style='background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); padding: 40px 30px; text-align: center;'>
                            <div style='display: inline-block; background-color: rgba(255, 255, 255, 0.2); padding: 16px; border-radius: 12px; margin-bottom: 16px;'>
                                <div style='width: 48px; height: 48px; background-color: #ffffff; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 24px; color: #dc2626; font-weight: bold;'>🔒</div>
                            </div>
                            <h1 style='margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;'>Đặt lại mật khẩu</h1>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style='padding: 40px 30px;'>
                            <p style='margin: 0 0 20px 0; font-size: 16px; line-height: 1.6; color: #1f2937;'>
                                Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản <strong style='color: #2563eb;'>{toEmail}</strong>.
                            </p>
                            <p style='margin: 0 0 30px 0; font-size: 16px; line-height: 1.6; color: #4b5563;'>
                                Nhấn vào nút bên dưới để đặt lại mật khẩu của bạn:
                            </p>
                            
                            <!-- CTA Button -->
                            <div style='text-align: center; margin: 32px 0;'>
                                <a href='{resetLink}' style='display: inline-block; background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); color: #ffffff; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; box-shadow: 0 4px 6px rgba(220, 38, 38, 0.3); transition: all 0.3s ease;'>
                                    🔑 Đặt lại mật khẩu
                                </a>
                            </div>
                            
                            <!-- Token Display -->
                            <div style='margin: 24px 0; padding: 20px; background-color: #f3f4f6; border-radius: 8px; border: 1px dashed #d1d5db;'>
                                <p style='margin: 0 0 8px 0; font-size: 14px; color: #6b7280; font-weight: 600;'>Mã xác thực của bạn:</p>
                                <p style='margin: 0; font-size: 24px; font-weight: 700; color: #1f2937; letter-spacing: 4px; text-align: center; font-family: monospace;'>{resetToken}</p>
                            </div>
                            
                            <p style='margin: 24px 0 0 0; font-size: 14px; line-height: 1.6; color: #6b7280; text-align: center;'>
                                Hoặc copy và dán link sau vào trình duyệt:<br>
                                <a href='{resetLink}' style='color: #2563eb; word-break: break-all;'>{resetLink}</a>
                            </p>
                            
                            <!-- Warning Box -->
                            <div style='margin-top: 32px; padding: 16px; background-color: #fef3c7; border-left: 4px solid #f59e0b; border-radius: 8px;'>
                                <p style='margin: 0; font-size: 14px; color: #92400e; line-height: 1.6;'>
                                    <strong>⚠️ Lưu ý quan trọng:</strong>
                                </p>
                                <ul style='margin: 8px 0 0 0; padding-left: 20px; font-size: 14px; color: #92400e; line-height: 1.8;'>
                                    <li>Mã xác thực này chỉ có hiệu lực trong <strong>10 phút</strong>.</li>
                                    <li>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.</li>
                                    <li>Để bảo mật tài khoản, không chia sẻ mã xác thực với bất kỳ ai.</li>
                                </ul>
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style='padding: 30px; background-color: #f9fafb; border-top: 1px solid #e5e7eb; text-align: center;'>
                            <p style='margin: 0 0 8px 0; font-size: 14px; color: #6b7280;'>
                                Email này được gửi tự động từ hệ thống <strong style='color: #2563eb;'>ClinicCare</strong>.
                            </p>
                            <p style='margin: 0; font-size: 12px; color: #9ca3af;'>
                                Vui lòng không trả lời email này. Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email.
                            </p>
                            <p style='margin: 16px 0 0 0; font-size: 12px; color: #9ca3af;'>
                                © {DateTime.UtcNow.Year} SWD. Tất cả quyền được bảo lưu.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>"
                };
                email.Body = body.ToMessageBody();

                using var smtp = new SmtpClient();
                await smtp.ConnectAsync(_configuration["SmtpSettings:Server"], int.Parse(_configuration["SmtpSettings:Port"]!), MailKit.Security.SecureSocketOptions.StartTls);
                await smtp.AuthenticateAsync(_configuration["SmtpSettings:SenderEmail"], _configuration["SmtpSettings:Password"]);
                await smtp.SendAsync(email);
                await smtp.DisconnectAsync(true);

                _logger.LogInformation("Password reset email sent successfully to {Email}", toEmail);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send password reset email to {Email}", toEmail);
                // Don't throw - email failures shouldn't break the request flow
                // In production, consider queuing emails for retry
            }
        }

        public async Task SendWelcomeEmailWithPasswordAsync(string toEmail, string temporaryPassword)
        {
            try
            {
                _logger.LogInformation("Sending welcome email to {Email}", toEmail);

                var frontendBaseUrl = _configuration["Urls:FrontendBaseUrl"] ?? "http://localhost:5173";
                var loginLink = $"{frontendBaseUrl}/login";

                var email = new MimeMessage();
                email.From.Add(new MailboxAddress(_configuration["SmtpSettings:SenderName"] ?? "ClinicCare", _configuration["SmtpSettings:SenderEmail"]));
                email.To.Add(new MailboxAddress(toEmail, toEmail));
                email.Subject = "Welcome to SWD!";

                var body = new BodyBuilder
                {
                    HtmlBody = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
</head>
<body style='margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, ""Segoe UI"", Roboto, ""Helvetica Neue"", Arial, sans-serif; background-color: #f3f4f6;'>
    <table role='presentation' style='width: 100%; border-collapse: collapse;'>
        <tr>
            <td style='padding: 40px 20px; text-align: center;'>
                <table role='presentation' style='max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); overflow: hidden;'>
                    <!-- Header -->
                    <tr>
                        <td style='background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); padding: 40px 30px; text-align: center;'>
                            <div style='display: inline-block; background-color: rgba(255, 255, 255, 0.2); padding: 16px; border-radius: 12px; margin-bottom: 16px;'>
                                <div style='width: 48px; height: 48px; background-color: #ffffff; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 24px; color: #2563eb; font-weight: bold;'>👋</div>
                            </div>
                            <h1 style='margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;'>Chào mừng bạn đến với ClinicCare!</h1>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style='padding: 40px 30px;'>
                            <p style='margin: 0 0 20px 0; font-size: 16px; line-height: 1.6; color: #1f2937;'>
                                Một tài khoản đã được tạo cho bạn trên hệ thống phòng khám <strong style='color: #2563eb;'>ClinicCare</strong>.
                            </p>
                            <p style='margin: 0 0 30px 0; font-size: 16px; line-height: 1.6; color: #4b5563;'>
                                Bạn có thể đăng nhập bằng thông tin dưới đây:
                            </p>
                            
                            <!-- Login Info Box -->
                            <div style='margin: 24px 0; padding: 20px; background-color: #f3f4f6; border-radius: 8px; border: 1px solid #e5e7eb;'>
                                <p style='margin: 0 0 12px 0; font-size: 14px; color: #6b7280; font-weight: 600;'>Thông tin đăng nhập:</p>
                                <p style='margin: 8px 0; font-size: 15px; color: #1f2937;'><strong>Email:</strong> <span style='color: #2563eb;'>{toEmail}</span></p>
                                <p style='margin: 8px 0; font-size: 15px; color: #1f2937;'><strong>Mật khẩu tạm thời:</strong></p>
                                <div style='margin: 8px 0; padding: 12px; background-color: #ffffff; border: 2px dashed #d1d5db; border-radius: 6px; text-align: center;'>
                                    <code style='font-size: 18px; font-weight: 700; color: #1f2937; letter-spacing: 2px; font-family: monospace;'>{temporaryPassword}</code>
                                </div>
                            </div>
                            
                            <!-- Warning Box -->
                            <div style='margin: 24px 0; padding: 16px; background-color: #fef3c7; border-left: 4px solid #f59e0b; border-radius: 8px;'>
                                <p style='margin: 0; font-size: 14px; color: #92400e; line-height: 1.6;'>
                                    <strong>⚠️ Lưu ý:</strong> Vui lòng đăng nhập và đổi mật khẩu của bạn ngay lập tức để bảo mật tài khoản.
                                </p>
                            </div>
                            
                            <!-- CTA Button -->
                            <div style='text-align: center; margin: 32px 0;'>
                                <a href='{loginLink}' style='display: inline-block; background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); color: #ffffff; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; box-shadow: 0 4px 6px rgba(37, 99, 235, 0.3); transition: all 0.3s ease;'>
                                    🔑 Đăng nhập ngay
                                </a>
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style='padding: 30px; background-color: #f9fafb; border-top: 1px solid #e5e7eb; text-align: center;'>
                            <p style='margin: 0 0 8px 0; font-size: 14px; color: #6b7280;'>
                                Email này được gửi tự động từ hệ thống <strong style='color: #2563eb;'>ClinicCare</strong>.
                            </p>
                            <p style='margin: 0; font-size: 12px; color: #9ca3af;'>
                                Vui lòng không trả lời email này.
                            </p>
                            <p style='margin: 16px 0 0 0; font-size: 12px; color: #9ca3af;'>
                                © {DateTime.UtcNow.Year} ClinicCare. Tất cả quyền được bảo lưu.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>"
                };
                email.Body = body.ToMessageBody();

                using var smtp = new SmtpClient();
                await smtp.ConnectAsync(_configuration["SmtpSettings:Server"], int.Parse(_configuration["SmtpSettings:Port"]!), MailKit.Security.SecureSocketOptions.StartTls);
                await smtp.AuthenticateAsync(_configuration["SmtpSettings:SenderEmail"], _configuration["SmtpSettings:Password"]);
                await smtp.SendAsync(email);
                await smtp.DisconnectAsync(true);

                _logger.LogInformation("Welcome email sent successfully to {Email}", toEmail);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send welcome email to {Email}", toEmail);
                // Don't throw - email failures shouldn't break the request flow
            }
        }
    }
}
