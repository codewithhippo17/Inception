FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y procps dumb-init
COPY server.py .

# We will run this twice: once overriding the entrypoint (bad), and once using dumb-init (good).
ENTRYPOINT ["dumb-init", "--"]
CMD ["python", "-u", "server.py"]
