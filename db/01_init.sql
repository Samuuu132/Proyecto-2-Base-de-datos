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

-- Views
CREATE OR REPLACE VIEW vista_resumen_ventas AS
SELECT
    v.venta_id,
    v.fecha_venta,
    v.total,
    v.estado,
    c.nombre || ' ' || c.apellido AS cliente,
    c.email AS cliente_email,
    e.nombre || ' ' || e.apellido AS empleado,
    e.cargo AS empleado_cargo,
    COUNT(dv.detalle_id) AS cantidad_productos
FROM venta v
JOIN cliente c ON v.cliente_id = c.cliente_id
JOIN empleado e ON v.empleado_id = e.empleado_id
JOIN detalle_venta dv ON v.venta_id = dv.venta_id
GROUP BY v.venta_id, v.fecha_venta, v.total, v.estado,
         c.nombre, c.apellido, c.email,
         e.nombre, e.apellido, e.cargo;

CREATE INDEX idx_venta_estado ON venta (estado);

-- ============================================================
-- ROLES Y PERMISOS
-- ============================================================

-- Crear los 5 roles
CREATE ROLE rol_gerente;
CREATE ROLE rol_supervisor;
CREATE ROLE rol_vendedor;
CREATE ROLE rol_cajero;
CREATE ROLE rol_bodeguero;

-- ── ROL GERENTE ──────────────────────────────────────────
-- Acceso total a todas las tablas
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_gerente;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_gerente;

-- ── ROL SUPERVISOR ───────────────────────────────────────
-- Puede ver y modificar todo excepto eliminar ventas o empleados
GRANT SELECT, INSERT, UPDATE ON producto TO rol_supervisor;
GRANT SELECT, INSERT, UPDATE ON categoria TO rol_supervisor;
GRANT SELECT, INSERT, UPDATE ON proveedor TO rol_supervisor;
GRANT SELECT, INSERT, UPDATE ON cliente TO rol_supervisor;
GRANT SELECT ON venta TO rol_supervisor;
GRANT SELECT ON detalle_venta TO rol_supervisor;
GRANT SELECT ON empleado TO rol_supervisor;
GRANT SELECT ON movimiento_inventario TO rol_supervisor;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rol_supervisor;

-- ── ROL VENDEDOR ─────────────────────────────────────────
-- Puede ver productos y clientes, registrar ventas
GRANT SELECT ON producto TO rol_vendedor;
GRANT SELECT ON categoria TO rol_vendedor;
GRANT SELECT ON proveedor TO rol_vendedor;
GRANT SELECT, INSERT, UPDATE ON cliente TO rol_vendedor;
GRANT SELECT, INSERT ON venta TO rol_vendedor;
GRANT SELECT, INSERT ON detalle_venta TO rol_vendedor;
GRANT SELECT ON empleado TO rol_vendedor;
GRANT INSERT ON movimiento_inventario TO rol_vendedor;
GRANT UPDATE (stock_actual) ON producto TO rol_vendedor;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rol_vendedor;

-- ── ROL CAJERO ───────────────────────────────────────────
-- Solo puede ver ventas y clientes, no modifica inventario
GRANT SELECT ON venta TO rol_cajero;
GRANT SELECT ON detalle_venta TO rol_cajero;
GRANT SELECT ON cliente TO rol_cajero;
GRANT SELECT ON producto TO rol_cajero;
GRANT SELECT ON categoria TO rol_cajero;
GRANT SELECT ON empleado TO rol_cajero;

-- ── ROL BODEGUERO ────────────────────────────────────────
-- Solo maneja inventario, no ve ventas ni clientes
GRANT SELECT, INSERT, UPDATE ON producto TO rol_bodeguero;
GRANT SELECT ON categoria TO rol_bodeguero;
GRANT SELECT ON proveedor TO rol_bodeguero;
GRANT SELECT, INSERT ON movimiento_inventario TO rol_bodeguero;
GRANT UPDATE (stock_actual) ON producto TO rol_bodeguero;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rol_bodeguero;
REVOKE SELECT ON cliente FROM rol_bodeguero;
REVOKE SELECT ON venta FROM rol_bodeguero;
REVOKE SELECT ON detalle_venta FROM rol_bodeguero;

-- ── Asignar roles al usuario proy3 ───────────────────────
GRANT rol_gerente TO proy3;
GRANT rol_supervisor TO proy3;
GRANT rol_vendedor TO proy3;
GRANT rol_cajero TO proy3;
GRANT rol_bodeguero TO proy3;