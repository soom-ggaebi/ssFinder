"""
main application
"""

from fastapi import FastAPI
import uvicorn
from config.config import FAST_API_HOST, FAST_API_PORT
from app.routers.lost_item_router import router as lost_item_router
import app.core.util as util

app = FastAPI(title="ssfinder DATA Collector")
util.LogConfig(active_log_file=True, file_name="info.log",
               mode="a", string_cut_mode=False)

@app.get("/")
@util.logger
def hello():
    return {"hello": "world"}


# 라우터 등록
app.include_router(lost_item_router, prefix="/api", tags=["lost-items"])

if __name__ == "__main__":
    uvicorn.run(app, host=FAST_API_HOST, port=FAST_API_PORT)