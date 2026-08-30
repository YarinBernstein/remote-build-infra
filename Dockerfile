# Stage 1: base runtime deps, shared by every other stage
FROM almalinux:9 AS base

WORKDIR /app

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum update -y && \
    yum install -y libstdc++ python3 python3-pip wget

# Stage 2: compiles the C++ binary
FROM base AS builder

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y gcc-c++

RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    pip3 install pandas numpy

COPY . .
RUN g++ main.cpp -o my_app

# Stage 3: slim runtime image - just the compiled binary
FROM base AS slim

COPY --from=builder /app/my_app .
CMD ["./my_app"]

# Stage 4: full dev image - adds debugging/testing tools
FROM builder AS full

RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y gdb valgrind vim

RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    pip3 install ipython pytest

CMD ["/bin/bash"]
