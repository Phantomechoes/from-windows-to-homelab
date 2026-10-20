# Reproducible shape of the hello-web image.
# Copy a static BusyBox into this directory before building. It is not in git.
FROM scratch
COPY busybox /busybox
COPY index.html /www/index.html
USER 65534:65534
EXPOSE 8080
ENTRYPOINT ["/busybox", "httpd", "-f", "-p", "8080", "-h", "/www"]
