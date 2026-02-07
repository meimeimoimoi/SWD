using MyApp.Application.Features.AI.DTOs;

namespace MyApp.Application.Interfaces;

public interface IAIService
{
    Task<PreprocessImageResponseDto> PreprocessImageAsync(PreprocessImageRequestDto request);
    Task<InferenceResponseDto> RunInferenceAsync(InferenceRequestDto request);
}
