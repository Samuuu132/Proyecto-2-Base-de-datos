from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from database import get_connection

app = FastAPI(title="Sistema de Inventario y Ventas")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# MODELOS (para recibir datos del frontend)

class Categoria(BaseModel):
    nombre: str
    descripcion: Optional[str] = None

class Proveedor(BaseModel):
    nombre: str
    telefono: Optional[str] = None
    email: Optional[str] = None
    direccion: Optional[str] = None

class Producto(BaseModel):
    categoria_id: int
    proveedor_id: int
    nombre: str
    descripcion: Optional[str] = None
    precio_unitario: float
    stock_actual: int = 0
    stock_minimo: int = 0

class Cliente(BaseModel):
    nombre: str
    apellido: str
    email: Optional[str] = None
    telefono: Optional[str] = None
    direccion: Optional[str] = None

class Venta(BaseModel):
    cliente_id: int
    empleado_id: int
    detalles: list


# CATEGORIAS - CRUD completo
@app.get("/categorias")
def get_categorias():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT categoria_id, nombre, descripcion FROM categoria ORDER BY nombre")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"categoria_id": r[0], "nombre": r[1], "descripcion": r[2]} for r in rows]

@app.post("/categorias")
def create_categoria(cat: Categoria):
    conn = get_connection()
    cur = conn.cursor()
    try:
        BEGIN = "BEGIN"
        cur.execute(BEGIN)
        cur.execute(
            "INSERT INTO categoria (nombre, descripcion) VALUES (%s, %s) RETURNING categoria_id",
            (cat.nombre, cat.descripcion)
        )
        new_id = cur.fetchone()[0]
        conn.commit()
        return {"message": "Categoría creada", "categoria_id": new_id}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()

@app.put("/categorias/{categoria_id}")
def update_categoria(categoria_id: int, cat: Categoria):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("BEGIN")
        cur.execute(
            "UPDATE categoria SET nombre=%s, descripcion=%s WHERE categoria_id=%s",
            (cat.nombre, cat.descripcion, categoria_id)
        )
        conn.commit()
        return {"message": "Categoría actualizada"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()

@app.delete("/categorias/{categoria_id}")
def delete_categoria(categoria_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("BEGIN")
        cur.execute("DELETE FROM categoria WHERE categoria_id=%s", (categoria_id,))
        conn.commit()
        return {"message": "Categoría eliminada"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()


# PRODUCTOS - CRUD completo

@app.get("/productos")
def get_productos():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT p.producto_id, p.nombre, p.precio_unitario, p.stock_actual,
               p.stock_minimo, c.nombre AS categoria, pr.nombre AS proveedor
        FROM producto p
        JOIN categoria c ON p.categoria_id = c.categoria_id
        JOIN proveedor pr ON p.proveedor_id = pr.proveedor_id
        ORDER BY p.nombre
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"producto_id": r[0], "nombre": r[1], "precio_unitario": float(r[2]),
             "stock_actual": r[3], "stock_minimo": r[4],
             "categoria": r[5], "proveedor": r[6]} for r in rows]

@app.post("/productos")
def create_producto(prod: Producto):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("BEGIN")
        cur.execute("""
            INSERT INTO producto (categoria_id, proveedor_id, nombre, descripcion,
                                  precio_unitario, stock_actual, stock_minimo)
            VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING producto_id
        """, (prod.categoria_id, prod.proveedor_id, prod.nombre, prod.descripcion,
              prod.precio_unitario, prod.stock_actual, prod.stock_minimo))
        new_id = cur.fetchone()[0]
        conn.commit()
        return {"message": "Producto creado", "producto_id": new_id}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()

@app.put("/productos/{producto_id}")
def update_producto(producto_id: int, prod: Producto):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("BEGIN")
        cur.execute("""
            UPDATE producto SET categoria_id=%s, proveedor_id=%s, nombre=%s,
            descripcion=%s, precio_unitario=%s, stock_actual=%s, stock_minimo=%s
            WHERE producto_id=%s
        """, (prod.categoria_id, prod.proveedor_id, prod.nombre, prod.descripcion,
              prod.precio_unitario, prod.stock_actual, prod.stock_minimo, producto_id))
        conn.commit()
        return {"message": "Producto actualizado"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()

@app.delete("/productos/{producto_id}")
def delete_producto(producto_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("BEGIN")
        cur.execute("DELETE FROM producto WHERE producto_id=%s", (producto_id,))
        conn.commit()
        return {"message": "Producto eliminado"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()


# CLIENTES - CRUD completo

@app.get("/clientes")
def get_clientes():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT cliente_id, nombre, apellido, email, telefono
        FROM cliente ORDER BY apellido, nombre
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"cliente_id": r[0], "nombre": r[1], "apellido": r[2],
             "email": r[3], "telefono": r[4]} for r in rows]

@app.post("/clientes")
def create_cliente(cli: Cliente):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("BEGIN")
        cur.execute("""
            INSERT INTO cliente (nombre, apellido, email, telefono, direccion)
            VALUES (%s, %s, %s, %s, %s) RETURNING cliente_id
        """, (cli.nombre, cli.apellido, cli.email, cli.telefono, cli.direccion))
        new_id = cur.fetchone()[0]
        conn.commit()
        return {"message": "Cliente creado", "cliente_id": new_id}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()

@app.put("/clientes/{cliente_id}")
def update_cliente(cliente_id: int, cli: Cliente):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("BEGIN")
        cur.execute("""
            UPDATE cliente SET nombre=%s, apellido=%s, email=%s,
            telefono=%s, direccion=%s WHERE cliente_id=%s
        """, (cli.nombre, cli.apellido, cli.email,
              cli.telefono, cli.direccion, cliente_id))
        conn.commit()
        return {"message": "Cliente actualizado"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()

@app.delete("/clientes/{cliente_id}")
def delete_cliente(cliente_id: int):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("BEGIN")
        cur.execute("DELETE FROM cliente WHERE cliente_id=%s", (cliente_id,))
        conn.commit()
        return {"message": "Cliente eliminado"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()


# VENTAS - con transacción explícita y ROLLBACK

@app.get("/ventas")
def get_ventas():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT v.venta_id, v.fecha_venta, v.total, v.estado,
               c.nombre || ' ' || c.apellido AS cliente,
               e.nombre || ' ' || e.apellido AS empleado
        FROM venta v
        JOIN cliente c ON v.cliente_id = c.cliente_id
        JOIN empleado e ON v.empleado_id = e.empleado_id
        ORDER BY v.fecha_venta DESC
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"venta_id": r[0], "fecha_venta": str(r[1]), "total": float(r[2]),
             "estado": r[3], "cliente": r[4], "empleado": r[5]} for r in rows]

@app.post("/ventas")
def create_venta(venta: Venta):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("BEGIN")

        # Verificar stock disponible antes de insertar
        for detalle in venta.detalles:
            cur.execute("SELECT stock_actual FROM producto WHERE producto_id=%s",
                        (detalle["producto_id"],))
            row = cur.fetchone()
            if not row:
                raise Exception(f"Producto {detalle['producto_id']} no existe")
            if row[0] < detalle["cantidad"]:
                raise Exception(f"Stock insuficiente para producto {detalle['producto_id']}")

        # Calcular total
        total = sum(d["cantidad"] * d["precio_unitario"] for d in venta.detalles)

        # Insertar venta
        cur.execute("""
            INSERT INTO venta (cliente_id, empleado_id, total, estado)
            VALUES (%s, %s, %s, 'completada') RETURNING venta_id
        """, (venta.cliente_id, venta.empleado_id, total))
        venta_id = cur.fetchone()[0]

        # Insertar detalles y actualizar stock
        for detalle in venta.detalles:
            subtotal = detalle["cantidad"] * detalle["precio_unitario"]
            cur.execute("""
                INSERT INTO detalle_venta (venta_id, producto_id, cantidad, precio_unitario, subtotal)
                VALUES (%s, %s, %s, %s, %s)
            """, (venta_id, detalle["producto_id"], detalle["cantidad"],
                  detalle["precio_unitario"], subtotal))

            # Actualizar stock
            cur.execute("""
                UPDATE producto SET stock_actual = stock_actual - %s
                WHERE producto_id = %s
            """, (detalle["cantidad"], detalle["producto_id"]))

            # Registrar movimiento de inventario
            cur.execute("""
                INSERT INTO movimiento_inventario (producto_id, tipo, cantidad, motivo)
                VALUES (%s, 'SALIDA', %s, %s)
            """, (detalle["producto_id"], -detalle["cantidad"], f"Venta #{venta_id}"))

        conn.commit()
        return {"message": "Venta registrada", "venta_id": venta_id, "total": total}

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()


# REPORTES - consultas avanzadas visibles en la UI
# JOIN: productos con su categoria y proveedor
@app.get("/reportes/productos-detalle")
def reporte_productos_detalle():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT p.nombre, p.precio_unitario, p.stock_actual,
               c.nombre AS categoria, pr.nombre AS proveedor
        FROM producto p
        JOIN categoria c ON p.categoria_id = c.categoria_id
        JOIN proveedor pr ON p.proveedor_id = pr.proveedor_id
        ORDER BY c.nombre, p.nombre
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"producto": r[0], "precio": float(r[1]), "stock": r[2],
             "categoria": r[3], "proveedor": r[4]} for r in rows]

# GROUP BY + HAVING: ventas por cliente con total mayor a 1000
@app.get("/reportes/ventas-por-cliente")
def reporte_ventas_por_cliente():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT c.nombre || ' ' || c.apellido AS cliente,
               COUNT(v.venta_id) AS total_ventas,
               SUM(v.total) AS monto_total
        FROM venta v
        JOIN cliente c ON v.cliente_id = c.cliente_id
        GROUP BY c.cliente_id, c.nombre, c.apellido
        HAVING SUM(v.total) > 1000
        ORDER BY monto_total DESC
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"cliente": r[0], "total_ventas": r[1], "monto_total": float(r[2])} for r in rows]

# CTE: productos con stock bajo el mínimo
@app.get("/reportes/stock-bajo")
def reporte_stock_bajo():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        WITH productos_criticos AS (
            SELECT p.producto_id, p.nombre, p.stock_actual, p.stock_minimo,
                   p.stock_minimo - p.stock_actual AS unidades_faltantes,
                   c.nombre AS categoria
            FROM producto p
            JOIN categoria c ON p.categoria_id = c.categoria_id
            WHERE p.stock_actual <= p.stock_minimo
        )
        SELECT * FROM productos_criticos
        ORDER BY unidades_faltantes DESC
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"producto_id": r[0], "nombre": r[1], "stock_actual": r[2],
             "stock_minimo": r[3], "unidades_faltantes": r[4],
             "categoria": r[5]} for r in rows]

# Subquery: clientes que han comprado productos de electronica
@app.get("/reportes/clientes-electronica")
def reporte_clientes_electronica():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT DISTINCT c.nombre || ' ' || c.apellido AS cliente, c.email
        FROM cliente c
        WHERE c.cliente_id IN (
            SELECT v.cliente_id
            FROM venta v
            JOIN detalle_venta dv ON v.venta_id = dv.venta_id
            JOIN producto p ON dv.producto_id = p.producto_id
            JOIN categoria cat ON p.categoria_id = cat.categoria_id
            WHERE cat.nombre = 'Electrónica'
        )
        ORDER BY cliente
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"cliente": r[0], "email": r[1]} for r in rows]


# PROVEEDORES - GET

@app.get("/proveedores")
def get_proveedores():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT proveedor_id, nombre FROM proveedor ORDER BY nombre")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"proveedor_id": r[0], "nombre": r[1]} for r in rows]


# EMPLEADOS - GET

@app.get("/empleados")
def get_empleados():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT empleado_id, nombre, apellido FROM empleado ORDER BY apellido")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"empleado_id": r[0], "nombre": r[1], "apellido": r[2]} for r in rows]


# VIEW — vista_resumen_ventas utilizada por el backend

@app.get("/reportes/resumen-ventas")
def reporte_resumen_ventas():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT venta_id, fecha_venta, total, estado,
               cliente, cliente_email, empleado,
               empleado_cargo, cantidad_productos
        FROM vista_resumen_ventas
        ORDER BY fecha_venta DESC
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"venta_id": r[0], "fecha_venta": str(r[1]),
             "total": float(r[2]), "estado": r[3],
             "cliente": r[4], "cliente_email": r[5],
             "empleado": r[6], "empleado_cargo": r[7],
             "cantidad_productos": r[8]} for r in rows]


# SUBQUERY 2 — productos que nunca han sido vendidos 

@app.get("/reportes/productos-sin-ventas")
def reporte_productos_sin_ventas():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT p.nombre, p.precio_unitario, p.stock_actual,
               c.nombre AS categoria
        FROM producto p
        JOIN categoria c ON p.categoria_id = c.categoria_id
        WHERE NOT EXISTS (
            SELECT 1
            FROM detalle_venta dv
            WHERE dv.producto_id = p.producto_id
        )
        ORDER BY p.nombre
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"nombre": r[0], "precio_unitario": float(r[1]),
             "stock_actual": r[2], "categoria": r[3]} for r in rows]