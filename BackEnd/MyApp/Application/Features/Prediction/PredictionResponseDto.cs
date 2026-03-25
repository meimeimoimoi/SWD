using MyApp.Application.Features.Treatment.DTOs;
using MyApp.Application.Features.Technician.DTOs;

namespace MyApp.Application.Features.Prediction
{
    public class PredictionResponseDto
    {
        public int PredictionId { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public string PredictedClass { get; set; } = string.Empty;
        public double Confidence { get; set; }
        public long ProcessingTimeMs { get; set; }

        public int? IllnessId { get; set; }
        public string? DiseaseName { get; set; }
        public string? Symptoms { get; set; }
        public string? Causes { get; set; }

        public List<TreatmentDto> Treatments { get; set; } = new List<TreatmentDto>();
        public List<MedicineDto> Medicines { get; set; } = new List<MedicineDto>();

    }
    public class TreatmentDto
    {
        public string Name { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string? Ingredients { get; set; }
        public string? ShoppeUrl { get; set; }
        public List<SolutionImageDto> Images { get; set; } = new();
    }
    

 public class MedicineDto
    {  
        public string Name { get; set; } = string.Empty;
                public string Type { get; set; } = string.Empty;
    
                public string ImageUrl { get; set; } = string.Empty;
        public string? Ingredients { get; set; }
     public string Description { get; set; } = string.Empty;

    public string? ShoppeUrl { get; set; }

    public List<SolutionImageDto> Images { get; set; } = new();


    }
}
