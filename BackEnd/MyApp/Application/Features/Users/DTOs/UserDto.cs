namespace MyApp.Application.Features.Users.DTOs
{
    public class UserDto
    {
        public int UserId { get; set; }
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Phone { get; set; }
        public string? ProfileImagePath { get; set; }
        public DateTime? LastLoginAt { get; set; }
        public string? Role { get; set; }
    }
}
