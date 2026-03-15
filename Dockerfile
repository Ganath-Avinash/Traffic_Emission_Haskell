FROM nginx:alpine

# Copy static files to nginx's default serve directory
COPY scotty-web/static /usr/share/nginx/html

# Custom nginx config to handle routing properly
RUN echo 'server { \
    listen 3000; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location ~* \\.json$ { \
        add_header Content-Type "application/json; charset=utf-8"; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]