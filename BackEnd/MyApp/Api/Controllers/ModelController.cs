using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.ModelManagement.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/admin/models")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class ModelController : ControllerBase
    {
        private readonly IModelService _modelService;
        private readonly ILogger<ModelController> _logger;

        public ModelController(IModelService modelService, ILogger<ModelController> logger)
        {
            _modelService = modelService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllModels()
        {
            try
            {
                var models = await _modelService.GetAllModelsAsync();
                return Ok(new
                {
                    success = true,
                    message = "Model list retrieved successfully.",
                    total = models.Count,
                    data = models
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting model list.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPost]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadModel([FromForm] UploadModelDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid input data.",
                        errors = ModelState.Values
                            .SelectMany(v => v.Errors)
                            .Select(e => e.ErrorMessage)
                    });
                }

                var (success, message, data) = await _modelService.UploadModelAsync(dto);

                if (!success)
                    return Conflict(new { success = false, message });

                return CreatedAtAction(nameof(GetAllModels), new { },
                    new { success = true, message, data });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading model.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPatch("{id}/active")]
        public async Task<IActionResult> ActivateModel(int id)
        {
            try
            {
                var result = await _modelService.ActivateModelAsync(id);
                if (result == null)
                    return NotFound(new { success = false, message = $"Model with ID {id} not found." });

                return Ok(new
                {
                    success = true,
                    message = $"Model '{result.ModelName}' v{result.Version} is now active and set as default.",
                    data = result
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error activating model Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }
    }
}
