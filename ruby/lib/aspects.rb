require_relative 'otroArchivo'

class Aspects#TODO JUAN hacer clase Origen. Que existan 2 tipos de origenes, Las clases y modulos que entiendan define_method y los objetos que entiendan define_singleton_method

  def self.on(*origenes, &bloque)
    contexto = CorredorDeCondiciones.new
    if origenes == [] then
      raise ArgumentError.new, "wrong number of arguments (0 for +1)"
    else
      contexto.listaDeOrigenes = buscarOrigenesPresentes(*origenes)
      contexto.instance_eval(&bloque)
    end
  end

  def self.buscarOrigenesPresentes(*origenes)
    origenesAux = []
    origenes.each { |origen| origenesAux.append filtrarOrigen(origen)}
    return origenesAux.flatten
  end

  def self.filtrarOrigen(origen)

    if(origen.class == Regexp)
      listaDeModulos = ObjectSpace.each_object(Module).filter {|modulo| origen.match?(modulo.to_s)}
      if listaDeModulos != [] then
        return listaDeModulos
      else raise ArgumentError, "origen vacío? el origen no existe"
      end
    end

    return origen
  end

end

class CondicionName
  attr_accessor :regex
  def seCumple? metodo
    @regex.match? metodo.name.to_s
  end
end

class CondicionParametros
  attr_accessor :cant_parametros_buscados, :tipo_actual, :expresion_regular

  def seCumple?(metodo)
    resultado = send(@tipo_actual, metodo)
    return resultado
  end

  def default(metodo)
    metodo.parameters.length == @cant_parametros_buscados
  end

  def mandatory(metodo)
    cantidad_aciertos = 0
    metodo.parameters.each {|tupla_parametro| if(tupla_parametro[0].to_s == :req.to_s) then cantidad_aciertos+=1 end}
    return cant_parametros_buscados == cantidad_aciertos
  end

  def optional(metodo)#TODO refactorizar esta repeticion de logica.
    cantidad_aciertos = 0
    metodo.parameters.each {|tupla_parametro| if(tupla_parametro[0].to_s == :opt.to_s) then cantidad_aciertos+=1 end}
    return cant_parametros_buscados == cantidad_aciertos
  end

  def regexp(metodo)
    cantidad_aciertos = 0
    metodo.parameters.each {|tupla_parametro| if(@expresion_regular.match?(tupla_parametro[1].to_s)) then cantidad_aciertos+=1 end}#TODO sketchy, revisar esto
    return cant_parametros_buscados == cantidad_aciertos
  end
end#TODO JUAN pasar default, mandatory, optional y regexp a clases?? que se instancien objetos. Para mi serian objetos onda regexp = proc{logica}

class CondicionNegada
  attr_accessor :metodos_a_evaluar

  def seCumple?(metodo)
    @metodos_a_evaluar.any? { |metodo_a_evaluar|  metodo_a_evaluar.to_s == metodo.name.to_s}
  end
end#TODO JUAN me dijo que seCumple? reciba la condicion anterior y al evaluarla (condicion.seCumple?) el true o false que me devuelva le haga not

class CorredorDeCondiciones#TODO JUAN hacer que el CorredorDeCondiciones reciba 1 origen. Instanciar 1 corredorDeCondiciones por cada Origen. Y que se encargue de evaluarlo.
  attr_accessor :listaDeOrigenes#redundante

  def initialize(*origenes)
    @listaDeOrigenes = *origenes
  end

  def where(*condiciones)
    lista = @listaDeOrigenes.map { |un_origen|  un_origen.instance_methods
                                                         .filter {|metodo| condiciones
                                                         .all? {|condicion| condicion.seCumple?(un_origen.new.method(metodo))}}}
    return lista.flatten.uniq#TODO comment para la linea de arriba: tengo que hacerle .new porque las clases no entienden .method, ademas de que instance_methods esta en false y deberia tener en cuenta los ancestors tmb
  end#TODO JUAN me dijo que a las clases le puedo hacer instance_method(metodo). No hace falta hacerle un_origen.new

  def name(regexp)
    condicion = CondicionName.new
    condicion.regex = regexp
    return condicion
  end

  def has_parameters(cant_parametros_buscados, tipo = default)
    condicion = CondicionParametros.new
    condicion.cant_parametros_buscados = cant_parametros_buscados
    if(tipo.class == Regexp) then
      condicion.tipo_actual = :regexp
      condicion.expresion_regular = tipo# ojo que esta es la regexp pasada por parametro
    else
      condicion.tipo_actual = tipo
    end

    return condicion
  end

  def default
    return :default
  end

  def mandatory
    return :mandatory#TODO JUAN pasar a objetos
  end

  def optional
    return :optional
  end

  def neg(condicion_parametro)
    condicion = CondicionNegada.new
    lista_metodos_que_si_cumplieron = where condicion_parametro
    lista_metodos_origenes = @listaDeOrigenes.flat_map {|origen| origen.instance_methods}.uniq
    metodos = lista_metodos_origenes - lista_metodos_que_si_cumplieron | lista_metodos_que_si_cumplieron - lista_metodos_origenes# el mayor overhead de la historia
    condicion.metodos_a_evaluar = metodos
    return condicion#TODO hacer lo de CondicionNeg
  end

  def transform(metodos_a_evaluar, &bloque)
    contexto = CorredorDeTransformaciones.new(@listaDeOrigenes, metodos_a_evaluar)
    contexto.instance_eval(&bloque)
  end
end

#Ejemplo
class Foo
end

class Foobar
end

class MiClase
  def foo
  end

  def bar
  end
end

module UnModulo
end

class UnaClase
  include UnModulo
end

class UnaClase2
end

class Atacante

end

class Guerrero < Atacante

end

class A
  def saludar(nombre1, nombre2)
    puts "Hola, #{nombre1} y #{nombre2}"
  end

  def saludar2
    puts "Hola, robertito"
  end
end

# A.define_method(:saludar) do |nombre1, nombre2|
#   puts "Hola, #{nombre1} y #{nombre2}"
# end
#A.new.saludar("tomas", "carlos")
#un_bloque = proc { |*args| "Los argumentos que me pasaron son: #{args}" }

#TODO ejemplo para mostrar a juan

# A.define_method(:m1, &un_bloque)
# saludar("roberto")

# meguardoelmetodo = A.new.method(:saludar)
# #meguardoelmetodo2.call("roberto", "pedro")
#
# bloque = proc do |nombre| meguardoelmetodo = self.method(:saludar)
# self.define_method(:saludar, meguardoelmetodo.call(nombre))
# end
# instancia = A.new.instance_eval(&bloque)
# instancia.saludar("pepardo")
#TODO FIN ejemplo para mostrar a juan

#puts A.new.instance_methods.inspect