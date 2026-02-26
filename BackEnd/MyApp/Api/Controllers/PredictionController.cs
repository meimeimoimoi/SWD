using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PredictionController : ControllerBase
    {
        private readonly IPredictionService _predictionService;
        private readonly ILogger<PredictionController> _logger;

        public PredictionController(
            IPredictionService predictionService,
            ILogger<PredictionController> logger)
        {
            _predictionService = predictionService;
            _logger = logger;
        }

        [HttpPost("predict")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [Authorize]
        public async Task<IActionResult> Predict(IFormFile image)
        {
            try
            {
                if (image == null || image.Length == 0)
                {
                    return BadRequest(new { success = false, message = "No image provided" });
                }

                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
                var extension = Path.GetExtension(image.FileName).ToLowerInvariant();

                if (!allowedExtensions.Contains(extension))
                {
                    return BadRequest(new { success = false, message = "Invalid file type. Only jpg, jpeg, png allowed" });
                }

                const long maxFileSize = 10 * 1024 * 1024;
                if (image.Length > maxFileSize)
                {
                    return BadRequest(new { success = false, message = "File too large. Max 10MB" });
                }

                _logger.LogInformation("Predicting: {FileName} ({Size} bytes)",
                    image.FileName, image.Length);

                using var stream = image.OpenReadStream();
                var result = await _predictionService.PredictAsync(stream);

                return Ok(new
                {
                    success = true,
                    message = "Prediction completed",
                    data = result
                });
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "Prediction service error");
                return StatusCode(503, new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning(ex, "Unauthorized access to prediction endpoint");
                return Unauthorized(new
                {
                    success = false,
                    message = "Unauthorized"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Prediction error");
                return StatusCode(500, new
                {
                    success = false,
                    message = "Prediction failed"
                });
            }
           
        }

        [HttpGet("classes")]
        [AllowAnonymous]
        public IActionResult GetClasses()
        {
            var classes = new[]
            {
                new { id = 0, name = "Bacterial Leaf Blight", severity = "high" },
                new { id = 1, name = "Brown Spot", severity = "medium" },
                new { id = 2, name = "Healthy Rice Leaf", severity = "none" },
                new { id = 3, name = "Leaf Blast", severity = "high" }
            };

            return Ok(new { success = true, total = classes.Length, data = classes });
        }

        // ✅ Đổi thành async vì IsModelLoaded() giờ là Task<bool>
        [HttpGet("health")]
        [AllowAnonymous]
        public async Task<IActionResult> Health()
        {
            var isLoaded = await _predictionService.IsModelLoaded();

            return Ok(new
            {
                status = isLoaded ? "ok" : "degraded",
                message = isLoaded
                    ? "Prediction service running"
                    : "Prediction service unavailable",
                modelLoaded = isLoaded
            });
        }
    }
}
