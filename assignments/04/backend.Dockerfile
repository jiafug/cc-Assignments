FROM nginx
COPY backend.nginx.conf /etc/nginx/nginx.conf
EXPOSE 80