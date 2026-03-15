using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Users.DTOs
{
    public class RatingRequestDto
    {
        /// <summary>
        /// Thang ?i?m ?ánh giá t? 1 ??n 5
        /// 1 = R?t không chính xác, 2 = Không chính xác, 3 = Trung bình, 4 = Chính xác, 5 = R?t chính xác
        /// </summary>
        [Required(ErrorMessage = "Rating score is required")]
        [Range(1, 5, ErrorMessage = "Rating score must be between 1 and 5")]
        public int Score { get; set; }

        [MaxLength(1000, ErrorMessage = "Comment cannot exceed 1000 characters")]
        public string? Comment { get; set; }
    }
}
