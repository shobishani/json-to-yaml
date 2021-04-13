## base image
FROM python:3.8.2-slim-buster AS base-image

FROM base-image as compile-image

## install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

## virtualenv
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

## add and install requirements
RUN pip install --upgrade pip
ADD ./requirements.txt .
RUN pip install -r requirements.txt

## build-image
FROM base-image AS runtime-image

ENV PATH="/opt/venv/bin:$PATH"

## copy Python dependencies from build image
COPY --from=compile-image /opt/venv /opt/venv

## set working directory
WORKDIR /usr/src/app

## add app
COPY . .

# set execute permission to entrypoint
RUN mv ./etc/docker/entrypoint.sh ./ && \
    chmod +x ./entrypoint.sh

## run server
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
EXPOSE 5000