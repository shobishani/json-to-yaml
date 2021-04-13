from flask import Flask
from werkzeug.middleware.proxy_fix import ProxyFix

from src import endpoints as yaml_apis
from src import healthcheck as health_check_api
def create_app():
    """Creates flask app and register blueprints
    Returns:
        app: Flask
    """
    app = Flask(__name__)
    app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)
    app.register_blueprint(yaml_apis.blueprint)
    app.register_blueprint(health_check_api.blueprint)

    return app

if __name__ == '__main__':
    test_app = create_app()
    test_app.run()
