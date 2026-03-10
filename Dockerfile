# Build aşaması
FROM oven/bun:1-debian AS builder
WORKDIR /app
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile
COPY . .
RUN bun next build

# Çalıştırma aşaması
FROM debian:bookworm-slim AS runner
WORKDIR /app

# Sistem paketlerini ve bağımlılıkları kur (UNZIP EKLENDI)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    ffmpeg \
    python3 \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# yt-dlp'yi doğrudan sisteme (global) kuruyoruz
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

# Bun kurulumu (Artık unzip yüklü olduğu için hata vermeyecek)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

ENV NODE_ENV=production
ENV PORT=3000

# Dosyaları kopyala
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 3000

# Uygulamayı başlat
CMD ["bun", "run", "server.js"]
