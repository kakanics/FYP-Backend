from abc import ABC, abstractmethod
from typing import List, Optional, Any

class BaseRepository(ABC):
    @abstractmethod
    def find_by_id(self, entity_id: int) -> Optional[Any]:
        pass
    
    @abstractmethod
    def find_all(self) -> List[Any]:
        pass
    
    @abstractmethod
    def save(self, entity: Any) -> Any:
        pass
    
    @abstractmethod
    def delete(self, entity_id: int) -> bool:
        pass
    
    @abstractmethod
    def update(self, entity_id: int, **kwargs) -> Optional[Any]:
        pass
