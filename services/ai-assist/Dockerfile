# Start from a small official Python image (3.13, same as the M5 Function)
FROM python:3.13-slim

# Work inside /app in the container
WORKDIR /app

# Copy the library list first, so Docker can reuse this layer when only code changes
COPY requirements.txt .

# Install the pinned libraries; --no-cache-dir keeps the image small
RUN pip install --no-cache-dir -r requirements.txt

# Copy the service code (evals.py stays out: it's a test, not part of the service)
COPY main.py .

# Document the port the app listens on
EXPOSE 8000

# Start uvicorn; 0.0.0.0 = accept traffic from outside the container (127.0.0.1 would only listen inside it)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]