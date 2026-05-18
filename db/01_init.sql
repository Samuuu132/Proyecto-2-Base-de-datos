-- ============================================================
-- PROYECTO 3 - Sistema de Inventario y Ventas
-- CC3088 Bases de Datos 1 - Universidad del Valle de Guatemala
-- DDL Completo - PostgreSQL
-- ============================================================

CREATE TABLE categoria (
    categoria_id  SERIAL          PRIMARY KEY,
    nombre        VARCHAR(100)    NOT NULL UNIQUE,
    descripcion   TEXT
);

CREATE TABLE proveedor (
    proveedor_id  SERIAL          PRIMARY KEY,
    nombre        VARCHAR(150)    NOT NULL,
    telefono      VARCHAR(20),
    email         VARCHAR(150)    UNIQUE,
    direccion     VARCHAR(255)
);

CREATE TABLE cliente (
    cliente_id    SERIAL          PRIMARY KEY,
    nombre        VARCHAR(100)    NOT NULL,
    apellido      VARCHAR(100)    NOT NULL,
    email         VARCHAR(150)    UNIQUE,
    telefono      VARCHAR(20),
    direccion     VARCHAR(255)
);

CREATE TABLE empleado (
    empleado_id   SERIAL          PRIMARY KEY,
    nombre        VARCHAR(100)    NOT NULL,
    apellido      VARCHAR(100)    NOT NULL,
    cargo         VARCHAR(80)     NOT NULL,
    email         VARCHAR(150)    NOT NULL UNIQUE,
    password_hash VARCHAR(255)    NOT NULL,
    rol           VARCHAR(50)     NOT NULL DEFAULT 'vendedor'
);

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

-- ============================================================
-- INDICES
-- ============================================================
CREATE INDEX idx_producto_categoria  ON producto (categoria_id);
CREATE INDEX idx_producto_proveedor  ON producto (proveedor_id);
CREATE INDEX idx_venta_cliente       ON venta (cliente_id);
CREATE INDEX idx_venta_empleado      ON venta (empleado_id);
CREATE INDEX idx_venta_fecha         ON venta (fecha_venta);
CREATE INDEX idx_venta_estado        ON venta (estado);
CREATE INDEX idx_detalle_venta       ON detalle_venta (venta_id);
CREATE INDEX idx_detalle_producto    ON detalle_venta (producto_id);
CREATE INDEX idx_movimiento_producto ON movimiento_inventario (producto_id);

-- ============================================================
-- VIEWS
-- ============================================================
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

-- ============================================================
-- ROLES Y PERMISOS
-- ============================================================
CREATE ROLE rol_gerente;
CREATE ROLE rol_supervisor;
CREATE ROLE rol_vendedor;
CREATE ROLE rol_cajero;
CREATE ROLE rol_bodeguero;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_gerente;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_gerente;

GRANT SELECT, INSERT, UPDATE ON producto TO rol_supervisor;
GRANT SELECT, INSERT, UPDATE ON categoria TO rol_supervisor;
GRANT SELECT, INSERT, UPDATE ON proveedor TO rol_supervisor;
GRANT SELECT, INSERT, UPDATE ON cliente TO rol_supervisor;
GRANT SELECT ON venta TO rol_supervisor;
GRANT SELECT ON detalle_venta TO rol_supervisor;
GRANT SELECT ON empleado TO rol_supervisor;
GRANT SELECT ON movimiento_inventario TO rol_supervisor;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rol_supervisor;

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

GRANT SELECT ON venta TO rol_cajero;
GRANT SELECT ON detalle_venta TO rol_cajero;
GRANT SELECT ON cliente TO rol_cajero;
GRANT SELECT ON producto TO rol_cajero;
GRANT SELECT ON categoria TO rol_cajero;
GRANT SELECT ON empleado TO rol_cajero;

GRANT SELECT, INSERT, UPDATE ON producto TO rol_bodeguero;
GRANT SELECT ON categoria TO rol_bodeguero;
GRANT SELECT ON proveedor TO rol_bodeguero;
GRANT SELECT, INSERT ON movimiento_inventario TO rol_bodeguero;
GRANT UPDATE (stock_actual) ON producto TO rol_bodeguero;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rol_bodeguero;
REVOKE SELECT ON cliente FROM rol_bodeguero;
REVOKE SELECT ON venta FROM rol_bodeguero;
REVOKE SELECT ON detalle_venta FROM rol_bodeguero;

GRANT rol_gerente    TO proy3;
GRANT rol_supervisor TO proy3;
GRANT rol_vendedor   TO proy3;
GRANT rol_cajero     TO proy3;
GRANT rol_bodeguero  TO proy3;

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

CREATE OR REPLACE PROCEDURE sp_registrar_venta(
    p_cliente_id    INT,
    p_empleado_id   INT,
    p_detalles      JSON,
    OUT p_venta_id  INT,
    OUT p_mensaje   TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total         DECIMAL(12,2) := 0;
    v_detalle       JSON;
    v_producto_id   INT;
    v_cantidad      INT;
    v_precio        DECIMAL(10,2);
    v_subtotal      DECIMAL(12,2);
    v_stock         INT;
    i               INT;
BEGIN
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM cliente WHERE cliente_id = p_cliente_id) THEN
            RAISE EXCEPTION 'Cliente % no existe', p_cliente_id;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM empleado WHERE empleado_id = p_empleado_id) THEN
            RAISE EXCEPTION 'Empleado % no existe', p_empleado_id;
        END IF;
        FOR i IN 0..json_array_length(p_detalles) - 1 LOOP
            v_detalle     := p_detalles->i;
            v_producto_id := (v_detalle->>'producto_id')::INT;
            v_cantidad    := (v_detalle->>'cantidad')::INT;
            SELECT stock_actual INTO v_stock
            FROM producto WHERE producto_id = v_producto_id;
            IF v_stock IS NULL THEN
                RAISE EXCEPTION 'Producto % no existe', v_producto_id;
            END IF;
            IF v_stock < v_cantidad THEN
                RAISE EXCEPTION 'Stock insuficiente para producto %', v_producto_id;
            END IF;
            SELECT precio_unitario INTO v_precio
            FROM producto WHERE producto_id = v_producto_id;
            v_subtotal := v_cantidad * v_precio;
            v_total    := v_total + v_subtotal;
        END LOOP;
        INSERT INTO venta (cliente_id, empleado_id, total, estado)
        VALUES (p_cliente_id, p_empleado_id, v_total, 'completada')
        RETURNING venta_id INTO p_venta_id;
        FOR i IN 0..json_array_length(p_detalles) - 1 LOOP
            v_detalle     := p_detalles->i;
            v_producto_id := (v_detalle->>'producto_id')::INT;
            v_cantidad    := (v_detalle->>'cantidad')::INT;
            SELECT precio_unitario INTO v_precio
            FROM producto WHERE producto_id = v_producto_id;
            v_subtotal := v_cantidad * v_precio;
            INSERT INTO detalle_venta (venta_id, producto_id, cantidad, precio_unitario, subtotal)
            VALUES (p_venta_id, v_producto_id, v_cantidad, v_precio, v_subtotal);
            UPDATE producto SET stock_actual = stock_actual - v_cantidad
            WHERE producto_id = v_producto_id;
            INSERT INTO movimiento_inventario (producto_id, tipo, cantidad, motivo)
            VALUES (v_producto_id, 'SALIDA', -v_cantidad, 'Venta #' || p_venta_id);
        END LOOP;
        p_mensaje := 'Venta registrada exitosamente';
    EXCEPTION
        WHEN OTHERS THEN
            p_venta_id := -1;
            p_mensaje  := SQLERRM;
            RAISE;
    END;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_crear_producto(
    p_categoria_id      INT,
    p_proveedor_id      INT,
    p_nombre            VARCHAR(150),
    p_descripcion       TEXT,
    p_precio_unitario   DECIMAL(10,2),
    p_stock_actual      INT,
    p_stock_minimo      INT,
    OUT p_producto_id   INT,
    OUT p_mensaje       TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_precio_unitario < 0 THEN
        RAISE EXCEPTION 'El precio no puede ser negativo';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM categoria WHERE categoria_id = p_categoria_id) THEN
        RAISE EXCEPTION 'Categoría % no existe', p_categoria_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM proveedor WHERE proveedor_id = p_proveedor_id) THEN
        RAISE EXCEPTION 'Proveedor % no existe', p_proveedor_id;
    END IF;
    INSERT INTO producto (categoria_id, proveedor_id, nombre, descripcion,
                          precio_unitario, stock_actual, stock_minimo)
    VALUES (p_categoria_id, p_proveedor_id, p_nombre, p_descripcion,
            p_precio_unitario, p_stock_actual, p_stock_minimo)
    RETURNING producto_id INTO p_producto_id;
    p_mensaje := 'Producto creado exitosamente';
EXCEPTION
    WHEN OTHERS THEN
        p_producto_id := -1;
        p_mensaje     := SQLERRM;
        RAISE;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_actualizar_stock(
    p_producto_id   INT,
    p_tipo          VARCHAR(20),
    p_cantidad      INT,
    p_motivo        TEXT,
    OUT p_mensaje   TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock_actual INT;
BEGIN
    SELECT stock_actual INTO v_stock_actual
    FROM producto WHERE producto_id = p_producto_id;
    IF v_stock_actual IS NULL THEN
        RAISE EXCEPTION 'Producto % no existe', p_producto_id;
    END IF;
    IF p_tipo NOT IN ('ENTRADA', 'SALIDA', 'AJUSTE') THEN
        RAISE EXCEPTION 'Tipo de movimiento inválido: %', p_tipo;
    END IF;
    IF p_tipo = 'SALIDA' AND v_stock_actual < p_cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente. Stock actual: %', v_stock_actual;
    END IF;
    IF p_tipo = 'ENTRADA' THEN
        UPDATE producto SET stock_actual = stock_actual + p_cantidad
        WHERE producto_id = p_producto_id;
    ELSIF p_tipo = 'SALIDA' THEN
        UPDATE producto SET stock_actual = stock_actual - p_cantidad
        WHERE producto_id = p_producto_id;
    ELSE
        UPDATE producto SET stock_actual = p_cantidad
        WHERE producto_id = p_producto_id;
    END IF;
    INSERT INTO movimiento_inventario (producto_id, tipo, cantidad, motivo)
    VALUES (p_producto_id, p_tipo,
            CASE WHEN p_tipo = 'SALIDA' THEN -p_cantidad ELSE p_cantidad END,
            p_motivo);
    p_mensaje := 'Stock actualizado exitosamente';
EXCEPTION
    WHEN OTHERS THEN
        p_mensaje := SQLERRM;
        RAISE;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_crear_cliente(
    p_nombre         VARCHAR(100),
    p_apellido       VARCHAR(100),
    p_email          VARCHAR(150),
    p_telefono       VARCHAR(20),
    p_direccion      VARCHAR(255),
    OUT p_cliente_id INT,
    OUT p_mensaje    TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_nombre IS NULL OR p_nombre = '' THEN
        RAISE EXCEPTION 'El nombre es obligatorio';
    END IF;
    IF p_apellido IS NULL OR p_apellido = '' THEN
        RAISE EXCEPTION 'El apellido es obligatorio';
    END IF;
    IF EXISTS (SELECT 1 FROM cliente WHERE email = p_email AND p_email IS NOT NULL) THEN
        RAISE EXCEPTION 'Ya existe un cliente con el email %', p_email;
    END IF;
    INSERT INTO cliente (nombre, apellido, email, telefono, direccion)
    VALUES (p_nombre, p_apellido, p_email, p_telefono, p_direccion)
    RETURNING cliente_id INTO p_cliente_id;
    p_mensaje := 'Cliente creado exitosamente';
EXCEPTION
    WHEN OTHERS THEN
        p_cliente_id := -1;
        p_mensaje    := SQLERRM;
        RAISE;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_anular_venta(
    p_venta_id    INT,
    p_motivo      TEXT,
    OUT p_mensaje TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado      VARCHAR(20);
    v_producto_id INT;
    v_cantidad    INT;
BEGIN
    BEGIN
        SELECT estado INTO v_estado
        FROM venta WHERE venta_id = p_venta_id;
        IF v_estado IS NULL THEN
            RAISE EXCEPTION 'Venta % no existe', p_venta_id;
        END IF;
        IF v_estado = 'anulada' THEN
            RAISE EXCEPTION 'La venta % ya está anulada', p_venta_id;
        END IF;
        FOR v_producto_id, v_cantidad IN
            SELECT producto_id, cantidad
            FROM detalle_venta WHERE venta_id = p_venta_id
        LOOP
            UPDATE producto SET stock_actual = stock_actual + v_cantidad
            WHERE producto_id = v_producto_id;
            INSERT INTO movimiento_inventario (producto_id, tipo, cantidad, motivo)
            VALUES (v_producto_id, 'ENTRADA', v_cantidad,
                    'Devolución por anulación venta #' || p_venta_id || ': ' || p_motivo);
        END LOOP;
        UPDATE venta SET estado = 'anulada' WHERE venta_id = p_venta_id;
        p_mensaje := 'Venta anulada exitosamente';
    EXCEPTION
        WHEN OTHERS THEN
            p_mensaje := SQLERRM;
            RAISE;
    END;
END;
$$;