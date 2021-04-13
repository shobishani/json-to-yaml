from flask import Blueprint
from werkzeug import serving

blueprint = Blueprint('health-endpoints', __name__)

parent_log_request = serving.WSGIRequestHandler.log_request

def log_request(self, *args, **kwargs):
    excluded = [
        '/healthz',
        '/healthx',
        '/startup'
    ]
    if self.path in excluded:
        return

    parent_log_request(self, *args, **kwargs)

serving.WSGIRequestHandler.log_request = log_request

@blueprint.route('/healthz')
def healthz():
    return "OK"

@blueprint.route('/healthx')
def healthx():
    return 'OK', 200

@blueprint.route('/startup')
def startup():
    return 'OK', 200
