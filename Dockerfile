FROM nginx:alpine

WORKDIR /usr/share/nginx/html

COPY . .

RUN cp anchor.html index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
