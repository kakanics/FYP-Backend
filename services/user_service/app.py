import sys
import os

# Add shared components to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from flask import Flask
from flask_cors import CORS
from shared.config import BaseServiceConfig
from shared.utils.response import APIResponse
from infrastructure.web.controllers import bp
from infrastructure.database.connection import init_db

def create_app(config=None):
    app = Flask(__name__)
    
    # Load configuration
    config = config or BaseServiceConfig()
    app.config['DEBUG'] = config.debug
    app.config['TESTING'] = config.testing
    app.config['SECRET_KEY'] = config.secret_key
    
    # Set service name for identification
    os.environ['SERVICE_NAME'] = 'user-service'
    
    # Enable CORS
    CORS(app)
    
    # Initialize database
    init_db()
    
    # Register blueprints
    app.register_blueprint(bp, url_prefix='/api/v1')
    
    # Global error handlers
    @app.errorhandler(404)
    def not_found(error):
        return APIResponse.not_found("Endpoint not found")
    
    @app.errorhandler(500)
    def internal_error(error):
        return APIResponse.error("Internal server error", 500)
    
    @app.errorhandler(Exception)
    def handle_exception(e):
        return APIResponse.error(str(e), 500)
    
    return app

if __name__ == '__main__':
    app = create_app()
    config = BaseServiceConfig()
    app.run(host=config.host, port=config.port, debug=config.debug)
