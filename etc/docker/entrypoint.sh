#!/bin/bash

gunicorn --bind 0.0.0.0:5000 --workers 4 'bin.run_api:gunicorn_app()'