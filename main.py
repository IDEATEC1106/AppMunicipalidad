import threading
import requests
from kivy.app import App
from kivy.lang import Builder
from kivy.uix.screenmanager import Screen, ScreenManager
from kivy.clock import Clock
from kivy.uix.spinner import Spinner

# IMPORTACIONES CORRECTAS Y VERIFICADAS PARA KIVYMD 2.0
from kivymd.app import MDApp
from kivymd.uix.label import MDLabel
from kivymd.uix.button import MDButton, MDButtonText
from kivymd.uix.dialog import MDDialog, MDDialogHeadlineText, MDDialogSupportingText
from kivymd.uix.card import MDCard
from kivymd.uix.list import MDListItem, MDListItemHeadlineText, MDListItemSupportingText
from kivymd.uix.boxlayout import MDBoxLayout

# URL de tu API Backend intermedia (Servidor Flask/FastAPI que se comunica con tu SQL Server)
API_URL = "https://38.224.68.171:5001" # Cambiar por tu endpoint real en producción

KV = """
ScreenManager:
    LoginScreen:
    MenuScreen:
    DatosScreen:
    PredialScreen:
    ListaPrediosScreen:

<LoginScreen>:
    name: 'login'
    canvas.before:
        Color:
            rgba: 0.05, 0.25, 0.05, 1 
        Rectangle:
            pos: self.pos
            size: self.size

    MDBoxLayout:
        orientation: 'vertical'
        padding: "20dp"
        spacing: "15dp"

        MDLabel:
            text: "MUNICIPALIDAD DISTRITAL DE GUADALUPE"
            halign: "center"
            font_style: "Title"
            role: "large"
            theme_text_color: "Custom"
            text_color: 1, 1, 1, 1 
            bold: True
            size_hint_y: None
            height: "60dp"

        MDLabel:
            text: "Acceso al Contribuyente"
            halign: "center"
            font_style: "Body"
            role: "medium"
            theme_text_color: "Custom"
            text_color: 1, 0.8, 0, 1 
            size_hint_y: None
            height: "30dp"

        Widget:
            size_hint_y: None
            height: "40dp"

        MDTextField:
            id: user_input
            mode: "outlined"
            line_color_focus: 1, 0.8, 0, 1 
            text_color_normal: 1, 1, 1, 1
            text_color_focus: 1, 1, 1, 1
            MDTextFieldHintText:
                text: "Código de Contribuyente (ID_PREDIAL)"
                text_color_normal: 1, 1, 1, 0.7
                text_color_focus: 1, 0.8, 0, 1

        MDTextField:
            id: pass_input
            password: True
            mode: "outlined"
            line_color_focus: 1, 0.8, 0, 1 
            text_color_normal: 1, 1, 1, 1
            text_color_focus: 1, 1, 1, 1
            MDTextFieldHintText:
                text: "Clave de Acceso (RUC_LE)"
                text_color_normal: 1, 1, 1, 0.7
                text_color_focus: 1, 0.8, 0, 1

        Widget:
            size_hint_y: None
            height: "20dp"

        MDButton:
            style: "filled"
            md_bg_color: 1, 0.8, 0, 1 
            pos_hint: {"center_x": .5}
            size_hint_x: 0.8
            on_release: root.validar_y_conectar()
            MDButtonText:
                text: "CONECTAR E INGRESAR"
                text_color: 0.05, 0.25, 0.05, 1 
                bold: True
                pos_hint: {"center_x": .5, "center_y": .5}

        Widget:

<MenuScreen>:
    name: 'menu'
    canvas.before:
        Color:
            rgba: 0.05, 0.25, 0.05, 1 
        Rectangle:
            pos: self.pos
            size: self.size

    MDBoxLayout:
        orientation: 'vertical'
        padding: "20dp"
        spacing: "15dp"

        MDLabel:
            text: "MUNICIPALIDAD DISTRITAL DE GUADALUPE"
            halign: "center"
            font_style: "Title"
            role: "large"
            theme_text_color: "Custom"
            text_color: 1, 1, 1, 1 
            bold: True
            size_hint_y: None
            height: "50dp"

        MDLabel:
            text: "MENÚ PRINCIPAL"
            halign: "center"
            font_style: "Headline"
            role: "large"
            theme_text_color: "Custom"
            text_color: 1, 0.8, 0, 1 
            bold: True
            size_hint_y: None
            height: "40dp"

        Widget:
            size_hint_y: None
            height: "20dp"

        MDButton:
            style: "filled"
            md_bg_color: 1, 1, 1, 1 
            pos_hint: {"center_x": .5}
            size_hint_x: 0.9
            on_release: root.ir_a_datos_contribuyente()
            MDButtonText:
                text: "1. DATOS DEL CONTRIBUYENTE"
                text_color: 0.05, 0.25, 0.05, 1
                bold: True
                pos_hint: {"center_x": .5, "center_y": .5}

        MDButton:
            style: "filled"
            md_bg_color: 1, 1, 1, 1
            pos_hint: {"center_x": .5}
            size_hint_x: 0.9
            on_release: root.opcion_desarrollo("Estado de Pagos de Arbitrios")
            MDButtonText:
                text: "2. ESTADO DE PAGOS DE ARBITRIOS"
                text_color: 0.05, 0.25, 0.05, 1
                bold: True
                pos_hint: {"center_x": .5, "center_y": .5}

        MDButton:
            style: "filled"
            md_bg_color: 1, 1, 1, 1
            pos_hint: {"center_x": .5}
            size_hint_x: 0.9
            on_release: root.manager.current = 'predial_control'
            MDButtonText:
                text: "3. CONTROL PAGOS IMPUESTO PREDIAL"
                text_color: 0.05, 0.25, 0.05, 1
                bold: True
                pos_hint: {"center_x": .5, "center_y": .5}

        Widget:
            size_hint_y: None
            height: "30dp"

        MDButton:
            style: "filled"
            md_bg_color: 1, 0.8, 0, 1 
            pos_hint: {"center_x": .5}
            size_hint_x: 0.9
            on_release: root.salir()
            MDButtonText:
                text: "4. SALIR DEL SISTEMA"
                text_color: 0.05, 0.25, 0.05, 1
                bold: True
                pos_hint: {"center_x": .5, "center_y": .5}

        Widget:

<DatosScreen>:
    name: 'datos_contribuyente'
    on_enter: root.cargar_datos()
    canvas.before:
        Color:
            rgba: 0.05, 0.25, 0.05, 1 
        Rectangle:
            pos: self.pos
            size: self.size

    MDBoxLayout:
        orientation: 'vertical'
        padding: "20dp"
        spacing: "15dp"

        MDLabel:
            text: "DATOS DEL CONTRIBUYENTE"
            halign: "center"
            font_style: "Headline"
            role: "medium"
            theme_text_color: "Custom"
            text_color: 1, 0.8, 0, 1 
            bold: True
            size_hint_y: None
            height: "40dp"

        ScrollView:
            size_hint_y: 1
            MDBoxLayout:
                id: container_datos
                orientation: 'vertical'
                spacing: "12dp"
                size_hint_y: None
                height: self.minimum_height

        MDButton:
            style: "filled"
            md_bg_color: 1, 0.8, 0, 1 
            pos_hint: {"center_x": .5}
            size_hint_x: 0.9
            on_release: root.manager.current = 'menu'
            MDButtonText:
                text: "VOLVER AL MENÚ"
                text_color: 0.05, 0.25, 0.05, 1
                bold: True
                pos_hint: {"center_x": .5, "center_y": .5}

<PredialScreen>:
    name: 'predial_control'
    on_enter: root.cargar_cuentas()
    canvas.before:
        Color:
            rgba: 0.05, 0.25, 0.05, 1 
        Rectangle:
            pos: self.pos
            size: self.size

    MDBoxLayout:
        orientation: 'vertical'
        padding: "15dp"
        spacing: "10dp"

        MDLabel:
            text: "CONTROL PAGOS IMPUESTO PREDIAL"
            halign: "center"
            font_style: "Title"
            role: "medium"
            theme_text_color: "Custom"
            text_color: 1, 0.8, 0, 1 
            bold: True
            size_hint_y: None
            height: "40dp"

        MDTabsPrimary:
            id: tabs_predial
            pos_hint: {"center_x": .5}
            size_hint_y: None
            height: "48dp"
            on_tab_switch: root.cambiar_pestania(*args)

            MDTabsItem:
                MDTabsItemText:
                    text: "CUENTAS PENDIENTES"

            MDTabsItem:
                MDTabsItemText:
                    text: "CUENTAS PAGADAS"

        MDTabsCarousel:
            id: related_content
            size_hint_y: 1

            ScrollView:
                MDGridLayout:
                    id: grid_pendientes
                    cols: 1
                    spacing: "10dp"
                    padding: "10dp"
                    size_hint_y: None
                    height: self.minimum_height

            ScrollView:
                MDGridLayout:
                    id: grid_pagadas
                    cols: 1
                    spacing: "10dp"
                    padding: "10dp"
                    size_hint_y: None
                    height: self.minimum_height

        MDBoxLayout:
            orientation: 'horizontal'
            spacing: "15dp"
            size_hint_y: None
            height: "50dp"

            MDButton:
                style: "filled"
                md_bg_color: 1, 1, 1, 1
                size_hint_x: 0.5
                on_release: root.manager.current = 'lista_predios_screen'
                MDButtonText:
                    text: "PREDIOS REGISTRADOS"
                    text_color: 0.05, 0.25, 0.05, 1
                    bold: True

            MDButton:
                style: "filled"
                md_bg_color: 1, 0.8, 0, 1 
                size_hint_x: 0.5
                on_release: root.manager.current = 'menu'
                MDButtonText:
                    text: "VOLVER AL MENÚ"
                    text_color: 0.05, 0.25, 0.05, 1
                    bold: True
                    
<ListaPrediosScreen>:
    name: 'lista_predios_screen'
    canvas.before:
        Color:
            rgba: 0.05, 0.25, 0.05, 1 
        Rectangle:
            pos: self.pos
            size: self.size

    MDBoxLayout:
        orientation: 'vertical'
        padding: "20dp"
        spacing: "15dp"

        MDLabel:
            text: "RELACIÓN DE PREDIOS POR AÑO"
            halign: "center"
            font_style: "Title"
            role: "medium"
            theme_text_color: "Custom"
            text_color: 1, 0.8, 0, 1 
            bold: True
            size_hint_y: None
            height: "40dp"

        MDBoxLayout:
            orientation: 'horizontal'
            spacing: "10dp"
            size_hint_y: None
            height: "50dp"

            MDLabel:
                text: "Seleccione el Año:"
                theme_text_color: "Custom"
                text_color: 1, 1, 1, 1
                bold: True
                size_hint_x: 0.4
                halign: "left"

            Spinner:
                id: spinner_anios
                text: "Elegir Año"
                values: []
                size_hint_x: 0.6
                background_color: (0.08, 0.35, 0.2, 1)
                color: (1, 1, 1, 1)
                bold: True
                on_text: root.buscar_predios_por_anio(self.text)

        ScrollView:
            size_hint_y: 1
            MDBoxLayout:
                id: container_predios
                orientation: 'vertical'
                spacing: "12dp"
                size_hint_y: None
                height: self.minimum_height

        MDButton:
            style: "filled"
            md_bg_color: 1, 0.8, 0, 1 
            pos_hint: {"center_x": .5}
            size_hint_x: 1
            on_release: root.manager.current = 'predial_control'
            MDButtonText:
                text: "REGRESAR A PAGOS"
                text_color: 0.05, 0.25, 0.05, 1
                bold: True
                pos_hint: {"center_x": .5, "center_y": .5}
"""

class LoginScreen(Screen):
    def mostrar_alerta(self, titulo, mensaje):
        dialogo = MDDialog(
            MDDialogHeadlineText(text=titulo),
            MDDialogSupportingText(text=mensaje),
        )
        dialogo.open()

    def validar_y_conectar(self):
        usuario = self.ids.user_input.text.strip()
        clave = self.ids.pass_input.text.strip()

        if not usuario or not clave:
            self.mostrar_alerta("Campos Vacíos", "Por favor, ingrese su código y clave.")
            return

        # Ejecutamos la petición en segundo plano para no congelar la app
        threading.Thread(target=self._hacer_login_api, args=(usuario, clave), daemon=True).start()

    def _hacer_login_api(self, usuario, clave):
        try:
            response = requests.post(f"{API_URL}/api/login", json={"id_contri": usuario, "ruc_le": clave}, timeout=10)
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    Clock.schedule_once(lambda dt: self._exito_login(usuario))
                else:
                    Clock.schedule_once(lambda dt: self.mostrar_alerta("Acceso Denegado", "Datos incorrectos."))
            else:
                Clock.schedule_once(lambda dt: self.mostrar_alerta("Error", "Servidor no disponible temporalmente."))
        except Exception as e:
            Clock.schedule_once(lambda dt: self.mostrar_alerta("Error de Red", f"Verifique su conexión a internet: {str(e)}"))

    def _exito_login(self, usuario):
        MDApp.get_running_app().usuario_actual = usuario
        self.ids.user_input.text = ""
        self.ids.pass_input.text = ""
        self.manager.current = 'menu'

class MenuScreen(Screen):
    def ir_a_datos_contribuyente(self):
        self.manager.current = 'datos_contribuyente'

    def opcion_desarrollo(self, nombre_opcion):
        dialogo = MDDialog(
            MDDialogHeadlineText(text=nombre_opcion),
            MDDialogSupportingText(text="Módulo en desarrollo comercial o técnico."),
        )
        dialogo.open()

    def salir(self):
        MDApp.get_running_app().usuario_actual = None
        self.manager.current = 'login'

class DatosScreen(Screen):
    def cargar_datos(self):
        Clock.schedule_once(self._ejecutar_carga_datos, 0)

    def _ejecutar_carga_datos(self, dt):
        self.ids.container_datos.clear_widgets()
        usr_id = MDApp.get_running_app().usuario_actual
        if not usr_id: return
        threading.Thread(target=self._obtener_datos_api, args=(usr_id,), daemon=True).start()

    def _obtener_datos_api(self, usr_id):
        try:
            response = requests.get(f"{API_URL}/api/contribuyente/{usr_id}", timeout=10)
            if response.status_code == 200:
                datos = response.json().get("data", {})
                Clock.schedule_once(lambda dt: self._renderizar_datos(datos))
            else:
                Clock.schedule_once(lambda dt: self.mostrar_mensaje_vacio("No se pudo recuperar la información."))
        except Exception as e:
            Clock.schedule_once(lambda dt: self.mostrar_mensaje_vacio(f"Error de conexión: {str(e)}"))

    def _renderizar_datos(self, datos):
        for col_name, valor in datos.items():
            val_str = str(valor).strip() if valor is not None else "N/A"
            tarjeta = MDCard(
                orientation="vertical", size_hint_y=None, height="72dp", padding="4dp",
                style="filled", theme_bg_color="Custom", md_bg_color=(1, 1, 1, 0.1)
            )
            item_lista = MDListItem(
                MDListItemSupportingText(text=str(col_name).upper(), theme_text_color="Custom", text_color=(1, 0.8, 0, 1)),
                MDListItemHeadlineText(text=val_str, theme_text_color="Custom", text_color=(1, 1, 1, 1)),
                theme_bg_color="Custom", md_bg_color=(0, 0, 0, 0)
            )
            tarjeta.add_widget(item_lista)
            self.ids.container_datos.add_widget(tarjeta)

    def mostrar_mensaje_vacio(self, mensaje):
        tarjeta = MDCard(
            orientation="vertical", size_hint_y=None, height="80dp", padding="8dp",
            style="filled", theme_bg_color="Custom", md_bg_color=(1, 0.2, 0.2, 0.15)
        )
        item = MDListItem(
            MDListItemHeadlineText(text=mensaje, theme_text_color="Custom", text_color=(1, 1, 1, 1)),
            theme_bg_color="Custom", md_bg_color=(0, 0, 0, 0)
        )
        tarjeta.add_widget(item)
        self.ids.container_datos.add_widget(tarjeta)

class PredialScreen(Screen):
    def cargar_cuentas(self):
        Clock.schedule_once(self._ejecutar_carga_cuentas, 0)

    def _ejecutar_carga_cuentas(self, dt):
        usr_id = MDApp.get_running_app().usuario_actual
        if not usr_id: return
        self.ids.grid_pendientes.clear_widgets()
        self.ids.grid_pagadas.clear_widgets()
        threading.Thread(target=self._obtener_cuentas_api, args=(usr_id,), daemon=True).start()

    def cambiar_pestania(self, *args):
        try:
            tab_item_instance = args[1]
            texto_tab = ""
            for child in tab_item_instance.children:
                if hasattr(child, 'text'):
                    texto_tab = child.text
                    break
            if "PAGADAS" in texto_tab.upper():
                self.ids.related_content.load_slide(self.ids.related_content.slides[1])
            else:
                self.ids.related_content.load_slide(self.ids.related_content.slides[0])
        except Exception as e:
            print(f"Error al cambiar pestaña: {e}")

    def _obtener_cuentas_api(self, usr_id):
        try:
            response = requests.get(f"{API_URL}/api/predial/cuentas/{usr_id}", timeout=10)
            if response.status_code == 200:
                resultado = response.json()
                Clock.schedule_once(lambda dt: self._renderizar_cuentas(resultado))
        except Exception as e:
            print(f"Error de red en cuentas: {e}")

    def _renderizar_cuentas(self, data):
        # Renderiza las listas pendientes y pagadas recibidas en formato JSON desde la API
        pass

class ListaPrediosScreen(Screen):
    def on_kv_post(self, base_widget):
        self.ids.spinner_anios.values = [str(anio) for anio in range(2010, 2028)]

    def on_enter(self):
        if 'spinner_anios' in self.ids: self.ids.spinner_anios.text = "Elegir Año"
        if 'container_predios' in self.ids: self.ids.container_predios.clear_widgets()

    def buscar_predios_por_anio(self, anio):
        if not anio or anio == "Elegir Año": return
        usr_id = MDApp.get_running_app().usuario_actual
        if not usr_id: return
        self.ids.container_predios.clear_widgets()
        # Llamar a API por hilos...

class SistemaApp(MDApp):
    usuario_actual = None

    def build(self):
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Olive"
        return Builder.load_string(KV)

if __name__ == '__main__':
    SistemaApp().run()
