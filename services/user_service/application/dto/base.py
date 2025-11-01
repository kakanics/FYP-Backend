from dataclasses import dataclass
from typing import Optional
from datetime import datetime

@dataclass
class BaseDTO:
    id: Optional[int] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
