using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Trees.DTOs;

public class MapTreeIllnessDto
{
    [Required(ErrorMessage = "Tree ID is required")]
    public int TreeId { get; set; }

    [Required(ErrorMessage = "Illness ID is required")]
    public int IllnessId { get; set; }
}
