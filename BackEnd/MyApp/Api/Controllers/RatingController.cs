using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Enums;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace MyApp.Api.Controllers
{
    [Route("api/rating")]
    [ApiController]
    [Authorize]
    public class RatingController : ControllerBase
    {
        private readonly IRatingService _ratingService;
        private readonly ILogger<RatingController> _logger;

        public RatingController(IRatingService ratingService, ILogger<RatingController> logger)
        {
            _ratingService = ratingService;
            _logger = logger;
        }

        [HttpPost("prediction/{predictionId}")]
        public async Task<IActionResult> CreateRating(int predictionId, [FromBody] RatingRequestDto dto)
        {
            try
            {
                if (!ModelState.IsValid) return BadRequest(new { success = false, message = "Invalid data", errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });
                var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId)) return Unauthorized(new { success = false, message = "Unauthorized" });
                var rating = await _ratingService.CreateRatingAsync(userId, predictionId, dto);
                return CreatedAtAction(nameof(GetRatingByPrediction), new { predictionId }, new { success = true, message = "Rating submitted", data = rating });
            }
            catch (Exception ex) { return StatusCode(500, new { success = false, message = ex.Message }); }
        }

        [HttpGet("prediction/{predictionId}")]
        public async Task<IActionResult> GetRatingByPrediction(int predictionId)
        {
            try
            {
                var rating = await _ratingService.GetRatingByPredictionIdAsync(predictionId);
                if (rating == null) return NotFound(new { success = false, message = "Not found" });
                return Ok(new { success = true, data = rating });
            }
            catch (Exception ex) { return StatusCode(500, new { success = false, message = ex.Message }); }
        }

        [HttpGet("all")]
        [Authorize(Roles = RolePolicy.Admin)]
        public async Task<IActionResult> GetAllRatings()
        {
            try
            {
                var ratings = await _ratingService.GetAllRatingsAsync();
                return Ok(new { success = true, data = ratings });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all ratings");
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }
    }
}
