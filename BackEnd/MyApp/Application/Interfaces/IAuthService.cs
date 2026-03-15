using MyApp.Application.Features.Users.DTOs;
using MyApp.Infrastructure.Helpers;
namespace MyApp.Application.Interfaces
{
    public interface IAuthService
    {
        Task<LoginResponseDTO> LoginAsync(LoginRequestDTO request);
        Task<ApiResponse> RegisterAsync(ResgisterRequestDTO request);
        Task LogoutAsync(string token);

        Task<LoginResponseDTO> RefreshAsync(RefreshTokenRequestDTO request);
    }
}
