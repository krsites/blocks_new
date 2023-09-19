# Используем образ Alpine Linux как базовый образ
FROM alpine:latest

# Устанавливаем зависимости для сборки и генерации сайта
RUN apk add --no-cache ruby ruby-dev build-base libffi-dev zlib-dev nodejs npm

# Устанавливаем Jekyll и Bundler
RUN gem install jekyll bundler

# Копируем файлы проекта в контейнер
COPY . /app

# Устанавливаем рабочую директорию
WORKDIR /app

# Устанавливаем зависимости проекта
RUN bundle install

# Запускаем генерацию сайта
CMD ["jekyll", "build"]