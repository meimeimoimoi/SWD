using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/admin")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class DashboardController : ControllerBase
    {
        private readonly IMonitoringService _monitoringService;
        private readonly ILogger<DashboardController> _logger;

        public DashboardController(IMonitoringService monitoringService, ILogger<DashboardController> logger)
        {
            _monitoringService = monitoringService;
            _logger = logger;
        }

        [HttpGet("stats")]
        public async Task<IActionResult> GetStats()
        {
            try
            {
                var stats = await _monitoringService.GetDashboardStatsAsync();
                return Ok(new { success = true, data = stats });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching dashboard stats.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpGet("predictions/stats")]
        public async Task<IActionResult> GetPredictionStats([FromQuery] int days = 7)
        {
            try
            {
                var stats = await _monitoringService.GetPredictionStatsAsync(days);
                return Ok(new { success = true, data = stats });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching prediction stats.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpGet("models/accuracy")]
        public async Task<IActionResult> GetModelAccuracy()
        {
            try
            {
                var accuracy = await _monitoringService.GetModelAccuracyAsync();
                return Ok(new { success = true, data = accuracy });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching model accuracy.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpGet("ratings")]
        public async Task<IActionResult> GetRatings([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            try
            {
                var ratings = await _monitoringService.GetRatingsAsync(page, pageSize);
                return Ok(new { success = true, page, pageSize, total = ratings.Count, data = ratings });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching ratings.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }
    }
}
