using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Data.Entities
{
    public class UserRole
    {
        public Guid UserId { get; set; }
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;

        public int RoleId { get; set; }
        [ForeignKey("RoleId")]
        public Role Role { get; set; } = null!;
    }
}
