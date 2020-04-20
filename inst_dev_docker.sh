#!/bin/bash

#Cria o arquivo Dockerfile que recebe as instruções para gerar a nossa imagem docker do backend.
echo 'FROM golang:1.12.0-alpine3.9
RUN mkdir /app
RUN apk add --update git gcc musl-dev
RUN go get -u github.com/gorilla/mux
RUN go get -u github.com/mattn/go-sqlite3
RUN go get -u github.com/sirupsen/logrus
ADD . /app
WORKDIR /app
RUN go build -o main
EXPOSE 8080
ENTRYPOINT ["/app/main"]' > /bexs-devops-exam/backend/src/backend/Dockerfile

#Cria o arquivo Dockerfile que recebe as instruções para gerar a nossa imagem docker do frontend.
echo 'FROM python:3.8-alpine
WORKDIR /app
ADD . /app
RUN pip install virtualenv
RUN python3 -m virtualenv --python=/usr/local/bin/python3 /opt/venv
RUN . /opt/venv/bin/activate && pip install -r requirements.txt
EXPOSE 8000
CMD . /opt/venv/bin/activate && exec python frontend.py' > /bexs-devops-exam/frontend/src/frontend/Dockerfile


#Efetuando o build da imagem docker da aplicação backend
docker build -t go-backend /bexs-devops-exam/backend/src/backend/

#Alterando o arquivo frontend.py para que consiga efetuar a comunicação com o backend dentro da rede docker
sed -i  's/localhost/bexs-devops-exam_go-backend_1/g' /bexs-devops-exam/frontend/src/frontend/frontend.py

#Efetuando o build da imagem docker da aplicação frontend
docker build -t py-frontend /bexs-devops-exam/frontend/src/frontend/

#Criando o arquivo docker-compose.yml para subir os serviços do backend e frontend.
echo 'version: "3"

services:

  py-frontend:
    image: py-frontend
    ports:
      - "8000:8000"
    networks:
      - rede_docker


  go-backend:
    image: go-backend
    ports:
      - "8080:8080"
    networks:
      - rede_docker

networks:
  rede_docker:
    driver: overlay' > /bexs-devops-exam/docker-compose.yml

#Inicilizando o docker swarm
cd /bexs-devops-exam ; docker swarm init

#Iniciando a stack contendo o backend e o frontend.
docker-compose -f /bexs-devops-exam/docker-compose.yml up
