from sqlalchemy.orm import Session
from typing import List, Optional, Type, Any
from domain.repositories.base import BaseRepository

class SQLAlchemyRepository(BaseRepository):
    def __init__(self, session: Session, model: Type[Any]):
        self.session = session
        self.model = model
    
    def find_by_id(self, entity_id: int) -> Optional[Any]:
        return self.session.query(self.model).filter(self.model.id == entity_id).first()
    
    def find_all(self) -> List[Any]:
        return self.session.query(self.model).all()
    
    def save(self, entity: Any) -> Any:
        self.session.add(entity)
        self.session.commit()
        self.session.refresh(entity)
        return entity
    
    def delete(self, entity_id: int) -> bool:
        entity = self.find_by_id(entity_id)
        if entity:
            self.session.delete(entity)
            self.session.commit()
            return True
        return False
    
    def update(self, entity_id: int, **kwargs) -> Optional[Any]:
        entity = self.find_by_id(entity_id)
        if entity:
            for key, value in kwargs.items():
                if hasattr(entity, key):
                    setattr(entity, key, value)
            self.session.commit()
            self.session.refresh(entity)
            return entity
        return None
