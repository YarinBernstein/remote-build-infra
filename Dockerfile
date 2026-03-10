# ==========================================
# Stage 1: Base Image
# ==========================================
# This is the starting point for all other stages
FROM almalinux:9 AS base

# Set the working directory inside the container
WORKDIR /app

# Install basic runtime dependencies using YUM cache
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum update -y && \
    yum install -y libstdc++ python3 python3-pip wget

# ==========================================
# Stage 2: Builder
# ==========================================
# This stage is for compiling the code
FROM base AS builder

# Install the C++ compiler
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y gcc-c++ 

# Install Python libraries using PIP cache
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    pip3 install pandas numpy

# Copy your source code files
COPY . .

# *** COMPILATION STEP ***
# Compiling main.cpp into an executable named 'my_app'
RUN g++ main.cpp -o my_app

# ==========================================
# Stage 3: Slim Image (For Clients)
# ==========================================
# The final, lightweight image for deployment
FROM base AS slim

# Copy only the compiled binary from the builder stage
COPY --from=builder /app/my_app .

CMD ["./my_app"]

# ==========================================
# Stage 4: Full Image (For Developers)
# ==========================================
# An image with extra tools for debugging and development
FROM builder AS full

# Install debugging tools using YUM cache
RUN --mount=type=cache,target=/var/cache/yum,sharing=locked \
    yum install -y gdb valgrind vim
    
# Install testing tools using PIP cache
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    pip3 install ipython pytest

CMD ["/bin/bash"]