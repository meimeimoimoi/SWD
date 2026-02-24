namespace MyApp.Application.Features.Users.DTOs
{
    public class TopPredictionDto
    {
        public string Class { get; set; } = null!;
        public decimal Confidence { get; set; }
        public string IllnessName { get; set; } = null!;
    }
}
