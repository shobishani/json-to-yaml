from src.app import create_app

def gunicorn_app():
    """
    Added this function so in future we might initialize database etc

    Returns:
        app
    """
    return create_app()
