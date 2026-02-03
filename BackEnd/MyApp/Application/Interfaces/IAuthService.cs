using MyApp.Application.Features.Users.DTOs;
namespace MyApp.Application.Interfaces
{
    public interface IAuthService
    {
        Task<string> LoginAsync(LoginRequestDTO request);
        Task RegisterAsync(ResgisterRequestDTO request);
        Task LogoutAsync(string token);
    }
}
