FROM node:lts-alpine AS builder

WORKDIR /build

COPY app/package.json app/pnpm-lock.yaml ./

RUN npm install -g pnpm@9.11.0

RUN pnpm install --frozen-lockfile

COPY app/ .

RUN pnpm run build

# ---- Runtime Stage ----

FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=builder /build/dist /usr/share/nginx/html

RUN chown -R nginx:nginx /usr/share/nginx/html /tmp /var/cache/nginx

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]