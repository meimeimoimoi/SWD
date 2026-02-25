namespace MyApp.Application.Features.Users.DTOs
{
    public class SolutionConditionDto
    {
        public int ConditionId { get; set; }
        public decimal? MinConfidence { get; set; }
        public string? WeatherCondition { get; set; }
        public string? Note { get; set; }
    }
}
