using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Admin.DTOs
{
    public class CreateUserDto
    {
        [Required]
        [EmailAddress]
        [MaxLength(255)]
        public string Email { get; set; } = null!;

        [Required]
        [MinLength(6)]
        [MaxLength(100)]
        public string Password { get; set; } = null!;

        [Required]
        [MaxLength(50)]
        public string Role { get; set; } = null!; // "Admin", "Technician", "User", etc.
    }
}
