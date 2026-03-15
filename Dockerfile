FROM nginx:alpine

# Copy static files to nginx's default serve directory
COPY scotty-web/static /usr/share/nginx/html

# Remove the default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Write the nginx config template (with $PORT placeholder)
RUN printf 'server {\n\
    listen NGINX_PORT;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
    location ~* \\.json$ {\n\
        add_header Content-Type "application/json; charset=utf-8";\n\
    }\n\
}\n' > /etc/nginx/default.conf.template

# Railway provides PORT env var at runtime
ENV PORT=8080

EXPOSE 8080

# At startup: replace NGINX_PORT with actual $PORT value, then start nginx
CMD sh -c "sed s/NGINX_PORT/\$PORT/g /etc/nginx/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"