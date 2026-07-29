from decimal import Decimal
from datetime import date
from pydantic import BaseModel, Field


class SalesRow(BaseModel):
    date: date
    revenue: Decimal = Field(max_digits=15, decimal_places=2, ge=0, alias="Revenue")
    cogs: Decimal = Field(max_digits=15, decimal_places=2, ge=0, alias="COGS")
