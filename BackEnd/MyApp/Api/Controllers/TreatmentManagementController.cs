using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Technician.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Enums;

namespace MyApp.Api.Controllers
{
    [Route("api/treatments")]
    [ApiController]
    [Authorize(Roles = RolePolicy.TechnicianOrAdmin)]
    public class TreatmentManagementController : ControllerBase
    {
        private readonly ITechnicianService _technicianService;
        private readonly ILogger<TreatmentManagementController> _logger;

        public TreatmentManagementController(ITechnicianService technicianService, ILogger<TreatmentManagementController> logger)
        {
            _technicianService = technicianService;
            _logger            = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllTreatments()
        {
            try
            {
                var result = await _technicianService.GetAllTreatmentsAsync();
                return Ok(new { success = true, total = result.Count, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching treatments.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPost]
        public async Task<IActionResult> CreateTreatment([FromBody] CreateTreatmentDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                var result = await _technicianService.CreateTreatmentAsync(dto);
                return StatusCode(201, new { success = true, message = "Treatment created successfully.", data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating treatment.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPost("{id}/assign")]
        public async Task<IActionResult> AssignTreatmentToIllness(int id, [FromBody] AssignTreatmentToIllnessDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                var (success, message, data) = await _technicianService.AssignTreatmentToIllnessAsync(id, dto.IllnessId);
                if (!success)
                    return NotFound(new { success = false, message });
                return Ok(new { success = true, message, data });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error assigning treatment {Id} to illness.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }
    }
}
