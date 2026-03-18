using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/admin/settings")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class SettingsController : ControllerBase
    {
        private readonly ISystemSettingService _settingService;
        private readonly ILogger<SettingsController> _logger;

        public SettingsController(ISystemSettingService settingService, ILogger<SettingsController> logger)
        {
            _settingService = settingService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllSettings()
        {
            try
            {
                var settings = await _settingService.GetAllSettingsAsync();
                return Ok(new { success = true, data = settings });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching settings.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPut("{key}")]
        public async Task<IActionResult> UpdateSetting(string key, [FromBody] UpdateSettingRequest request)
        {
            try
            {
                var result = await _settingService.UpdateSettingAsync(key, request.Value);
                if (!result)
                    return NotFound(new { success = false, message = $"Setting with key '{key}' not found." });

                return Ok(new { success = true, message = "Setting updated successfully." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating setting '{Key}'.", key);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }
    }

    public class UpdateSettingRequest
    {
        public string Value { get; set; } = null!;
    }
}
