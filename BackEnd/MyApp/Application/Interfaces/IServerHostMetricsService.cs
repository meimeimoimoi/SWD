using MyApp.Application.Features.Admin.DTOs;

namespace MyApp.Application.Interfaces;

public interface IServerHostMetricsService
{
    Task<ServerHostStatusSimpleDto> GetSimpleAsync(CancellationToken cancellationToken = default);

    Task<ServerHostStatusDetailDto> GetDetailAsync(CancellationToken cancellationToken = default);
}
