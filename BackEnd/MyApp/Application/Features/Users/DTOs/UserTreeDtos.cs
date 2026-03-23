using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Users.DTOs;

public class CreateUserTreeDto
{
    [Required]
    [MinLength(1)]
    [MaxLength(255)]
    public string TreeName { get; set; } = string.Empty;

    [MaxLength(255)]
    public string? ScientificName { get; set; }

    public string? Description { get; set; }
}

public class UserTreeListItemDto
{
    public int TreeId { get; set; }
    public string? TreeName { get; set; }
    public string? ScientificName { get; set; }
    public string? ImagePath { get; set; }
}
