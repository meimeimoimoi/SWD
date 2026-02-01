using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SWD.Data.Entities;

public class UserRefreshToken
{
    [Key]
    public int Id { get; set; }

    public Guid UserId { get; set; }
    [ForeignKey("UserId")]
    public User User { get; set; } = null!;

    [Required]
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
