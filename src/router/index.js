import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '@/supabase'
import InicioView from '@/views/InicioView.vue'
import LoginView from '@/views/LoginView.vue'
import RegistroView from '@/views/RegistroView.vue'
import RecuperarView from '@/views/RecuperarView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/login',
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
    },
    {
      path: '/registro',
      name: 'registro',
      component: RegistroView,
    },
    {
      path: '/recuperar',
      name: 'recuperar',
      component: RecuperarView,
    },
    {
      path: '/inicio',
      name: 'inicio',
      component: InicioView,
      meta: {
        requiereAutenticacion: true,
      },
    },
  ],
})

router.beforeEach(async (destino) => {
  const {
    data: { session },
  } = await supabase.auth.getSession()

  if (destino.meta.requiereAutenticacion && !session) {
    return '/login'
  }

  if (
    session &&
    (destino.path === '/login' || destino.path === '/registro' || destino.path === '/recuperar')
  ) {
    return '/inicio'
  }
})

export default router