# 1. Build aşaması
FROM oven/bun:1-debian AS builder
WORKDIR /app
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile
COPY . .
RUN bun next build

# 2. Çalıştırma aşaması
FROM oven/bun:1-debian AS runner
WORKDIR /app

# Gerekli sistem paketleri
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg python3 curl ca-certificates && rm -rf /var/lib/apt/lists/*

# yt-dlp kurulumu
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

# yt-dlp konfigürasyonu (Hem /etc hem kullanıcı dizinine ekliyoruz ki kesin okusun)
RUN mkdir -p /etc/yt-dlp && \
    echo '--cookies /app/cookies.txt' > /etc/yt-dlp.conf && \
    echo '--user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"' >> /etc/yt-dlp.conf && \
    mkdir -p /root/.config/yt-dlp && \
    cp /etc/yt-dlp.conf /root/.config/yt-dlp/config

# Çevresel değişkenler
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Dosyaları kopyala
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 3000

# Base64 çerezlerini dosyaya yaz ve uygulamayı başlat
CMD sh -c "echo '$YT_COOKIES' | base64 -di > /app/cookies.txt && bun run server.js"
