FROM python:3.10

ENV PYTHONUNBUFFERED=1

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/

# Compile bytecode and use copy link mode
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

WORKDIR /app

# Place executables in the environment at the front of the path
ENV PATH="/зн-/.venv/bin:$PATH"

# Install dependencies first (better layer caching)
COPY pyproject.toml /app/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-dev

# Copy service source
COPY . /app/

# Ensure environment is in sync (no dev deps)
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-dev

EXPOSE 8000

# Run FastAPI app with multiple workers, listen on all interfaces
CMD ["fastapi", "run", "--workers", "4", "--host", "0.0.0.0", "main.py"]
