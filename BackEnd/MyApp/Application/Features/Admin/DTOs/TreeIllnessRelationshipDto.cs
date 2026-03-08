using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Admin.DTOs
{
    public class TreeIllnessRelationshipDto
    {
        public int RelationshipId { get; set; }
        public int TreeId { get; set; }
        public string? TreeName { get; set; }
        public int IllnessId { get; set; }
        public string? IllnessName { get; set; }
    }

    public class CreateRelationshipDto
    {
        [Required(ErrorMessage = "TreeId is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "TreeId must be a positive integer.")]
        public int TreeId { get; set; }

        [Required(ErrorMessage = "IllnessId is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "IllnessId must be a positive integer.")]
        public int IllnessId { get; set; }
    }
}
