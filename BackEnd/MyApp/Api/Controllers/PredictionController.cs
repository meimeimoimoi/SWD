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
        private readonly IMonitoringService _monitoringService;
        private readonly ILogger<PredictionController> _logger;
        private readonly MyApp.Persistence.Repositories.PredictionRepository _predictionRepository;

        public PredictionController(
            IPredictionService predictionService,
            IMonitoringService monitoringService,
            ILogger<PredictionController> logger,
            MyApp.Persistence.Repositories.PredictionRepository predictionRepository)
        {
            _predictionService = predictionService;
            _monitoringService = monitoringService;
            _logger = logger;
            _predictionRepository = predictionRepository;
        }

        [HttpPost("predict")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [Authorize]
        public async Task<IActionResult> Predict(
            IFormFile image,
            [FromForm] int? modelVersionId = null)
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
                    var result = await _predictionService.PredictAsync(userId, image, modelVersionId);
                    result.ImageUrl = BuildImageUrl(result.ImageUrl);
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

        [HttpGet("models")]
        [Authorize]
        public async Task<IActionResult> ListPredictionModels(CancellationToken cancellationToken)
        {
            try
            {
                var models =
                    await _predictionService.ListAvailablePredictionModelsAsync(cancellationToken);
                return Ok(new
                {
                    success = true,
                    total = models.Count,
                    data = models,
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error listing prediction models");
                return StatusCode(500, new { success = false, message = "Error loading models" });
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

        [HttpGet("common-threats")]
        [Authorize]
        public async Task<IActionResult> GetCommonThreats([FromQuery] int take = 5)
        {
            try
            {
                var data = await _monitoringService.GetCommonThreatsAsync(take);
                return Ok(new { success = true, data });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading common threats");
                return StatusCode(500, new { success = false, message = "Could not load common threats." });
            }
        }

        [HttpPatch("{id}")]
        [Authorize]
        public async Task<IActionResult> UpdatePrediction(int id, [FromBody] MyApp.Application.Features.Prediction.UpdatePredictionDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                var prediction = await _predictionRepository.GetPredictionByIdAsync(id);
                if (prediction == null)
                    return NotFound(new { success = false, message = $"Prediction with ID {id} not found." });

                if (dto.TreeId != null) prediction.TreeId = dto.TreeId;
                if (dto.IllnessId != null) prediction.IllnessId = dto.IllnessId;
                if (dto.PredictedClass != null) prediction.PredictedClass = dto.PredictedClass;

                await _predictionRepository.UpdatePredictionAsync(prediction);

                return Ok(new { success = true, message = "Prediction updated successfully.", data = new
                {
                    prediction.PredictionId,
                    prediction.TreeId,
                    prediction.IllnessId,
                    prediction.PredictedClass,
                    prediction.ConfidenceScore
                }});
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating prediction Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        private string BuildImageUrl(string? storedFilename)
        {
            if (string.IsNullOrWhiteSpace(storedFilename))
            {
                return string.Empty;
            }

            return $"{Request.Scheme}://{Request.Host}/uploads/images/{storedFilename}";
        }
    }
}
