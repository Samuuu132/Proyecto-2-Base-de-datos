from sqlalchemy import Column, Integer, String, Text, Numeric, ForeignKey, TIMESTAMP
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class Categoria(Base):
    __tablename__ = "categoria"
    categoria_id  = Column(Integer, primary_key=True, index=True)
    nombre        = Column(String(100), nullable=False, unique=True)
    descripcion   = Column(Text)
    productos     = relationship("Producto", back_populates="categoria")

class Proveedor(Base):
    __tablename__ = "proveedor"
    proveedor_id  = Column(Integer, primary_key=True, index=True)
    nombre        = Column(String(150), nullable=False)
    telefono      = Column(String(20))
    email         = Column(String(150), unique=True)
    direccion     = Column(String(255))
    productos     = relationship("Producto", back_populates="proveedor")

class Producto(Base):
    __tablename__ = "producto"
    producto_id     = Column(Integer, primary_key=True, index=True)
    categoria_id    = Column(Integer, ForeignKey("categoria.categoria_id"), nullable=False)
    proveedor_id    = Column(Integer, ForeignKey("proveedor.proveedor_id"), nullable=False)
    nombre          = Column(String(150), nullable=False)
    descripcion     = Column(Text)
    precio_unitario = Column(Numeric(10, 2), nullable=False)
    stock_actual    = Column(Integer, default=0)
    stock_minimo    = Column(Integer, default=0)
    categoria       = relationship("Categoria", back_populates="productos")
    proveedor       = relationship("Proveedor", back_populates="productos")

class Cliente(Base):
    __tablename__ = "cliente"
    cliente_id  = Column(Integer, primary_key=True, index=True)
    nombre      = Column(String(100), nullable=False)
    apellido    = Column(String(100), nullable=False)
    email       = Column(String(150), unique=True)
    telefono    = Column(String(20))
    direccion   = Column(String(255))

class Empleado(Base):
    __tablename__ = "empleado"
    empleado_id   = Column(Integer, primary_key=True, index=True)
    nombre        = Column(String(100), nullable=False)
    apellido      = Column(String(100), nullable=False)
    cargo         = Column(String(80), nullable=False)
    email         = Column(String(150), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)
    rol           = Column(String(50), nullable=False, default="vendedor")

class Venta(Base):
    __tablename__ = "venta"
    venta_id    = Column(Integer, primary_key=True, index=True)
    cliente_id  = Column(Integer, ForeignKey("cliente.cliente_id"), nullable=False)
    empleado_id = Column(Integer, ForeignKey("empleado.empleado_id"), nullable=False)
    fecha_venta = Column(TIMESTAMP, server_default=func.now())
    total       = Column(Numeric(12, 2), default=0)
    estado      = Column(String(20), default="pendiente")