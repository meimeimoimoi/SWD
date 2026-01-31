using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Business.DTOs
{
    public class GoogleLoginRequestDto
    {
        public string? Credential { get; set; } // ID Token từ Google (optional)
        public string? AccessToken { get; set; } // Access Token từ Google (optional)
        public string? Email { get; set; } // Email từ Google user info (optional)
        public string? Name { get; set; } // Name từ Google user info (optional)
    }
}
