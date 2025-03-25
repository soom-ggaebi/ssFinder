"""
main application
"""

from fastapi import FastAPI
from app.routers import lost_item_router

app = FastAPI(title="Lost Items Pipeline API")

app.include_router(lost_item_router, prefix="/api")

@app.get("/", response_model=dict)
def root():
    return {"message": "hello"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
