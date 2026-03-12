from fastapi import APIRouter, Depends, HTTPException, status
import random
import asyncio

router = APIRouter()

# Mock AI Valuations
EVALUATIONS = [
    {"value": 50, "comment": "A classic! But probably covered in dust. I'd give you 50 Barter Coins for it if I was feeling generous."},
    {"value": 120, "comment": "Ooh, shiny! This has some decent utility. Solid 120 Barter Coins."},
    {"value": 500, "comment": "Woah, hold onto your hats! This is a rare find. Easily worth 500 Barter Coins to the right collector."},
    {"value": 15, "comment": "Are you sure this isn't literal trash? Just kidding... mostly. 15 Barter Coins, take it or leave it."},
    {"value": 250, "comment": "Very practical. A solid middle-tier barter item. I bet someone would trade a nice watch for this. 250 Coins."},
]

@router.post("/evaluate", status_code=status.HTTP_200_OK)
async def evaluate_item(item_name: str, description: str = ""):
    """
    Simulates an AI evaluating an item for barter.
    Returns a mocked value and a snarky/helpful comment.
    """
    # Simulate some "thinking" time for the UI to show off its scanning animation
    await asyncio.sleep(1.5) 
    
    # In a real app, we'd send `item_name` and `description` to an LLM like Gemini
    # For now, we pick a random mock evaluation
    
    evaluation = random.choice(EVALUATIONS)
    
    # Add a little fuzziness to the value so it feels less static
    fuzzy_value = evaluation["value"] + random.randint(-5, 15)
    
    return {
        "item_name": item_name,
        "estimated_value": fuzzy_value,
        "ai_comment": evaluation["comment"],
        "confidence_score": round(random.uniform(0.7, 0.98), 2)
    }
