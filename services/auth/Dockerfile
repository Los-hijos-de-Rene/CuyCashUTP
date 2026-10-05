FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# El puerto lo decide quien despliega: Render y Cloud Run lo inyectan en $PORT.
# Por eso la forma shell, que expande la variable; la forma exec la pasaría
# como texto literal y el servicio nunca respondería.
EXPOSE 8001
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8001}"]
