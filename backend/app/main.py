import os
import logging
import uuid
from contextvars import ContextVar
from pythonjsonlogger import jsonlogger
from fastapi import FastAPI, Request, status, HTTPException
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi_socketio import SocketManager
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from pydantic import ValidationError
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from .config import settings
from .routers import auth, listings, cart, orders, users, offers, chat, rewards, admin, coupons, forum, ai, analytics, config
from .database import engine, Base

request_id_ctx_var: ContextVar[str] = ContextVar("request_id", default="")

class CustomJsonFormatter(jsonlogger.JsonFormatter):
    def add_fields(self, log_record, record, message_dict):
        super().add_fields(log_record, record, message_dict)
        log_record['request_id'] = request_id_ctx_var.get()
        if not log_record.get('timestamp'):
            log_record['timestamp'] = datetime.now(timezone.utc).isoformat()
        log_record['level'] = (log_record.get('level') or record.levelname).upper()

handler = logging.StreamHandler()
formatter = CustomJsonFormatter('%(timestamp)s %(level)s %(name)s %(message)s')
handler.setFormatter(formatter)
root_logger = logging.getLogger()
root_logger.addHandler(handler)
root_logger.setLevel(logging.INFO)
logging.getLogger("uvicorn.access").disabled = True

logger = logging.getLogger(__name__)


def _error_response(status_code: int, error: str, message: str, request_id: str = "", details: list | None = None) -> dict:
    resp = {
        "success": False,
        "error": error,
        "message": message,
        "request_id": request_id,
    }
    if details:
        resp["details"] = details
    return resp


def add_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(RateLimitExceeded)
    async def _rate_limit_handler(request: Request, exc: RateLimitExceeded):
        rid = request_id_ctx_var.get()
        logger.warning(f"Rate limit exceeded: {get_remote_address(request)}")
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content=_error_response(
                status.HTTP_429_TOO_MANY_REQUESTS,
                "rate_limit_exceeded",
                "Whoa there, trader! You're moving a bit too fast. Take a break and try again in a moment.",
                rid,
            ),
        )

    @app.exception_handler(ValidationError)
    async def _validation_handler(request: Request, exc: ValidationError):
        rid = request_id_ctx_var.get()
        details = []
        for err in exc.errors():
            loc = " -> ".join(str(x) for x in err.get("loc", []))
            details.append({"field": loc, "message": err.get("msg", ""), "type": err.get("type", "")})
        logger.warning(f"Validation error: {details}")
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=_error_response(
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                "validation_error",
                "Please check your input and try again.",
                rid,
                details,
            ),
        )

    @app.exception_handler(HTTPException)
    async def _http_exception_handler(request: Request, exc: HTTPException):
        rid = request_id_ctx_var.get()
        return JSONResponse(
            status_code=exc.status_code,
            content=_error_response(
                exc.status_code,
                "http_error",
                exc.detail if isinstance(exc.detail, str) else str(exc.detail),
                rid,
            ),
        )

    @app.exception_handler(Exception)
    async def _generic_handler(request: Request, exc: Exception):
        rid = request_id_ctx_var.get()
        logger.exception(f"Unhandled exception: {exc}")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=_error_response(
                status.HTTP_500_INTERNAL_SERVER_ERROR,
                "internal_error",
                "Something went wrong on our end. Please try again later.",
                rid,
            ),
        )


app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Refactored and Enhanced API for Baterpoint",
    version=settings.VERSION,
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
)

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
add_error_handlers(app)

if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

@app.middleware("http")
async def add_request_id(request: Request, call_next):
    request_id = str(uuid.uuid4())
    token = request_id_ctx_var.set(request_id)
    try:
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response
    finally:
        request_id_ctx_var.reset(token)

sio = SocketManager(app=app)

logger.info("Initializing API routers...")
app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(listings.router, prefix=settings.API_V1_STR)
app.include_router(cart.router, prefix=settings.API_V1_STR)
app.include_router(orders.router, prefix=settings.API_V1_STR)
app.include_router(users.router, prefix=settings.API_V1_STR)
app.include_router(offers.router, prefix=settings.API_V1_STR)
app.include_router(chat.router, prefix=settings.API_V1_STR)
app.include_router(rewards.router, prefix=settings.API_V1_STR)
app.include_router(admin.router, prefix=settings.API_V1_STR)
app.include_router(coupons.router, prefix=settings.API_V1_STR)
app.include_router(forum.router, prefix=settings.API_V1_STR)
app.include_router(ai.router, prefix=f"{settings.API_V1_STR}/ai", tags=["ai"])
app.include_router(analytics.router, prefix=settings.API_V1_STR)
app.include_router(config.router, prefix=f"{settings.API_V1_STR}/config")
logger.info("API routers successfully initialized.")

@app.get("/health")
def health_check():
    return {"status": "healthy", "version": settings.VERSION}

@app.sio.on("connect")
async def handle_connect(sid, environ):
    logger.info(f"Client connected: {sid}")

Base.metadata.create_all(bind=engine)
logger.info("Database tables created/verified.")

os.makedirs(settings.STATIC_DIR, exist_ok=True)
os.makedirs(settings.CHAT_IMAGES_DIR, exist_ok=True)
os.makedirs(settings.LISTING_IMAGES_DIR, exist_ok=True)

app.mount("/static", StaticFiles(directory=settings.STATIC_DIR), name="static")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)