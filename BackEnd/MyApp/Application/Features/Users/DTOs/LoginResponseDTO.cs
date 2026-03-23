namespace MyApp.Application.Features.Users.DTOs
{
    public class LoginResponseDTO
    {
        public string AccessToken { get; set; } = null!;
        public string RefreshToken { get; set; } = null!;
        public TimeSpan ExpiresIn { get; set; }
        public required string Username { get; set; }
        public required string Role { get; set; }

    }
}
