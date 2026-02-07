namespace MyApp.Application.Interfaces
{
    public interface IMessageService
    {
        Task SendAccountCreatedByStaffEmailAsync(string toEmail, string firstName, string temporaryPassword, int userId, string confirmationToken);
    }
}
