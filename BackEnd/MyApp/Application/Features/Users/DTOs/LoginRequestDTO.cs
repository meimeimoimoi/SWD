using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Users.DTOs
{
    public class LoginRequestDTO
    {
        [Required(ErrorMessage = "Username or Email is required")]
        public string UsernameOrEmail { get; set; } = null!;
        
        [Required(ErrorMessage = "Password is required")]
        [MinLength(6, ErrorMessage = "Password must be at least 6 characters")]
        public string Password { get; set; } = null!;
    }
}
