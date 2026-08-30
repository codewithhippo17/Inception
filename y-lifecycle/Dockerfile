FROM debian:latest
WORKDIR /app
COPY worker.sh startup.sh ./
RUN chmod +x worker.sh startup.sh

# We correctly use Exec Form here, BUT the bash logic inside is fatally flawed.
ENTRYPOINT ["./startup.sh"]