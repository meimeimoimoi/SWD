using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Business.Interface
{
    public interface IMessageService
    {
        Task SendPasswordResetEmailAsync(string toEmail, string resetToken);
        Task SendConfirmationEmailAsync(string toEmail, string userId, string token);
        Task SendWelcomeEmailWithPasswordAsync(string toEmail, string temporaryPassword);
    }
}
