using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Business.DTOs
{
    public class RegisterResponseDto
    {
        public Guid UserId { get; set; }
        public string Email { get; set; } = string.Empty;
    }
}
