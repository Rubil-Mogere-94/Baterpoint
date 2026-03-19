import firebase_admin
from firebase_admin import credentials, messaging
from ..config import settings
import logging

logger = logging.getLogger(__name__)

# Initialize Firebase App
_firebase_app = None

def get_firebase_app():
    global _firebase_app
    if _firebase_app is None:
        path = settings.FIREBASE_SERVICE_ACCOUNT_PATH
        if path and import_os_exists(path):
            try:
                cred = credentials.Certificate(path)
                _firebase_app = firebase_admin.initialize_app(cred)
                logger.info("Firebase Admin SDK initialized successfully.")
            except Exception as e:
                logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        else:
            logger.warning("FIREBASE_SERVICE_ACCOUNT_PATH not set or file not found. Push notifications will be disabled.")
    return _firebase_app

def import_os_exists(path):
    import os
    return os.path.exists(path)

def send_push_notification(device_token: str, title: str, body: str, data: dict = None):
    """
    Sends a push notification to a specific device via FCM.
    """
    app = get_firebase_app()
    if not app:
        logger.debug("Firebase not initialized. Skipping notification.")
        return None

    if not device_token:
        logger.debug("No device token provided. Skipping notification.")
        return None

    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        token=device_token,
    )
    
    try:
        response = messaging.send(message)
        logger.info(f"Successfully sent message: {response}")
        return response
    except Exception as e:
        logger.error(f"Error sending FCM message: {e}")
        return None
