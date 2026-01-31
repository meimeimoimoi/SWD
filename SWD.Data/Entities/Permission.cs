using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SWD.Data.Entities;

public class Permission
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty; // e.g., patients:read

    [StringLength(255)]
    public string? Description { get; set; }
}
