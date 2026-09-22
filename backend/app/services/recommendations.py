try:
    from sentence_transformers import SentenceTransformer
    _HAS_SENTENCE_TRANSFORMERS = True
except ImportError:
    _HAS_SENTENCE_TRANSFORMERS = False

try:
    import numpy as np
    _HAS_NUMPY = True
except ImportError:
    _HAS_NUMPY = False

from sqlalchemy.orm import Session
from ..models import ListingModel, UserModel

_model = None

def get_model():
    global _model
    if not _HAS_SENTENCE_TRANSFORMERS:
        return None
    if _model is None:
        # Using a small, fast model
        _model = SentenceTransformer('all-MiniLM-L6-v2')
    return _model

def generate_embedding(text: str) -> list:
    m = get_model()
    if m is None:
        return []
    return m.encode(text).tolist()


def update_listing_embedding(db: Session, listing_id: int):
    listing = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not listing:
        return
    text = f"{listing.title} {listing.description or ''} {listing.category}"
    embedding = generate_embedding(text)
    listing.embedding = embedding
    db.commit()

def cosine_similarity(v1, v2):
    if not v1 or not v2:
        return 0.0
    v1 = np.array(v1)
    v2 = np.array(v2)
    norm1 = np.linalg.norm(v1)
    norm2 = np.linalg.norm(v2)
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return np.dot(v1, v2) / (norm1 * norm2)

def find_similar_listings(db: Session, listing_id: int, limit: int = 10):
    target = db.query(ListingModel).filter(ListingModel.id == listing_id).first()
    if not target or not target.embedding:
        return []
    
    # In a real large-scale app, we'd use pgvector or a vector DB
    # For this scale, we can fetch all and rank in memory
    candidates = db.query(ListingModel).filter(
        ListingModel.id != listing_id,
        ListingModel.embedding.isnot(None)
    ).all()
    
    if not candidates:
        return []

    # Sort by similarity
    candidates.sort(
        key=lambda l: cosine_similarity(target.embedding, l.embedding),
        reverse=True
    )
    return candidates[:limit]

def recommend_for_user(db: Session, user_id: int, limit: int = 10):
    # Basic logic: Find listings similar to what the user has favorited
    from ..models import FavoriteModel
    
    favorites = db.query(ListingModel).join(FavoriteModel).filter(FavoriteModel.user_id == user_id).all()
    if not favorites:
        # Fallback to trending
        return db.query(ListingModel).order_by(ListingModel.view_count.desc()).limit(limit).all()
    
    # Average the embeddings of favorites to create a user "interest vector"
    embeddings = [f.embedding for f in favorites if f.embedding]
    if not embeddings:
        return db.query(ListingModel).order_by(ListingModel.view_count.desc()).limit(limit).all()
    
    user_vector = np.mean(embeddings, axis=0).tolist()
    
    # Find listings similar to the user vector
    exclude_ids = [f.id for f in favorites]
    candidates = db.query(ListingModel).filter(
        ~ListingModel.id.in_(exclude_ids),
        ListingModel.embedding.isnot(None)
    ).all()
    
    candidates.sort(
        key=lambda l: cosine_similarity(user_vector, l.embedding),
        reverse=True
    )
    return candidates[:limit]
