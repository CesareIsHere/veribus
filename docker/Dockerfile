# Flutter web served by nginx.
#   docker compose -f docker/docker-compose.yml up --build
ARG FLUTTER_VERSION=3.47.5
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build

ARG ENV_FILE=env/dev.json
WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define-from-file=${ENV_FILE}

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
