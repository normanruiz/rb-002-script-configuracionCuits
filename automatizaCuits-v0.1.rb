##############################################################################
# ARCHIVO             : automatizaCuits-v0.1.rb
# AUTOR/ES            : Norman Ruiz
# VERSION             : 0.1 beta.
# FECHA DE CREACION   : 20/01/2020.
# ULTIMA ACTUALIZACION: 04/02/2020.
# LICENCIA            : GPL (General Public License) - Version 3.
#
#  **************************************************************************
#  * El software libre no es una cuestion economica sino una cuestion etica *
#  **************************************************************************
#
# Este programa es software libre;  puede redistribuirlo  o  modificarlo bajo
# los terminos de la Licencia Publica General de GNU  tal como se publica por
# la  Free Software Foundation;  ya sea la version 3 de la Licencia,  o (a su
# eleccion) cualquier version posterior.
#
# Este programa se distribuye con la esperanza  de que le sea util,  pero SIN
# NINGUNA  GARANTIA;  sin  incluso  la garantia implicita de MERCANTILIDAD  o
# IDONEIDAD PARA UN PROPOSITO PARTICULAR.
#
# Vea la Licencia Publica General GNU para mas detalles.
#
# Deberia haber recibido una copia de la Licencia Publica General de GNU junto
# con este proyecto, si no es asi, escriba a la Free Software Foundation, Inc,
# 59 Temple Place - Suite 330, Boston, MA 02111-1307, EE.UU.

#=============================================================================
# SISTEMA OPERATIVO   : Microsoft Windows 10 Pro
# IDE                 : Visual Studio Code Version: 1.41.1
# COMPILADOR          : ruby 2.6.5p114 (2019-10-01 revision 67812) [x64-mingw32]
# LICENCIA            : GPL (General Public License) - Version 3.
#=============================================================================
# DESCRIPCION:
#              Este script automatiza el alta de cuits en el servidor
#              InteliMatch.
#
##############################################################################

#*****************************************************************************
#                             INCLUSIONES ESTANDAR
#=============================================================================
require 'faraday'
require 'fileutils'

#*****************************************************************************
#                             INCLUSIONES PERSONALES
#=============================================================================

#*****************************************************************************
# DEFINICION DE LAS FUNCIONES
#=============================================================================

#=============================================================================
# FUNCION : CreaArchivos(aux)
# ACCION : Esta funcion crea los archivos de configuracion.
# PARAMETROS: string, contiene el numero de cuit con el que se esta trabajando.
# DEVUELVE : bool, determina si se creo un nuevo archivo de configuracion.
#-----------------------------------------------------------------------------
def CreaArchivos(aux)
    estado = false
    Dir.chdir("C:\\Imatch\\configuracion")
    archivo = "TR_" + aux + ".xml"
    print "\tVerificando archivo de configuracion " + archivo + "...\n"
    if File.exists?(archivo)
        print "\tArchivo " + archivo + " existe...\n"
    else
        File.open(archivo, 'w') do |registro|
            registro.puts '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            registro.puts '<ConfiguracionArchivo>'
            registro.puts '   <entidad>' + aux + '</entidad>'
            registro.puts '   <carpetaDeInput>C:\\SFTP\\Tickets\\' + aux + '\\</carpetaDeInput>'
            registro.puts '   <carpetaDeProcesados>C:\\SFTP\\Tickets\\' + aux + '\\procesados\\</carpetaDeProcesados>'
            registro.puts '   <carpetaDeErrores>C:\\SFTP\\Tickets\\' + aux + '\\errores\\</carpetaDeErrores>'
            registro.puts '   <prefix>PO</prefix>'
            registro.puts '   <readerConfig>C:\\Imatch\\Configuracion\\Sistema\\ticket\\TR_SpringConfig.xml</readerConfig>'
            registro.puts '   <cantidadDiasHistorico>365</cantidadDiasHistorico>'
            registro.puts '   <entidadLiquidante>false</entidadLiquidante>'
            registro.puts '   <capturaArchivos>true</capturaArchivos>'
            registro.puts '</ConfiguracionArchivo>'
        end
        print "\tArchivo " + archivo + " creado...\n"
        estado = true
    end
    return estado
end

#=============================================================================
# FUNCION : LoteDeCarga()
# ACCION : esta funcion recorre el directorio 'tickets' en busca de cuits
# PARAMETROS: void, no recibe nada.
# DEVUELVE : string[], con la lista de cuits que se encontraron.
#-----------------------------------------------------------------------------
def LoteDeCarga()
    print " #=============================================================================#\n"
    print "\tLote de carga en ejecucion...\n"
    print " #-----------------------------------------------------------------------------#\n"
    print "\tDetectando Cuits...\n"
    print " #-----------------------------------------------------------------------------#\n"
    aux = []
    cont = 0
    Dir.chdir("C:\\SFTP\\Tickets")
    Dir.foreach('.') do |item|
        next if item == '.' or item == '..'
        if File.directory?(item)
            print "\tCuit encontrado -> " + item + "...\n"
            aux[cont] = item
            cont += 1
        end
    end
    return aux
end

#=============================================================================
# FUNCION : LoteDeProceso(listadoCuits)
# ACCION : verifica la lista de cuits en busca de nuevos cuits, 
#          crea la estructura de directorios correspondiente y el 
#          archivo de configuracion correspondiente.
# PARAMETROS: string[], con la lista de cuits que se encontraron.
# DEVUELVE : bool, determina si se creo un nuevo archivo de configuracion.
#-----------------------------------------------------------------------------
def LoteDeProceso(listadoCuits)
    print " #=============================================================================#\n"
    print "\tLote de proceso en ejecucion...\n"
    print " #-----------------------------------------------------------------------------#\n"
    estado = false
    listadoCuits.each do |cuit|
        Dir.chdir("C:\\SFTP\\Tickets")
        print "\tProcesando " + cuit + "...\n"
        print "\tVerificando estructura de directorios...\n"
        procesados = cuit + "/procesados"
        if File.directory?(procesados)
            print "\tCarpeta <procesados> existente...\n"
        else
            Dir.mkdir(procesados)
            print "\tCarpeta <procesados> creada...\n"
        end
        errores = cuit + "/errores"
        if File.directory?(errores)
            print "\tCarpeta <errores> existente...\n"
        else
            Dir.mkdir(errores)
            print "\tCarpeta <errores> creada...\n"
        end
        if CreaArchivos(cuit)
            estado = true
        end
        print " #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#\n"
    end
    return estado
    print " #-----------------------------------------------------------------------------#\n"
end

#=============================================================================
# FUNCION : EnviaMensaje(estado).
# ACCION : Esta funcion envia un alerta notificando la nesecidad de un 
#          reinicio del servicio y genera un flag para reinicio automatio.
# PARAMETROS: bool, si trae true se envia el mensaje.
# DEVUELVE : void, no devuelve nada.
#-----------------------------------------------------------------------------
def EnviaMensaje(estado)
    if estado
        print "\tEnviar mensaje...\n"
        mensaje = '{"text":"Se detectaron cambios de configuracion, se requiere un reinicio del servicio, se programo un reinicio para las 03:00"}'
        url= 'https://hooks.slack.com/services/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'
        Faraday.post(url,mensaje, "Content-Type" => "application/json")
        Dir.chdir("C:\\Imatch\\scripts")
        File.open("flag.dat", 'w') do |registro|
        end
    end
end

#=============================================================================
# FUNCION : ReinicioServidor()
# ACCION : Esta funcion verifica la hora y la existencia de un flag y 
#          reinicia el servicio.
# PARAMETROS: void, no recibe nada.
# DEVUELVE : void, no devuelve nada.
#-----------------------------------------------------------------------------
def ReinicioServidor()
    Dir.chdir("C:\\Imatch\\scripts")
    hora = Time.now
    ahora = hora.strftime("%H%M")
    if ahora >= '0300' and ahora <= '0330' and File.exists?('flag.dat')
        system('net stop JBAS50SVC')
        system('net start JBAS50SVC')
        FileUtils.rm_rf('flag.dat')
    end
end

#=============================================================================
# FUNCION : Main().
# ACCION : Esta es la funcion principal del script.
# PARAMETROS: void, no recibe nada.
# DEVUELVE : void, no devuelve nada.
#-----------------------------------------------------------------------------
def Main()
    system('cls')
    print "\n"
    print " #=============================================================================#\n"
    print "\tVerificando configuracion...\n"
    print " #-----------------------------------------------------------------------------#\n"
    print "\n"

    # Declaro array vacio que contendra el listado de Cuits a verificar
    listadoCuits = []

    # Asigno el resultado del lote de carga al listado de Cuits
    listadoCuits = LoteDeCarga()

    # Ejecuto el lote de proceso en busca de posibles altas, retorno verdadero o falso
    # segun corresponda
    mensaje = LoteDeProceso(listadoCuits)

    # Evalue el resultado del proceso, en caso de existir un alta se emite un alerta.
    EnviaMensaje(mensaje)

    # Reinicio el servidor en caso de ser nesesario.
    ReinicioServidor()

    print " #-----------------------------------------------------------------------------#\n"
    print "\tProceso finalizado...\n"
    print " #=============================================================================#\n"
    print "\n"
end

# Llamo a la funcion Main que depliega el script
Main()

#=============================================================================
#                            FIN DE ARCHIVO
##############################################################################