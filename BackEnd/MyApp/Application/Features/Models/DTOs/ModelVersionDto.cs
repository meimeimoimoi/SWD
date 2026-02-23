namespace MyApp.Application.Features.Models.DTOs;

public class ModelVersionDto
{
    public int ModelVersionId { get; set; }
    public string ModelName { get; set; } = null!;
    public string Version { get; set; } = null!;
    public bool IsActive { get; set; }
    public bool IsDefault { get; set; }
}
