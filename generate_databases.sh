#!/usr/bin/env bash
docker run --name dart_development -e POSTGRES_DB=dart_development -e POSTGRES_USER=dart -e POSTGRES_PASSWORD=dart  -p 5432:5432 -d postgres
docker run --name dart_test -e POSTGRES_DB=dart_test -e POSTGRES_USER=dart -e POSTGRES_PASSWORD=dart  -p 5433:5432 -d postgres
aqueduct db generate
aqueduct db upgrade --connect=postgres://dart:dart@localhost:5432/dart_development
aqueduct auth add-client --id de.spielgestalt.therealworld.mobile \
    --secret @3uikdMkx \
    --connect=postgres://dart:dart@localhost:5432/dart_development
    
