-- PROYECTO 2 - Sistema de Inventario y Ventas
-- CC3088 Bases de Datos 1 - Universidad del Valle de Guatemala
-- DDL 


-- 1. CATEGORIA

CREATE TABLE categoria (
    categoria_id  SERIAL          PRIMARY KEY,
    nombre        VARCHAR(100)    NOT NULL UNIQUE,
    descripcion   TEXT
);


-- 2. PROVEEDOR

CREATE TABLE proveedor (
    proveedor_id  SERIAL          PRIMARY KEY,
    nombre        VARCHAR(150)    NOT NULL,
    telefono      VARCHAR(20),
    email         VARCHAR(150)    UNIQUE,
    direccion     VARCHAR(255)
);


-- 3. CLIENTE

CREATE TABLE cliente (
    cliente_id    SERIAL          PRIMARY KEY,
    nombre        VARCHAR(100)    NOT NULL,
    apellido      VARCHAR(100)    NOT NULL,
    email         VARCHAR(150)    UNIQUE,
    telefono      VARCHAR(20),
    direccion     VARCHAR(255)
);


-- 4. EMPLEADO

CREATE TABLE empleado (
    empleado_id   SERIAL          PRIMARY KEY,
    nombre        VARCHAR(100)    NOT NULL,
    apellido      VARCHAR(100)    NOT NULL,
    cargo         VARCHAR(80)     NOT NULL,
    email         VARCHAR(150)    NOT NULL UNIQUE,
    password_hash VARCHAR(255)    NOT NULL
);


-- 5. PRODUCTO

CREATE TABLE producto (
    producto_id     SERIAL              PRIMARY KEY,
    categoria_id    INT                 NOT NULL,
    proveedor_id    INT                 NOT NULL,
    nombre          VARCHAR(150)        NOT NULL,
    descripcion     TEXT,
    precio_unitario DECIMAL(10,2)       NOT NULL CHECK (precio_unitario >= 0),
    stock_actual    INT                 NOT NULL DEFAULT 0,
    stock_minimo    INT                 NOT NULL DEFAULT 0,

    CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id)
        REFERENCES categoria (categoria_id) ON DELETE RESTRICT,
    CONSTRAINT fk_producto_proveedor FOREIGN KEY (proveedor_id)
        REFERENCES proveedor (proveedor_id) ON DELETE RESTRICT
);


-- 6. VENTA

CREATE TABLE venta (
    venta_id      SERIAL                      PRIMARY KEY,
    cliente_id    INT                         NOT NULL,
    empleado_id   INT                         NOT NULL,
    fecha_venta   TIMESTAMP                   NOT NULL DEFAULT NOW(),
    total         DECIMAL(12,2)               NOT NULL DEFAULT 0,
    estado        VARCHAR(20)                 NOT NULL DEFAULT 'pendiente',

    CONSTRAINT fk_venta_cliente  FOREIGN KEY (cliente_id)
        REFERENCES cliente (cliente_id) ON DELETE RESTRICT,
    CONSTRAINT fk_venta_empleado FOREIGN KEY (empleado_id)
        REFERENCES empleado (empleado_id) ON DELETE RESTRICT
);


-- 7. DETALLE_VENTA

CREATE TABLE detalle_venta (
    detalle_id      SERIAL          PRIMARY KEY,
    venta_id        INT             NOT NULL,
    producto_id     INT             NOT NULL,
    cantidad        INT             NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2)   NOT NULL CHECK (precio_unitario >= 0),
    subtotal        DECIMAL(12,2)   NOT NULL CHECK (subtotal >= 0),

    CONSTRAINT fk_detalle_venta    FOREIGN KEY (venta_id)
        REFERENCES venta (venta_id) ON DELETE RESTRICT,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (producto_id)
        REFERENCES producto (producto_id) ON DELETE RESTRICT
);


-- 8. MOVIMIENTO_INVENTARIO

CREATE TABLE movimiento_inventario (
    movimiento_id   SERIAL          PRIMARY KEY,
    producto_id     INT             NOT NULL,
    tipo            VARCHAR(20)     NOT NULL CHECK (tipo IN ('ENTRADA', 'SALIDA', 'AJUSTE')),
    cantidad        INT             NOT NULL CHECK (cantidad != 0),
    fecha           TIMESTAMP       NOT NULL DEFAULT NOW(),
    motivo          TEXT,

    CONSTRAINT fk_movimiento_producto FOREIGN KEY (producto_id)
        REFERENCES producto (producto_id) ON DELETE RESTRICT
);


-- INDICES

CREATE INDEX idx_producto_categoria  ON producto (categoria_id);
CREATE INDEX idx_producto_proveedor  ON producto (proveedor_id);
CREATE INDEX idx_venta_cliente       ON venta (cliente_id);
CREATE INDEX idx_venta_empleado      ON venta (empleado_id);
CREATE INDEX idx_venta_fecha         ON venta (fecha_venta);
CREATE INDEX idx_detalle_venta       ON detalle_venta (venta_id);
CREATE INDEX idx_detalle_producto    ON detalle_venta (producto_id);
CREATE INDEX idx_movimiento_producto ON movimiento_inventario (producto_id);