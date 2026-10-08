FROM python:3.12-slim AS dependencies

WORKDIR /app

COPY requirements.txt .

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

FROM dependencies AS test

COPY app/ ./app/

RUN python -m pytest app/tests

FROM dependencies AS runtime

COPY app/app.py ./app/app.py

EXPOSE 8080

CMD ["python", "-m", "app.app"]