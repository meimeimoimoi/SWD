using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Enums;

namespace MyApp.Api.Controllers
{
    [Route("api/admin/review")]
    [ApiController]
    [Authorize(Roles = RolePolicy.AdminOrTechnician)]
    public class ReviewController : ControllerBase
    {
        private readonly IReviewService _reviewService;
        private readonly ILogger<ReviewController> _logger;

        public ReviewController(IReviewService reviewService, ILogger<ReviewController> logger)
        {
            _reviewService = reviewService;
            _logger = logger;
        }


        [HttpGet("treatments")]
        public async Task<IActionResult> GetAllTreatments()
        {
            try
            {
                var result = await _reviewService.GetAllTreatmentsAsync();
                return Ok(new { success = true, total = result.Count, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching treatments.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpGet("treatments/{id}")]
        public async Task<IActionResult> GetTreatmentById(int id)
        {
            try
            {
                var result = await _reviewService.GetTreatmentByIdAsync(id);
                if (result == null)
                    return NotFound(new { success = false, message = $"Treatment with ID {id} not found." });
                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching treatment Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPut("treatments/{id}")]
        public async Task<IActionResult> UpdateTreatment(int id, [FromBody] UpdateTreatmentDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                var result = await _reviewService.UpdateTreatmentAsync(id, dto);
                if (result == null)
                    return NotFound(new { success = false, message = $"Treatment with ID {id} not found." });
                return Ok(new { success = true, message = "Treatment updated successfully.", data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating treatment Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpDelete("treatments/{id}")]
        public async Task<IActionResult> DeleteTreatment(int id)
        {
            try
            {
                var result = await _reviewService.DeleteTreatmentAsync(id);
                if (!result)
                    return NotFound(new { success = false, message = $"Treatment with ID {id} not found." });
                return Ok(new { success = true, message = "Treatment deleted successfully." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting treatment Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }


        [HttpGet("models")]
        public async Task<IActionResult> GetAllModels()
        {
            try
            {
                var result = await _reviewService.GetAllModelsAsync();
                return Ok(new { success = true, total = result.Count, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching models.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPatch("models/{id}/activate")]
        public async Task<IActionResult> ActivateModel(int id)
        {
            try
            {
                var result = await _reviewService.ActivateModelAsync(id);
                if (result == null)
                    return NotFound(new { success = false, message = $"Model with ID {id} not found." });
                return Ok(new { success = true, message = $"Model '{result.ModelName}' v{result.Version} is now active.", data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error activating model Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPatch("models/{id}/deactivate")]
        public async Task<IActionResult> DeactivateModel(int id)
        {
            try
            {
                var result = await _reviewService.DeactivateModelAsync(id);
                if (!result)
                    return NotFound(new { success = false, message = $"Model with ID {id} not found." });
                return Ok(new { success = true, message = $"Model ID={id} has been deactivated." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deactivating model Id={Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }
    }
}
