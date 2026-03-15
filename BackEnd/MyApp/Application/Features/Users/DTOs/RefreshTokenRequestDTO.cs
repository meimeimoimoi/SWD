namespace MyApp.Application.Features.Users.DTOs
{
    public class RefreshTokenRequestDTO
    {
        public string AccessToken { get; set; } = null;
        public string RefreshToken { get; set; } = null;
    }
}
