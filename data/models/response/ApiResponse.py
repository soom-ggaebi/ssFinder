from pydantic import BaseModel, Field
from typing import Generic, TypeVar

T = TypeVar("T")

class ApiResponse(BaseModel, Generic[T]):
    status: str = Field(..., title="상태 코드")
    message: str = Field(..., title="메시지")
    data: T = Field(..., title="응답 데이터")
