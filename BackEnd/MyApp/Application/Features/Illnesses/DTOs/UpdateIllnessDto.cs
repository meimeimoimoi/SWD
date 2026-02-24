namespace MyApp.Application.Features.Illnesses.DTOs;

public class UpdateIllnessDto
{
    public string IllnessName { get; set; } = null!;
    public string? ScientificName { get; set; }
    public string? Description { get; set; }
    public string? Symptoms { get; set; }
    public string? Causes { get; set; }
    public string? Severity { get; set; }
}
