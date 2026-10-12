FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
RUN mkdir -p /usr/share/nginx/html/actuator && echo '{"status":"UP"}' > /usr/share/nginx/html/actuator/health
EXPOSE 8080
RUN sed -i 's/listen       80;/listen       8080;/g' /etc/nginx/conf.d/default.conf
CMD ["nginx", "-g", "daemon off;"]
