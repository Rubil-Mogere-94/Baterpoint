from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated, List

from ..database import get_db
from ..models import UserModel, RewardModel, UserRewardModel, NotificationModel
from ..schemas import Reward, UserReward
from ..dependencies import get_current_user

router = APIRouter(prefix="/rewards", tags=["Rewards"])

from pydantic import BaseModel

class XPRequest(BaseModel):
    xp_amount: int
    reason: str

@router.post("/xp/add", response_model=dict)
def add_xp(
    request: XPRequest,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """
    V4 Bater-Pass Engine:
    Add XP to a user's account for completing actions (trades, listing views, etc.)
    """
    try:
        # In a real app we'd have an XP tracking table.
        # For V4 Gamification, we'll re-use 'loyalty_points' as XP for now.
        current_user.loyalty_points += request.xp_amount
        db.commit()
        db.refresh(current_user)
        
        return {
            "status": "success",
            "message": f"Added {request.xp_amount} XP for {request.reason}",
            "new_xp_total": current_user.loyalty_points
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error adding XP: {str(e)}")

@router.get("/", response_model=List[Reward])
def get_rewards(db: Annotated[Session, Depends(get_db)]):
    rewards = db.query(RewardModel).all()
    if not rewards:
        # Seed rewards if empty
        seed = [
            RewardModel(title="Premium Status", description="Get a premium badge and 24h featured listings", points_cost=500, reward_type="status"),
            RewardModel(title="Verified Badge", description="Show a green checkmark on your profile", points_cost=200, reward_type="badge"),
            RewardModel(title="Deal Hunter", description="Receive notifications for ultra-deals 5 mins earlier", points_cost=300, reward_type="badge"),
        ]
        db.add_all(seed)
        db.commit()
        rewards = db.query(RewardModel).all()
    return rewards

@router.post("/{reward_id}/redeem", response_model=UserReward)
def redeem_reward(
    reward_id: int,
    current_user: Annotated[UserModel, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    try:
        reward = db.query(RewardModel).filter(RewardModel.id == reward_id).first()
        if not reward:
            raise HTTPException(status_code=404, detail="Reward not found")
        
        if current_user.loyalty_points < reward.points_cost:
            raise HTTPException(status_code=400, detail="Not enough loyalty points")
        
        # Check if already redeemed (optional, depending on type)
        if reward.reward_type == "badge":
            existing = db.query(UserRewardModel).filter(
                UserRewardModel.user_id == current_user.id,
                UserRewardModel.reward_id == reward_id
            ).first()
            if existing:
                raise HTTPException(status_code=400, detail="Reward already redeemed")
    
        # Deduct points
        current_user.loyalty_points -= reward.points_cost
        
        # Update status if applicable
        if reward.reward_type == "status" and reward.title == "Premium Status":
            current_user.subscription_status = "premium"
    
        user_reward = UserRewardModel(user_id=current_user.id, reward_id=reward.id)
        db.add(user_reward)
        db.commit()
        db.refresh(user_reward)
        
        # Mocking notification
        new_notif = NotificationModel(
            user_id=current_user.id, 
            title="Reward Redeemed!", 
            message=f"You've successfully redeemed {reward.title}."
        )
        db.add(new_notif)
        db.commit()
        
        return user_reward
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error redeeming reward: {str(e)}")
