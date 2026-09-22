<script setup>
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/supabase'

const route = useRoute()
const router = useRouter()
const email = ref('')
const nuevaPassword = ref('')
const repetirPassword = ref('')
const cargando = ref(false)
const mensaje = ref('')
const exito = ref(false)

const modoCambio = computed(() => {
  return route.query.reset === 'true' || route.query.type === 'recovery' || Boolean(route.query.code)
})

async function enviarCorreoRecuperacion() {
  mensaje.value = ''
  exito.value = false

  if (!email.value.trim()) {
    mensaje.value = 'Ingresá tu correo electrónico.'
    return
  }

  try {
    cargando.value = true

    const { error } = await supabase.auth.resetPasswordForEmail(email.value.trim(), {
      redirectTo: `${window.location.origin}/recuperar?reset=true`,
    })

    if (error) {
      throw error
    }

    exito.value = true
    mensaje.value = 'Revisá tu correo para continuar con la recuperación de la contraseña.'
    email.value = ''
  } catch (error) {
    mensaje.value = error.message
  } finally {
    cargando.value = false
  }
}

async function actualizarPassword() {
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
    mensaje.value = 'La contraseña se actualizó correctamente.'
    nuevaPassword.value = ''
    repetirPassword.value = ''

    setTimeout(() => {
      router.push('/login')
    }, 1500)
  } catch (error) {
    mensaje.value = error.message
  } finally {
    cargando.value = false
  }
}
</script>

<template>
  <main class="pagina-recuperar">
    <section class="tarjeta-recuperar">
      <div class="encabezado">
        <span class="badge">Seguridad</span>
        <h1>{{ modoCambio ? 'Cambiar contraseña' : 'Recuperar contraseña' }}</h1>
      </div>

      <p class="descripcion">
        {{ modoCambio ? 'Ingresá tu nueva contraseña.' : 'Ingresá tu correo electrónico para recibir un enlace de recuperación.' }}
      </p>

      <form v-if="!modoCambio" @submit.prevent="enviarCorreoRecuperacion" class="formulario">
        <div class="campo">
          <label for="email">Correo electrónico</label>
          <input
            id="email"
            v-model="email"
            type="email"
            placeholder="nombre@correo.com"
            autocomplete="email"
            required
          />
        </div>

        <button type="submit" :disabled="cargando">
          {{ cargando ? 'Enviando...' : 'Enviar enlace' }}
        </button>
      </form>

      <form v-else @submit.prevent="actualizarPassword" class="formulario">
        <div class="campo">
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

        <div class="campo">
          <label for="repetirPassword">Repetir contraseña</label>
          <input
            id="repetirPassword"
            v-model="repetirPassword"
            type="password"
            placeholder="Volvé a escribir la contraseña"
            autocomplete="new-password"
            required
          />
        </div>

        <button type="submit" :disabled="cargando">
          {{ cargando ? 'Guardando...' : 'Guardar nueva contraseña' }}
        </button>
      </form>

      <p v-if="mensaje" class="mensaje" :class="{ exito, error: !exito }">
        {{ mensaje }}
      </p>

      <p class="enlace-login">
        <RouterLink to="/login">Volver al inicio de sesión</RouterLink>
      </p>
    </section>
  </main>
</template>