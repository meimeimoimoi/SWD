using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SWD.Data.Entities;

public class Role
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(50)]
    public string Name { get; set; } = null!;

    [Required]
    [StringLength(50)]
    public string NormalizedName { get; set; } = null!;

    // Navigation property
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}