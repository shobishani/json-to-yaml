import io
import uuid
from http import HTTPStatus

import yaml
from werkzeug.wsgi import FileWrapper
from flask import Blueprint, Response, request

blueprint = Blueprint('json-to-yaml-apis', __name__)

@blueprint.route('/json-to-yaml', methods=['POST'])
def json_to_yaml():
    if not request.is_json:
        return {
            "error": "BAD REQUEST JSON payload is required"
        }, HTTPStatus.BAD_REQUEST
    try:
        yaml_content = yaml.dump(request.get_json())
    except Exception as e:
        return {
            "error": str(e)
        }, HTTPStatus.BAD_REQUEST

    response = Response(
        FileWrapper(io.BytesIO(bytes(yaml_content, 'utf-8'))),
        mimetype='application/yaml',
        direct_passthrough=True,
        headers={
            "Content-Disposition": f'attatchment; filename={uuid.uuid4().hex}'
        }
    )
    return response
