#!/bin/bash

#dwnld docker postgres

sudo docker pull postgres

# running and create database

sudo docker run --name  postgres-container -e POSTGRES_PASSWORD="@sde_password012" -e POSTGRES_USER="test_sde" -e POSTGRES_DB="demo" -v $HOME/sde_test_db:$HOME/sde_test_db -p 5432:5432 -d postgres

# run container for initiate database

sudo docker exec postgres-container psql -U test_sde -d demo -f ~/sde_test_db/sql/init_db/demo.sql