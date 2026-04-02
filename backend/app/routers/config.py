from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(tags=["config"])

class AppConfigResponse(BaseModel):
    minimum_version: str
    latest_version: str
    force_update: bool
    hot_update_message: str | None
    feature_flags: dict
    maintenance_mode: bool

@router.get("/app_config", response_model=AppConfigResponse)
async def get_app_config():
    """
    Returns dynamic configuration for the frontend apps.
    This acts as a Remote Config or 'Hot Update' endpoint.
    """
    return AppConfigResponse(
        minimum_version="1.0.0",
        latest_version="1.0.1",
        force_update=False,
        hot_update_message="A new Hot Patch is available. Enjoy the new Featured UI updates!",
        feature_flags={
            "enable_ai_valuator": True,
            "enable_premium_ui": True,
            "show_holographic_cards": True,
            "show_featured_carousel": True,
            "show_aurora_bg": True,
        },
        maintenance_mode=False
    )
