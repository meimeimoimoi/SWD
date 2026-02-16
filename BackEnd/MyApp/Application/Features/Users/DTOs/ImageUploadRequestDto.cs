using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Users.DTOs
{
    public class ImageUploadRequestDto
    {
        [Required(ErrorMessage = "Image file is required")]
        public IFormFile Image { get; set; } = null!;

    }
}
