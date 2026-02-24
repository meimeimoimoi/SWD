namespace MyApp.Application.Features.Solutions.DTOs;

public class SolutionByIllnessDto
{
    public int IllnessId { get; set; }
    public string IllnessName { get; set; } = null!;
    public List<SolutionItemDto> Solutions { get; set; } = new();
}
