import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

PROJECT_ROOT = Path(__file__).parents[2]
DATASET_DIR = PROJECT_ROOT / "dataset" / "datathon-2026-round-1"

DB_HOST = os.getenv("VINDATATHON_DB_HOST", "localhost")
DB_PORT = int(os.getenv("VINDATATHON_DB_PORT", "5432"))
DB_NAME = os.getenv("VINDATATHON_DB_NAME", "vindatathon")
DB_USER = os.getenv("VINDATATHON_DB_USER", "postgres")
DB_PASSWORD = os.getenv("VINDATATHON_DB_PASSWORD", "postgres")
DB_SCHEMA = os.getenv("VINDATATHON_DB_SCHEMA", "raw")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
CHUNK_SIZE = 10_000

TABLE_REGISTRY = {
    "customers": "CustomerRow",
    "orders": "OrderRow",
    "order_items": "OrderItemRow",
    "payments": "PaymentRow",
    "shipments": "ShipmentRow",
    "returns": "ReturnRow",
    "reviews": "ReviewRow",
    "products": "ProductRow",
    "inventory": "InventoryRow",
    "geography": "GeographyRow",
    "promotions": "PromotionRow",
    "web_traffic": "WebTrafficRow",
    "sales": "SalesRow",
}
