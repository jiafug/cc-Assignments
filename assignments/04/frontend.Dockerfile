FROM nginx
COPY frontend.nginx.conf /etc/nginx/nginx.conf
EXPOSE 80