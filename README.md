# Proyecto 2 - Sistema de Inventario y Ventas

## Descripcion General
Este proyecto es una aplicacion web completa para la gestion de inventario y ventas, desarrollado para el curso CC3088 Bases de Datos 1. Cuenta con un frontend construido en HTML/JS/CSS puro, un backend desarrollado con FastAPI (Python) y una base de datos relacional PostgreSQL. Toda la infraestructura esta orquestada y desplegada mediante Docker.

## 1. Instrucciones de Ejecucion y Configuracion

### Prerrequisitos
* Docker
* Docker Compose

### Variables de Entorno y Credenciales
Para cumplir con los requerimientos estrictos de calificacion, el sistema utiliza credenciales fijas. En la raiz del proyecto debe existir un archivo `.env` con la siguiente configuracion exacta:
```env
POSTGRES_USER=proy2
POSTGRES_PASSWORD=secret
POSTGRES_DB=proyecto2
POSTGRES_HOST=db
POSTGRES_PORT=5432
