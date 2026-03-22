using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Users.DTOs
{
    public class RatingRequestDto
    {
        [Required(ErrorMessage = "Rating score is required")]
        [Range(1, 5, ErrorMessage = "Rating score must be between 1 and 5")]
        public int Score { get; set; }

        [MaxLength(1000, ErrorMessage = "Comment cannot exceed 1000 characters")]
        public string? Comment { get; set; }
    }
}
