using MyApp.Application.Features.TreeIllnesses.DTOs;
using MyApp.Application.Features.Users.DTOs;
﻿using MyApp.Application.Features.Prediction;

namespace MyApp.Application.Interfaces
{
    public interface IPredictionService
    {
        Task<PredictionResponseDto?> GetPredictionByUploadIdAsync(int uploadId);
        Task<PredictionResponseDto?> GetPredictionByIdAsync(int predictionId);
        Task<List<PredictionResponseDto>> GetUserPredictionsAsync(int userId);
        Task<(List<PredictionResponseDto> predictions, PaginationMetadata pagination)> GetFilteredUserPredictionsAsync(
            int userId,
            PredictionFilterRequestDto filter);
        Task<PredictionResponseDto> CreatePredictionAsync(int uploadId, int illnessId, decimal confidenceScore, string? topNPredictions = null);
        Task<PredictionResponseDto> PredictAsync(int userId, IFormFile imageFile);
        Task<bool> IsModelLoaded();
    }
}
