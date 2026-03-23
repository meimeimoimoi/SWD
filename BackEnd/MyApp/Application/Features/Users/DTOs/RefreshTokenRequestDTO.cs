namespace MyApp.Application.Features.Users.DTOs
{
    public class RefreshTokenRequestDTO
    {
        public required string AccessToken { get; set; }
        public required string RefreshToken { get; set; }
    }
}
