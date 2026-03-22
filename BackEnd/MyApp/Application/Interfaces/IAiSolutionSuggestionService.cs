using MyApp.Application.Features.Treatment.DTOs;

namespace MyApp.Application.Interfaces;

public interface IAiSolutionSuggestionService
{
    Task<AiSolutionSuggestResponse> SuggestAsync(AiSolutionSuggestRequest request, CancellationToken cancellationToken = default);
}
