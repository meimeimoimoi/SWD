using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Admin.DTOs
{
    public class CreateTechnicianStaffDto
    {
        [Required]
        [MaxLength(255)]
        public string Username { get; set; } = null!;

        [Required]
        [EmailAddress]
        [MaxLength(255)]
        public string Email { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string? FirstName { get; set; }

        [MaxLength(100)]
        public string? LastName { get; set; }

        [MaxLength(20)]
        public string? Phone { get; set; }

        [Required]
        [MaxLength(50)]
        public string Role { get; set; } = null!; // "Technician" or "Staff"
    }
}