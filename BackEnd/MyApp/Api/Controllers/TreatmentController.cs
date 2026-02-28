using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/diseases")]
    [ApiController]
    public class TreatmentController : ControllerBase
    {
        private readonly ITreatmentService _treatmentService;
        private readonly ILogger<TreatmentController> _logger;

        public TreatmentController(ITreatmentService treatmentService, ILogger<TreatmentController> logger)
        {
            _treatmentService = treatmentService;
            _logger = logger;
        }

        [HttpGet("{id}/detail")]
        [AllowAnonymous]
        public async Task<IActionResult> GetDiseaseDetail(int id)
        {
            try
            {
                var detail = await _treatmentService.GetDiseaseDetailAsync(id);
                if (detail == null)
                    return NotFound(new { success = false, message = $"Disease with ID {id} not found." });

                return Ok(new { success = true, data = detail });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting disease detail for id={Id}", id);
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }
    }
}
