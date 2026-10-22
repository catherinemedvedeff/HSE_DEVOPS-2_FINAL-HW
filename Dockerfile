FROM python:3.11-slim-bookworm AS builder

WORKDIR /build

RUN pip install --no-cache-dir \
    poetry \
    poetry-plugin-export \
    setuptools \
    wheel

COPY pyproject.toml poetry.lock README.md ./
COPY src/ ./src/

RUN mkdir -p dist && \
    poetry export \
        --without-hashes \
        --format constraints.txt \
        --output dist/constraints.txt && \
    poetry run python -m pip wheel \
        --isolated \
        --requirement dist/constraints.txt \
        --wheel-dir dist/vendor && \
    poetry build --format wheel


FROM python:3.11-slim-bookworm

WORKDIR /app

COPY --from=builder /build/dist /tmp/dist

RUN find /tmp/dist -name '*.whl' -exec \
        pip install --no-cache-dir --no-index --no-deps {} + && \
    rm -rf /tmp/dist

RUN groupadd --system audit && \
    useradd --system --gid audit --create-home audit

USER audit

EXPOSE 8080

CMD ["python", "-m", "audit_svc"]