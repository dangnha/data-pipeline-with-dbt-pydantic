from decimal import Decimal
from pydantic import BaseModel, Field


class ProductRow(BaseModel):
    product_id: int = Field(gt=0)
    product_name: str
    category: str
    segment: str
    size: str
    color: str
    price: Decimal = Field(max_digits=15, decimal_places=2, gt=0)
    cogs: Decimal = Field(max_digits=15, decimal_places=2, gt=0)
