FROM python:3.11-slim

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy shared components
COPY ../../shared/ ./shared/
COPY ../../db_manager/ ./db_manager/

# Copy service code
COPY . .

EXPOSE 8084

CMD ["python", "app.py"]
