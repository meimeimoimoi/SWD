using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SWD.Business.Interface
{
    public interface IService<TDto> where TDto : class
    {
        Task<TDto> GetByIdAsync(Guid id);
        Task<IEnumerable<TDto>> GetAllAsync();
        Task<TDto> CreateAsync(TDto dto);
        Task<TDto> UpdateAsync(Guid id, TDto dto);
        Task<bool> DeleteAsync(Guid id);
    }
}
