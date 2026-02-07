using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using MyApp.Application.Interfaces;

namespace MyApp.Infrastructure.Services
{
    public class MessageService : IMessageService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<MessageService> _logger;

        public MessageService(IConfiguration configuration, ILogger<MessageService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        // For Technician/Staff created by Admin
        public async Task SendAccountCreatedByStaffEmailAsync(string toEmail, string firstName, string temporaryPassword, int userId, string confirmationToken)
        {
            try
            {
                _logger.LogInformation("Sending account created by staff email to {Email}", toEmail);
                
                var frontendBaseUrl = _configuration["Urls:FrontendBaseUrl"] ?? "http://localhost:5173";
                var confirmationLink = $"{frontendBaseUrl}/confirm-email?userId={userId}&token={confirmationToken}";
                var loginLink = $"{frontendBaseUrl}/login";
                
                var email = new MimeMessage();
                email.From.Add(new MailboxAddress(
                    _configuration["SmtpSettings:SenderName"] ?? "SWD", 
                    _configuration["SmtpSettings:SenderEmail"]!));
                email.To.Add(new MailboxAddress(firstName, toEmail));
                email.Subject = "Chào mừng bạn đến với SWD!";

                var body = new BodyBuilder
                {
                    HtmlBody = $@"<!DOCTYPE html>
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
                    <tr>
                        <td style='background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); padding: 40px 30px; text-align: center;'>
                            <div style='display: inline-block; background-color: rgba(255, 255, 255, 0.2); padding: 16px; border-radius: 12px; margin-bottom: 16px;'>
                                <div style='width: 48px; height: 48px; background-color: #ffffff; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 24px; color: #2563eb; font-weight: bold;'>👋</div>
                            </div>
                            <h1 style='margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;'>Chào mừng bạn đến với SWD!</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style='padding: 40px 30px;'>
                            <p style='margin: 0 0 20px 0; font-size: 16px; line-height: 1.6; color: #1f2937;'>
                                Xin chào <strong style='color: #2563eb;'>{firstName}</strong>,
                            </p>
                            <p style='margin: 0 0 30px 0; font-size: 16px; line-height: 1.6; color: #4b5563;'>
                                Một tài khoản đã được tạo cho bạn trên hệ thống <strong style='color: #2563eb;'>SWD</strong>. Bạn có thể đăng nhập bằng thông tin dưới đây:
                            </p>
                            <div style='margin: 24px 0; padding: 20px; background-color: #f3f4f6; border-radius: 8px; border: 1px solid #e5e7eb;'>
                                <p style='margin: 0 0 12px 0; font-size: 14px; color: #6b7280; font-weight: 600;'>Thông tin đăng nhập:</p>
                                <p style='margin: 8px 0; font-size: 15px; color: #1f2937;'><strong>User ID:</strong> <span style='color: #2563eb;'>#{userId}</span></p>
                                <p style='margin: 8px 0; font-size: 15px; color: #1f2937;'><strong>Email:</strong> <span style='color: #2563eb;'>{toEmail}</span></p>
                                <p style='margin: 8px 0; font-size: 15px; color: #1f2937;'><strong>Mật khẩu tạm thời:</strong></p>
                                <div style='margin: 8px 0; padding: 12px; background-color: #ffffff; border: 2px dashed #d1d5db; border-radius: 6px; text-align: center;'>
                                    <code style='font-size: 18px; font-weight: 700; color: #1f2937; letter-spacing: 2px; font-family: monospace;'>{temporaryPassword}</code>
                                </div>
                            </div>
                            <div style='margin: 24px 0; padding: 16px; background-color: #fef3c7; border-left: 4px solid #f59e0b; border-radius: 8px;'>
                                <p style='margin: 0; font-size: 14px; color: #92400e; line-height: 1.6;'>
                                    <strong>⚠️ Lưu ý:</strong> Vui lòng đăng nhập và đổi mật khẩu của bạn ngay lập tức để bảo mật tài khoản.
                                </p>
                            </div>
                            <div style='text-align: center; margin: 32px 0;'>
                                <a href='{confirmationLink}' style='display: inline-block; background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: #ffffff; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; box-shadow: 0 4px 6px rgba(16, 185, 129, 0.3); margin: 0 8px 12px 8px;'>
                                    ✓ Xác nhận email
                                </a>
                                <br>
                                <a href='{loginLink}' style='display: inline-block; background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%); color: #ffffff; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-weight: 600; font-size: 16px; box-shadow: 0 4px 6px rgba(37, 99, 235, 0.3); margin: 0 8px;'>
                                    🔑 Đăng nhập ngay
                                </a>
                            </div>
                            <p style='margin: 24px 0 0 0; font-size: 14px; line-height: 1.6; color: #6b7280; text-align: center;'>
                                Vui lòng xác nhận email trước khi đăng nhập. Sau khi đăng nhập, hệ thống sẽ yêu cầu bạn đổi mật khẩu.
                            </p>
                        </td>
                    </tr>
                    <tr>
                        <td style='padding: 30px; background-color: #f9fafb; border-top: 1px solid #e5e7eb; text-align: center;'>
                            <p style='margin: 0 0 8px 0; font-size: 14px; color: #6b7280;'>
                                Email này được gửi tự động từ hệ thống <strong style='color: #2563eb;'>SWD</strong>.
                            </p>
                            <p style='margin: 0; font-size: 12px; color: #9ca3af;'>
                                Vui lòng không trả lời email này.
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
                await smtp.ConnectAsync(
                    _configuration["SmtpSettings:Server"], 
                    int.Parse(_configuration["SmtpSettings:Port"]!), 
                    MailKit.Security.SecureSocketOptions.StartTls);
                await smtp.AuthenticateAsync(
                    _configuration["SmtpSettings:SenderEmail"], 
                    _configuration["SmtpSettings:Password"]);
                await smtp.SendAsync(email);
                await smtp.DisconnectAsync(true);
                
                _logger.LogInformation("Account created by staff email sent successfully to {Email}", toEmail);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send account created by staff email to {Email}", toEmail);
                // Don't throw - email failures shouldn't break the request flow
            }
        }
    }
}
