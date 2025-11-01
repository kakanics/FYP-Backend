from flask import Flask, jsonify
from flask_cors import CORS

def create_app():
    app = Flask(__name__)
    CORS(app)
    
    @app.route('/health')
    def health():
        return jsonify({"status": "healthy", "service": "test-service"})
    
    @app.route('/')
    def home():
        return jsonify({
            "message": "Test Service is running in Kubernetes!",
            "service": "test-service",
            "version": "1.0.0"
        })
    
    @app.route('/api/test')
    def test():
        return jsonify({
            "message": "API endpoint working",
            "data": {"test": True, "timestamp": "2024-11-01T07:55:00Z"}
        })
    
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000, debug=True)
