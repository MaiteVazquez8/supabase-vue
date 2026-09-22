<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/supabase'

const router = useRouter()
const nuevaPassword = ref('')
const repetirPassword = ref('')
const cargando = ref(false)
const mensaje = ref('')
const exito = ref(false)

async function cambiarPassword() {
  mensaje.value = ''
  exito.value = false

  if (nuevaPassword.value.length < 6) {
    mensaje.value = 'La contraseña debe tener al menos 6 caracteres.'
    return
  }

  if (nuevaPassword.value !== repetirPassword.value) {
    mensaje.value = 'Las contraseñas no coinciden.'
    return
  }

  try {
    cargando.value = true
    const { error } = await supabase.auth.updateUser({
      password: nuevaPassword.value,
    })

    if (error) {
      throw error
    }

    exito.value = true
    mensaje.value = 'Tu contraseña fue actualizada correctamente.'
    nuevaPassword.value = ''
    repetirPassword.value = ''

    setTimeout(() => {
      router.push('/inicio')
    }, 1200)
  } catch (error) {
    mensaje.value = error.message
  } finally {
    cargando.value = false
  }
}
</script>

<template>
  <main class="pagina-cambiar">
    <section class="tarjeta-cambiar">
      <h1>Cambiar contraseña</h1>
      <p>Ingresá tu nueva contraseña para continuar.</p>

      <form @submit.prevent="cambiarPassword">
        <div>
          <label for="nuevaPassword">Nueva contraseña</label>
          <input
            id="nuevaPassword"
            v-model="nuevaPassword"
            type="password"
            placeholder="Mínimo 6 caracteres"
            autocomplete="new-password"
            required
          />
        </div>

        <div>
          <label for="repetirPassword">Repetir contraseña</label>
          <input
            id="repetirPassword"
            v-model="repetirPassword"
            type="password"
            placeholder="Repetí la contraseña"
            autocomplete="new-password"
            required
          />
        </div>

        <button type="submit" :disabled="cargando">
          {{ cargando ? 'Guardando...' : 'Guardar contraseña' }}
        </button>
      </form>

      <p v-if="mensaje" :class="{ exito, error: !exito }">
        {{ mensaje }}
      </p>

      <p>
        <RouterLink to="/inicio">Volver al inicio</RouterLink>
      </p>
    </section>
  </main>
</template>
