using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace MyApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ImageUploadController : ControllerBase
    {
        private readonly IImageUploadService _imageUploadService;
        private readonly ILogger<ImageUploadController> _logger;

        public ImageUploadController(IImageUploadService imageUploadService, ILogger<ImageUploadController> logger)
        {
            _imageUploadService = imageUploadService;
            _logger = logger;
        }

        /// <summary>
        /// Upload an image of a tree disease
        /// </summary>
        /// <param name="request">Image upload request with file</param>
        /// <returns>Uploaded image details</returns>
        [HttpPost("upload")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> UploadImage([FromForm] ImageUploadRequestDto request)
        {
            try
            {
                var image = request.Image;

                if (image == null || image.Length == 0)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "No file uploaded."
                    });
                }

                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                    ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    return Unauthorized(new
                    {
                        success = false,
                        message = "Invalid user ID in token."
                    });
                }

                _logger.LogInformation("User {UserId} uploading image: {FileName}, Size: {Size}KB",
                    userId, image.FileName, image.Length / 1024);

                var result = await _imageUploadService.UploadImageAsync(userId, image);

                return Ok(new
                {
                    success = true,
                    message = "Image uploaded successfully",
                    data = result
                });
            }
            catch (ArgumentException ex)
            {
                _logger.LogError(ex, "Validation error during image upload");
                return BadRequest(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading image");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while uploading the image",
                    error = ex.Message
                });
            }
        }
        [HttpGet("{uploadId}")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetImageStatus(int uploadId)
        {
            try
            {
                var image = await _imageUploadService.GetImageByIdAsync(uploadId);

                if (image == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"Image with ID {uploadId} not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = "Image retrieved successfully",
                    data = image
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving image upload {UploadId}", uploadId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving image",
                    error = ex.Message
                });
            }
        }

       
        [HttpGet("my-images")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetMyImages()
        {
            try
            {
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                    ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    return Unauthorized(new
                    {
                        success = false,
                        message = "Invalid user authentication"
                    });
                }

                var images = await _imageUploadService.GetUserImagesAsync(userId);

                return Ok(new
                {
                    success = true,
                    message = $"Retrieved {images.Count} images",
                    data = images
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user images");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving images",
                    error = ex.Message
                });
            }
        }

    }
}
