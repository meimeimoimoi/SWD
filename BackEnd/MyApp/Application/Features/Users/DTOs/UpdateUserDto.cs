using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Users.DTOs
{
    public class UpdateUserDto
    {
        [MaxLength(255)]
        public string? Email { get; set; }

        [MaxLength(100)]
        public string? FirstName { get; set; }

        [MaxLength(100)]
        public string? LastName { get; set; }

        [MaxLength(20)]
        public string? Phone { get; set; }

        [MaxLength(500)]
        public string? ProfileImagePath { get; set; }

        [MaxLength(50)]
        public string? Role { get; set; }
    }
}