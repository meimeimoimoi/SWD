using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Business.DTOs
{
    public class CreateStaffUserDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = null!;

        // ✨ SỬA Ở ĐÂY ✨
        [Required]
        [StringLength(100)]
        public string FirstName { get; set; } = null!;

        [Required]
        [StringLength(100)]
        public string LastName { get; set; } = null!;

        [Required]
        public string RoleName { get; set; } = null!;
    }
}
