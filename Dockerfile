# HydraMesh + StreamDB + AI Agents Lab
# Multi-stage build for minimal production image
#
# Copyright (C) 2025 DeMoD LLC - GPL-3.0

# ============================================================================
# Stage 1: Build StreamDB and dependencies
# ============================================================================
FROM debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    make \
    libc6-dev \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    sbcl \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Build StreamDB
WORKDIR /build/streamdb
COPY streamdb/ .
RUN make shared static && \
    make install DESTDIR=/install PREFIX=/usr

# Install Python dependencies
WORKDIR /build/python
RUN python3 -m venv /install/opt/hydramesh/venv && \
    /install/opt/hydramesh/venv/bin/pip install --no-cache-dir \
        requests \
        pytest \
        black \
        mypy

# Copy agent-tools
COPY agent-tools/ /install/opt/hydramesh/agent-tools/

# Copy HydraMesh Lisp sources
COPY hydramesh/ /install/opt/hydramesh/lisp/

# Install Quicklisp for SBCL
RUN curl -o /tmp/quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp && \
    sbcl --non-interactive \
         --load /tmp/quicklisp.lisp \
         --eval '(quicklisp-quickstart:install :path "/install/opt/hydramesh/quicklisp/")' \
         --eval '(quit)' && \
    rm /tmp/quicklisp.lisp

# ============================================================================
# Stage 2: Production image
# ============================================================================
FROM debian:bookworm-slim AS runtime

LABEL maintainer="DeMoD LLC"
LABEL description="HydraMesh - UDP Gaming/Audio Framework with StreamDB"
LABEL version="2.2.0"
LABEL license="GPL-3.0"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    sbcl \
    netcat-openbsd \
    nmap \
    curl \
    dnsutils \
    jq \
    procps \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash hydramesh

# Copy built artifacts from builder
COPY --from=builder /install/usr/lib/libstreamdb.* /usr/lib/
COPY --from=builder /install/usr/include/streamdb*.h /usr/include/
COPY --from=builder /install/opt/hydramesh /opt/hydramesh

# Update library cache
RUN ldconfig

# Set up environment
ENV PATH="/opt/hydramesh/venv/bin:$PATH"
ENV PYTHONPATH="/opt/hydramesh/agent-tools"
ENV HYDRAMESH_HOME="/opt/hydramesh"
ENV HYDRAMESH_DB="/var/lib/hydramesh/streamdb.dat"
ENV SBCL_HOME="/usr/lib/sbcl"

# Create data directories
RUN mkdir -p /var/lib/hydramesh /var/log/hydramesh && \
    chown -R hydramesh:hydramesh /var/lib/hydramesh /var/log/hydramesh

# Copy entrypoint script
COPY --chmod=755 <<'EOF' /usr/local/bin/hydramesh-entrypoint
#!/bin/bash
set -e

# Create Quicklisp setup if needed
if [ ! -f ~/.sbclrc ]; then
    cat > ~/.sbclrc << 'SBCLRC'
#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp" "/opt/hydramesh/")))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))
SBCLRC
fi

case "${1:-shell}" in
    lisp|sbcl)
        shift
        exec sbcl --load /opt/hydramesh/lisp/hydramesh.lisp "$@"
        ;;
    python|py)
        shift
        exec python3 "$@"
        ;;
    agent-test)
        shift
        exec python3 -m pytest /opt/hydramesh/agent-tools/tests/ -v "$@"
        ;;
    hydramesh)
        shift
        exec sbcl --non-interactive \
             --load /opt/hydramesh/lisp/hydramesh.lisp \
             --eval "(main $*)"
        ;;
    streamdb-test)
        echo "Testing StreamDB library..."
        python3 << 'PYTEST'
import ctypes
import sys

lib = ctypes.CDLL("libstreamdb.so")
print(f"✓ StreamDB library loaded")

# Test version
lib.streamdb_version.restype = ctypes.c_char_p
version = lib.streamdb_version().decode()
print(f"✓ StreamDB version: {version}")

# Test init (memory-only)
lib.streamdb_init.restype = ctypes.c_void_p
db = lib.streamdb_init(None, 0)
if db:
    print(f"✓ Memory-only database created")
    lib.streamdb_free(db)
    print(f"✓ Database freed")
else:
    print("✗ Failed to create database")
    sys.exit(1)

print("\n✓ All StreamDB tests passed!")
PYTEST
        ;;
    shell|bash)
        exec /bin/bash
        ;;
    *)
        exec "$@"
        ;;
esac
EOF

WORKDIR /home/hydramesh
USER hydramesh

# Default ports
EXPOSE 7777/udp 7778/udp 50051/tcp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s \
    CMD python3 -c "import socket; s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.bind(('',0)); s.close()" || exit 1

ENTRYPOINT ["/usr/local/bin/hydramesh-entrypoint"]
CMD ["shell"]
