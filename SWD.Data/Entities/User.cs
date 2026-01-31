using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SWD.Data.Entities;

public class User
{
    [Key]
    public Guid Id { get; set; }

    [StringLength(256)]
    public string? UserName { get; set; }

    [StringLength(256)]
    public string? NormalizedUserName { get; set; }

    [Required]
    [EmailAddress]
    [StringLength(256)]
    public string Email { get; set; } = string.Empty;

    [StringLength(256)]
    public string? NormalizedEmail { get; set; }

    [Required]
    public bool EmailConfirmed { get; set; } = false;

    public string PasswordHash { get; set; } = string.Empty;

    // ✨ THÊM CÁC TRƯỜNG NÀY
    [StringLength(100)]
    public string? FirstName { get; set; }

    [StringLength(100)]
    public string? LastName { get; set; }

    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime? UpdatedAt { get; set; }

    public int AccessFailedCount { get; set; } = 0;
    public DateTime? LockoutEnd { get; set; }

    public string? PasswordResetToken { get; set; }
    public DateTime? ResetTokenExpires { get; set; }

    public string? EmailConfirmationToken { get; set; }
    public DateTime? ConfirmationTokenExpires { get; set; }
    public bool MustChangePassword { get; set; } = false; // Mặc định là false

    // Navigation property
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}
