require_relative 'otroArchivo'

class Aspects

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
    if(origen.is_a? Module)
      return origen
    end
    if(origen.class == Object)
      return origen
    end
    if(origen.class == Regexp)
      listaDeModulos = ObjectSpace.each_object(Module).filter {|modulo| origen.match?(modulo.to_s)}
      if listaDeModulos != [] then
        return listaDeModulos
      else raise ArgumentError, "origen vacío? el origen no existe"
      end
    end
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
end

class CondicionNegada
  attr_accessor :metodos_a_evaluar

  def seCumple?(metodo)
    @metodos_a_evaluar.any? { |metodo_a_evaluar|  metodo_a_evaluar.to_s == metodo.name.to_s}
  end
end

class CorredorDeCondiciones
  attr_accessor :listaDeOrigenes

  def initialize(*origenes)
    @listaDeOrigenes = *origenes
  end

  def where(*condiciones)
    lista = @listaDeOrigenes.map { |un_origen|  un_origen.instance_methods
                                                         .filter {|metodo| condiciones
                                                         .all? {|condicion| condicion.seCumple?(un_origen.new.method(metodo))}}}
    return lista.flatten.uniq#TODO comment para la linea de arriba: tengo que hacerle .new porque las clases no entienden .method, ademas de que instance_methods esta en false y deberia tener en cuenta los ancestors tmb
  end

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
    return :mandatory
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
    return condicion
  end

  def transform(metodos_a_evaluar, &bloque)
    contexto = CorredorDeTransformaciones.new(@listaDeOrigenes, metodos_a_evaluar)
    resultado = contexto.instance_eval(&bloque)
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
    puts "Hola, juancho y talarga"
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

# meguardoelmetodo2 = A.new.method(:saludar)
# #meguardoelmetodo2.call("roberto", "pedro")
#
# bloque = proc do |nombre| meguardoelmetodo = self.method(:saludar)
# self.define_method(:saludar, meguardoelmetodo.call(nombre))
# end
# instancia = A.new.instance_eval(&bloque)
# instancia.saludar("pepardo")
#TODO FIN ejemplo para mostrar a juan
# class A
#   def saludar(x)
#     "Hola, " + x
#   end
# end
#
#
# #---------------
# class B
#   def m1
#     puts "m1 viejo"
#   end
# end
# objeto = B.new
# bloque = proc{|nombre1, nombre2| "hola #{nombre1} y #{nombre2}"}
#
# metodo_miclase = objeto.method :m1
# proc_original = metodo_miclase.to_proc
# proc_original.define_singleton_method :call do
#   puts "reemplace call estoy re loco"
# end
# proc_original.call