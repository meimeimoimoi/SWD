using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Technician.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Enums;
using Microsoft.AspNetCore.Http;

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
        [AllowAnonymous]
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

        [HttpGet("{id}/images")]
        [AllowAnonymous]
        public async Task<IActionResult> GetImages(int id)
        {
            try
            {
                var images = await _technicianService.GetImagesBySolutionIdAsync(id);
                return Ok(new { success = true, total = images.Count, data = images });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching images for treatment {Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPost("{id}/images")]
        public async Task<IActionResult> UploadImage(int id, IFormFile file)
        {
            try
            {
                if (file == null || file.Length == 0)
                    return BadRequest(new { success = false, message = "Invalid file." });

                var image = await _technicianService.UploadSolutionImageAsync(id, file);
                return StatusCode(201, new { success = true, message = "Image uploaded.", data = image });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading image for treatment {Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpDelete("images/{imageId}")]
        public async Task<IActionResult> DeleteImage(int imageId)
        {
            try
            {
                var ok = await _technicianService.DeleteSolutionImageAsync(imageId);
                if (!ok)
                    return NotFound(new { success = false, message = "Image not found." });
                return Ok(new { success = true, message = "Image deleted." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting image {ImageId}.", imageId);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPatch("{id}/images/reorder")]
        public async Task<IActionResult> ReorderImages(int id, [FromBody] List<int> orderedIds)
        {
            try
            {
                if (orderedIds == null)
                    return BadRequest(new { success = false, message = "Invalid input." });

                var ok = await _technicianService.ReorderSolutionImagesAsync(id, orderedIds);
                if (!ok)
                    return BadRequest(new { success = false, message = "Reorder failed." });
                return Ok(new { success = true, message = "Reorder successful." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error reordering images for treatment {Id}.", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }
        [HttpPost]
        public async Task<IActionResult> CreateTreatment(CreateTreatmentDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                // Xử lý nhận nhiều ảnh từ multipart/form-data
                var files = Request.Form.Files;
                if (files != null && files.Count > 0)
                {
                    dto.Images = files.ToList();
                }
                var result = await _technicianService.CreateTreatmentAsync(dto);
                return StatusCode(201, new { success = true, message = "Treatment created successfully.", data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating treatment.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTreatment(int id, [FromBody] Application.Features.Admin.DTOs.UpdateTreatmentDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Invalid input.",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage) });

                var result = await _technicianService.UpdateTreatmentAsync(id, dto);
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
