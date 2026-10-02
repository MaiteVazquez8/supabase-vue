<script setup>
import { onMounted, ref } from 'vue'
import { supabase } from '@/supabase'
const productos = ref([])
const nombre = ref('')
const descripcion = ref('')
const precio = ref('')
const stock = ref(0)
const activo = ref(true)
const archivoImagen = ref(null)
const vistaPrevia = ref('')
const imagenUrlExistente = ref('')
const imagenRutaExistente = ref('')
const inputImagen = ref(null)
const productoEditandoId = ref(null)
const cargando = ref(false)
const mensaje = ref('')
const errorMensaje = ref('')
async function cargarProductos(limpiarMensaje = true) {
cargando.value = true
errorMensaje.value = ''
if (limpiarMensaje) mensaje.value = ''

const { data, error } = await supabase
.from('productos')
.select('*')
.order('creado_en', { ascending: false })
if (error) {
errorMensaje.value = error.message
} else {
productos.value = data
}
cargando.value = false
}
function seleccionarImagen(evento) {
errorMensaje.value = ''
const archivo = evento.target.files?.[0]
if (!archivo) {
archivoImagen.value = null
vistaPrevia.value = ''
return
}
const tiposPermitidos = ['image/jpeg', 'image/png', 'image/webp']
if (!tiposPermitidos.includes(archivo.type)) {
errorMensaje.value = 'La imagen debe ser JPG, PNG o WEBP.'
evento.target.value = ''
return
}
if (archivo.size > 5 * 1024 * 1024) {
errorMensaje.value = 'La imagen no puede superar los 5 MB.'
evento.target.value = ''
return
}
if (vistaPrevia.value) URL.revokeObjectURL(vistaPrevia.value)
archivoImagen.value = archivo
vistaPrevia.value = URL.createObjectURL(archivo)
}
async function subirImagen() {
if (!archivoImagen.value) return null
const {
data: { user },
error: errorUsuario,
} = await supabase.auth.getUser()
if (errorUsuario || !user) {
throw new Error('No hay un usuario autenticado.')
}
const extension = archivoImagen.value.name.split('.').pop().toLowerCase()
const ruta = `${user.id}/${crypto.randomUUID()}.${extension}`
const { error: errorSubida } = await supabase.storage
.from('productos')
.upload(ruta, archivoImagen.value, {
cacheControl: '3600',
upsert: false,
})
if (errorSubida) throw errorSubida
const { data } = supabase.storage.from('productos').getPublicUrl(ruta)
return {
url: data.publicUrl,
ruta,
}

}
async function guardarProducto() {
errorMensaje.value = ''
mensaje.value = ''
if (!nombre.value.trim()) {
errorMensaje.value = 'El nombre es obligatorio.'
return
}
if (precio.value === '' || Number(precio.value) < 0) {
errorMensaje.value = 'Ingresá un precio válido.'
return
}
if (Number(stock.value) < 0) {
errorMensaje.value = 'El stock no puede ser negativo.'
return
}
if (!productoEditandoId.value && !archivoImagen.value) {
errorMensaje.value = 'Seleccioná una imagen para el producto.'
return
}
cargando.value = true
let nuevaImagen
try {
nuevaImagen = await subirImagen()
const datosProducto = {
nombre: nombre.value.trim(),
descripcion: descripcion.value.trim() || null,
precio: Number(precio.value),
stock: Number(stock.value),
activo: activo.value,
imagen_url: nuevaImagen?.url ?? imagenUrlExistente.value,
imagen_ruta: nuevaImagen?.ruta ?? imagenRutaExistente.value,
}
let error
if (productoEditandoId.value) {
;({ error } = await supabase
.from('productos')
.update(datosProducto)
.eq('id', productoEditandoId.value))
} else {
;({ error } = await supabase.from('productos').insert(datosProducto))
}
if (error) {
if (nuevaImagen?.ruta) {
await supabase.storage.from('productos').remove([nuevaImagen.ruta])
}
throw error
}
if (
productoEditandoId.value &&
nuevaImagen?.ruta &&
imagenRutaExistente.value
) {
await supabase.storage
.from('productos')
.remove([imagenRutaExistente.value])
}
mensaje.value = productoEditandoId.value
? 'Producto actualizado correctamente.'
: 'Producto creado correctamente.'
limpiarFormulario()
await cargarProductos(false)

} catch (error) {
errorMensaje.value = error.message
} finally {
cargando.value = false
}
}
function editarProducto(producto) {
productoEditandoId.value = producto.id
nombre.value = producto.nombre
descripcion.value = producto.descripcion ?? ''
precio.value = producto.precio
stock.value = producto.stock
activo.value = producto.activo
imagenUrlExistente.value = producto.imagen_url ?? ''
imagenRutaExistente.value = producto.imagen_ruta ?? ''
archivoImagen.value = null
vistaPrevia.value = ''
if (inputImagen.value) inputImagen.value.value = ''
window.scrollTo({ top: 0, behavior: 'smooth' })
}
async function eliminarProducto(producto) {
const confirmado = window.confirm(
`¿Querés eliminar el producto "${producto.nombre}"?`,
)
if (!confirmado) return
cargando.value = true
errorMensaje.value = ''
mensaje.value = ''
const { error } = await supabase
.from('productos')
.delete()
.eq('id', producto.id)
if (error) {
errorMensaje.value = error.message
cargando.value = false
return
}
if (producto.imagen_ruta) {
const { error: errorImagen } = await supabase.storage
.from('productos')
.remove([producto.imagen_ruta])
if (errorImagen) {
errorMensaje.value =
'El producto se eliminó, pero no se pudo borrar su imagen.'
}
}
if (!errorMensaje.value) mensaje.value = 'Producto eliminado correctamente.'
if (productoEditandoId.value === producto.id) limpiarFormulario()
await cargarProductos(false)
cargando.value = false
}
function limpiarFormulario() {
nombre.value = ''
descripcion.value = ''
precio.value = ''
stock.value = 0
activo.value = true
productoEditandoId.value = null
archivoImagen.value = null
imagenUrlExistente.value = ''
imagenRutaExistente.value = ''
if (vistaPrevia.value) URL.revokeObjectURL(vistaPrevia.value)
vistaPrevia.value = ''

if (inputImagen.value) inputImagen.value.value = ''
}
function cancelarEdicion() {
limpiarFormulario()
mensaje.value = ''
errorMensaje.value = ''
}
onMounted(cargarProductos)
</script>

<template>
<main class="pagina-productos">
<section class="panel formulario-panel">
<p class="etiqueta">Administración</p>
<h1>{{ productoEditandoId ? 'Editar producto' : 'Nuevo producto' }}</h1>
<p class="introduccion">
Completá los datos y guardá una imagen JPG, PNG o WEBP.
</p>
<form class="formulario" @submit.prevent="guardarProducto">
<label>
Nombre
<input v-model="nombre" type="text" maxlength="120" required />
</label>
<label>
Descripción
<textarea v-model="descripcion" rows="4"></textarea>
</label>
<div class="fila">
<label>
Precio
<input
v-model="precio"
type="number"
min="0"
step="0.01"
required
/>
</label>
<label>
Stock
<input v-model="stock" type="number" min="0" step="1" required />
</label>
</div>
<label>
Imagen del producto
<input
ref="inputImagen"
type="file"
accept="image/jpeg,image/png,image/webp"
@change="seleccionarImagen"
/>
<small>Máximo 5 MB.</small>
</label>
<div
v-if="vistaPrevia || imagenUrlExistente"
class="contenedor-vista-previa"
>
<img
:src="vistaPrevia || imagenUrlExistente"
alt="Vista previa del producto"
class="vista-previa"
/>
<span v-if="vistaPrevia">Nueva imagen seleccionada</span>
<span v-else>Imagen actual</span>

</div>
<label class="check">
<input v-model="activo" type="checkbox" />
Producto activo
</label>
<p v-if="errorMensaje" class="mensaje error">{{ errorMensaje }}</p>
<p v-if="mensaje" class="mensaje exito">{{ mensaje }}</p>
<div class="acciones-formulario">
<button type="submit" :disabled="cargando">
{{
cargando
? 'Guardando...'
: productoEditandoId
? 'Actualizar producto'
: 'Crear producto'
}}
</button>
<button
v-if="productoEditandoId"
type="button"
class="secundario"
@click="cancelarEdicion"
>
Cancelar
</button>
</div>
</form>
</section>
<section class="panel listado-panel">
<div class="cabecera-listado">
<div>
<p class="etiqueta">Inventario</p>
<h2>Mis productos</h2>
</div>
<button class="secundario" :disabled="cargando" @click="cargarProductos">
Actualizar
</button>
</div>
<p v-if="cargando && !productos.length">Cargando productos...</p>
<p v-else-if="!productos.length" class="vacio">
Todavía no creaste productos.
</p>
<div v-else class="tabla-contenedor">
<table>
<thead>
<tr>
<th>Imagen</th>
<th>Producto</th>
<th>Precio</th>
<th>Stock</th>
<th>Estado</th>
<th>Acciones</th>
</tr>
</thead>
<tbody>
<tr v-for="producto in productos" :key="producto.id">
<td>
<img
v-if="producto.imagen_url"
:src="producto.imagen_url"
:alt="producto.nombre"
class="miniatura"
/>
<span v-else class="sin-imagen">Sin imagen</span>
</td>
<td>
<strong>{{ producto.nombre }}</strong>
<small>{{ producto.descripcion || 'Sin descripción' }}</small>
</td>
<td>${{ Number(producto.precio).toFixed(2) }}</td>
<td>{{ producto.stock }}</td>
<td>

<span :class="['estado', producto.activo ? 'activo' : 'inactivo']">
{{ producto.activo ? 'Activo' : 'Inactivo' }}
</span>
</td>
<td>
<div class="acciones-tabla">
<button class="editar" @click="editarProducto(producto)">
Editar
</button>
<button class="eliminar" @click="eliminarProducto(producto)">
Eliminar
</button>
</div>
</td>
</tr>
</tbody>
</table>
</div>
</section>
</main>
</template>

<style scoped>
:global(body) {
  margin: 0;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: #f3f6fb;
  color: #0f172a;
}

.pagina-productos {
  min-height: 100vh;
  display: grid;
  grid-template-columns: minmax(320px, 420px) minmax(0, 1fr);
  gap: 24px;
  padding: 32px 20px;
  background: linear-gradient(135deg, #eef4ff 0%, #f8fafc 48%, #eefbf5 100%);
}

.panel {
  background: rgba(255, 255, 255, 0.82);
  border: 1px solid rgba(148, 163, 184, 0.2);
  border-radius: 22px;
  box-shadow: 0 18px 50px rgba(15, 23, 42, 0.08);
  backdrop-filter: blur(10px);
  padding: 26px;
}

.formulario-panel {
  align-self: start;
}

.etiqueta {
  margin: 0 0 10px;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  font-size: 0.72rem;
  font-weight: 700;
  color: #2563eb;
}

h1,
h2 {
  margin: 0;
  color: #0f172a;
}

h1 {
  font-size: clamp(1.9rem, 2vw, 2.4rem);
}

h2 {
  font-size: 1.6rem;
}

.introduccion {
  margin: 12px 0 22px;
  color: #475569;
  line-height: 1.5;
}

.formulario {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.formulario label {
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-weight: 600;
  color: #334155;
}

.fila {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

input,
textarea,
button {
  font: inherit;
}

input[type='text'],
input[type='number'],
textarea {
  width: 100%;
  box-sizing: border-box;
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  background: #f8fafc;
  color: #0f172a;
  padding: 0.8rem 0.95rem;
  transition: border-color 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
}

input[type='text']:focus,
input[type='number']:focus,
textarea:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.12);
  background: #fff;
}

textarea {
  resize: vertical;
  min-height: 110px;
}

input[type='file'] {
  padding: 0.7rem 0.6rem;
  border: 1px dashed #93c5fd;
  border-radius: 12px;
  background: #eff6ff;
  color: #1e3a8a;
}

small {
  color: #64748b;
  font-size: 0.76rem;
}

.check {
  flex-direction: row !important;
  align-items: center;
  gap: 10px !important;
  color: #334155;
}

.check input {
  width: 18px;
  height: 18px;
  accent-color: #2563eb;
}

.contenedor-vista-previa {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  border: 1px solid #dbeafe;
  border-radius: 16px;
  background: linear-gradient(135deg, #f8fbff 0%, #eef2ff 100%);
  color: #1d4ed8;
  font-size: 0.85rem;
  font-weight: 600;
}

.vista-previa {
  width: 100%;
  max-height: 220px;
  object-fit: cover;
  border-radius: 14px;
  border: 1px solid rgba(59, 130, 246, 0.12);
}

.acciones-formulario {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

button {
  border: none;
  border-radius: 12px;
  cursor: pointer;
  font-weight: 700;
  transition: transform 0.15s ease, box-shadow 0.2s ease, opacity 0.2s ease;
}

button:hover:not(:disabled) {
  transform: translateY(-1px);
}

button:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

button[type='submit'],
.acciones-tabla .editar {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  color: white;
  box-shadow: 0 12px 24px rgba(37, 99, 235, 0.2);
}

button[type='submit'] {
  min-width: 180px;
  padding: 0.9rem 1.2rem;
}

button.secundario,
.acciones-tabla .eliminar {
  background: #e2e8f0;
  color: #0f172a;
}

button.secundario {
  padding: 0.8rem 1.1rem;
}

.acciones-tabla .editar,
.acciones-tabla .eliminar {
  padding: 0.6rem 0.85rem;
  min-width: 76px;
}

.acciones-tabla .eliminar {
  background: #fee2e2;
  color: #b91c1c;
}

.mensaje {
  margin: 0;
  border-radius: 12px;
  padding: 0.8rem 0.95rem;
  font-size: 0.92rem;
  font-weight: 600;
}

.mensaje.error {
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #b91c1c;
}

.mensaje.exito {
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #166534;
}

.listado-panel {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.cabecera-listado {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.vacio {
  margin: 0;
  padding: 1.4rem;
  border-radius: 14px;
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  color: #475569;
  font-weight: 600;
}

.tabla-contenedor {
  overflow-x: auto;
  border-radius: 18px;
  border: 1px solid #e2e8f0;
}

table {
  width: 100%;
  border-collapse: collapse;
  background: white;
}

th,
td {
  padding: 14px 12px;
  border-bottom: 1px solid #e2e8f0;
  text-align: left;
  vertical-align: middle;
}

th {
  background: #f8fafc;
  color: #475569;
  font-size: 0.78rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.miniatura {
  width: 68px;
  height: 68px;
  object-fit: cover;
  border-radius: 12px;
  border: 1px solid rgba(148, 163, 184, 0.25);
  background: #f8fafc;
}

.sin-imagen {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 68px;
  height: 68px;
  border-radius: 12px;
  background: #f1f5f9;
  color: #64748b;
  font-size: 0.72rem;
  font-weight: 700;
  border: 1px dashed #cbd5e1;
}

td strong {
  display: block;
  margin-bottom: 4px;
  color: #0f172a;
}

td small {
  display: block;
  color: #64748b;
  line-height: 1.4;
}

.estado {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 82px;
  padding: 0.45rem 0.7rem;
  border-radius: 999px;
  font-size: 0.78rem;
  font-weight: 700;
}

.estado.activo {
  background: #dcfce7;
  color: #166534;
}

.estado.inactivo {
  background: #f1f5f9;
  color: #475569;
}

.acciones-tabla {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

@media (max-width: 980px) {
  .pagina-productos {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .pagina-productos {
    padding: 18px 14px 26px;
  }

  .panel {
    padding: 18px;
    border-radius: 18px;
  }

  .cabecera-listado,
  .fila,
  .acciones-formulario {
    grid-template-columns: 1fr;
    flex-direction: column;
    align-items: stretch;
  }

  .acciones-formulario button,
  .cabecera-listado button {
    width: 100%;
  }
}
</style>
