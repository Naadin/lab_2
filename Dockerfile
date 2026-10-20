FROM python:3.12-alpine AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-alpine AS runtime

ARG LAB_LOGIN=unknown
ARG LAB_TOKEN=unknown

LABEL org.lab.login="$LAB_LOGIN" 
LABEL org.lab.token="$LAB_TOKEN"

ENV ROCKET_SIZE=Small
ENV LAB_LOGIN=$LAB_LOGIN
ENV LAB_TOKEN=$LAB_TOKEN
ENV PORT=8000

RUN addgroup -S appgroup && adduser -S naadin -G appgroup

WORKDIR /app

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY app/ .

RUN chown -R naadin:appgroup /app

USER naadin

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8000/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "1", "--access-logfile", "-", "--worker-tmp-dir", "/dev/shm", "app:app"]
