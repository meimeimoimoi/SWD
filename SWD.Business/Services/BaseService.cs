using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using SWD.Business.Interface;

namespace SWD.Business.Services
{
    public abstract class BaseService<TDto> : IService<TDto> where TDto : class
    {
        public virtual async Task<TDto> GetByIdAsync(Guid id)
        {
            // Implementation will be in derived classes
            throw new NotImplementedException();
        }

        public virtual async Task<IEnumerable<TDto>> GetAllAsync()
        {
            // Implementation will be in derived classes
            throw new NotImplementedException();
        }

        public virtual async Task<TDto> CreateAsync(TDto dto)
        {
            // Implementation will be in derived classes
            throw new NotImplementedException();
        }

        public virtual async Task<TDto> UpdateAsync(Guid id, TDto dto)
        {
            // Implementation will be in derived classes
            throw new NotImplementedException();
        }

        public virtual async Task<bool> DeleteAsync(Guid id)
        {
            // Implementation will be in derived classes
            throw new NotImplementedException();
        }
    }
}
