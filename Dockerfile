FROM python:3.7-slim

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    python3-pip \
    curl \
    libopenblas-dev \
    python3-scipy \
    cython \
    libhdf5-dev \
    python3-h5py \
    portaudio19-dev \
    swig \
    libpulse-dev \
    libatlas-base-dev \
    gcc

RUN mkdir /app
WORKDIR /app

COPY precise ./precise
COPY runner ./runner
COPY .venv ./.venv
COPY requirements.txt ./
COPY setup.py ./

RUN pip install -e runner/
RUN pip install -e .


WORKDIR /app


