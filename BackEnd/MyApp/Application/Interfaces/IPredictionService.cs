using System.Threading;
using Microsoft.AspNetCore.Http;
using MyApp.Application.Features.Prediction;

namespace MyApp.Application.Interfaces
{
    public interface IPredictionService
    {
        Task<PredictionResponseDto> PredictAsync(
            int userId,
            IFormFile imageFile,
            int? modelVersionId = null);

        Task<IReadOnlyList<PredictionModelListItemDto>> ListAvailablePredictionModelsAsync(
            CancellationToken cancellationToken = default);

        Task<bool> IsModelLoaded();

        /// <summary>Which model version ID is loaded in the shared inference session, if any.</summary>
        int? GetLoadedModelVersionId();
    }
}
