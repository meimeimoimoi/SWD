using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

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
                    return BadRequest(new { success = false, message = "Không tìm thấy hình ảnh" });
                }

                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
                var extension = Path.GetExtension(image.FileName).ToLowerInvariant();

                if (!allowedExtensions.Contains(extension))
                {
                    return BadRequest(new { success = false, message = "Không đúng định dạng" });
                }

                const long maxFileSize = 10 * 1024 * 1024;
                if (image.Length > maxFileSize)
                {
                    return BadRequest(new { success = false, message = "File không vượt quá 10MB" });
                }

                _logger.LogInformation("Predicting: {FileName} ({Size} bytes)",
                    image.FileName, image.Length);

                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                                    ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

                if(!int.TryParse(userIdClaim, out var userId))
                {
                    return Unauthorized();
                }

                try
                {
                    var result = await _predictionService.PredictAsync(userId, image);
                    return Ok(new
                    {
                        success = true,
                        message = "Dự đoán thành công.",
                        data = result
                    });
                }
                catch(Exception ex)
                {
                    _logger.LogError(ex, "Lỗi dự đoán");
                    return StatusCode(500, new { success = false, message = "Lỗi hệ thống" });
                }

                
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "Lỗi server.");
                return StatusCode(503, new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning(ex, "Bạn không có quyền truy cập tính năng này.");
                return Unauthorized(new
                {
                    success = false,
                    message = "Unauthorized"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi dự đoán");
                return StatusCode(500, new
                {
                    success = false,
                    message = "Lỗi dự đoán"
                });
            }
           
        }

        [HttpGet("classes")]
        [AllowAnonymous]
        public IActionResult GetClasses()
        {
            var classes = new[]
            {
                new { id = 0, name = "Bạc lá do vi khuẩn", severity = "Cao" },
                new { id = 1, name = "Đốm nâu", severity = "Vừa" },
                new { id = 2, name = "Lá lúa khỏe", severity = "Không" },
                new { id = 3, name = "Cháy lá", severity = "Cao" }
            };

            return Ok(new { success = true, total = classes.Length, data = classes });
        }

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
