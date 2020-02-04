FROM nginx:alpine
RUN mkdir app
COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/index.html /app/index.html
WORKDIR /app
USER 1001
EXPOSE 8000/tcp