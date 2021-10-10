require_relative 'otroArchivo'

class Origen#TODO convertir en 2 tipos de origenes, OrigenObjeto y OrigenModulo
  attr_accessor :tipo, :origen

  def definir_metodo(simbolo, &bloque)
    if(@tipo == :objeto) then
      @origen.define_singleton_method(simbolo, &bloque)
    else
      @origen.define_method(simbolo, &bloque)
    end
  end

  def mostrar_metodos()
    if(@tipo == :objeto) then
      @origen.methods
    else
      @origen.instance_methods
    end
  end

  def obtener_metodo(symbol)
    if(@tipo == :objeto) then
      @origen.method(symbol).unbind
    else
      @origen.instance_method(symbol)
    end
  end

  def responde_a?(symbol)
    begin
      if(@tipo == :objeto) then
        @origen.method(symbol)
      else
        @origen.instance_method(symbol)
      end
    rescue NameError
      return nil
    end
  end
end

class Aspects

  def self.on(*origenes, &bloque)

    if origenes == [] then
      raise ArgumentError.new, "wrong number of arguments (0 for +1)"
    else
      listaDeOrigenes = buscarOrigenesPresentes(*origenes)
      resultado = listaDeOrigenes.map { |origen| correr(origen, &bloque)}
      resultado.flatten.uniq
    end
  end

  def self.correr(origen, &bloque)
    contexto = CorredorDeCondiciones.new(origen)
    contexto.instance_eval(&bloque)
  end

  def self.buscarOrigenesPresentes(*origenes)
    origenesAux = []
    origenes.each { |origen| origenesAux.append filtrarOrigen(origen)}
    return origenesAux.flatten
  end

  def self.filtrarOrigen(objeto)

    if(objeto.class == Regexp)
      listaDeModulos = ObjectSpace.each_object(Module).filter {|modulo| objeto.match?(modulo.to_s)}
      if listaDeModulos != [] then
        listaDeOrigenes = listaDeModulos.map { |modulo| convertirEnOrigen(modulo)}
        return listaDeOrigenes
      else raise ArgumentError, "origen vacío? el origen no existe"
      end
    end

    return convertirEnOrigen(objeto)
  end

  def self.convertirEnOrigen(objeto)#TODO Aca por la condicion se debe generar OrigenObjeto o OrigenModulo
    origen = Origen.new
    origen.origen = objeto
    if(objeto.is_a? Module) then
      origen.tipo = :modulo
    else
      origen.tipo = :objeto
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

class Has_parametersOptional#TODO eliminar logica repetida, hacer que la condicion y la accion se pasen por parametro, ademas de usar .COUNT
  attr_accessor :cant_parametros_buscados

  def seCumple?(metodo)
    cantidad_aciertos = 0
    metodo.parameters.each {|tupla_parametro| if(tupla_parametro[0].to_s == :opt.to_s) then cantidad_aciertos+=1 end}
    return cant_parametros_buscados == cantidad_aciertos
  end
end

class Has_parametersMandatory
  attr_accessor :cant_parametros_buscados

  def seCumple?(metodo)
    cantidad_aciertos = 0
    metodo.parameters.each {|tupla_parametro| if(tupla_parametro[0].to_s == :req.to_s) then cantidad_aciertos+=1 end}
    return cant_parametros_buscados == cantidad_aciertos#todo count
  end
end

class Has_parametersDefault
  attr_accessor :cant_parametros_buscados

  def seCumple?(metodo)
    metodo.parameters.length == @cant_parametros_buscados
  end
end

class Has_parametersRegexp
  attr_accessor :cant_parametros_buscados, :expresion_regular

  def initialize(cant_parametros_buscados, regexp)
    @cant_parametros_buscados = cant_parametros_buscados
    @expresion_regular = regexp
  end

  def seCumple?(metodo)
    cantidad_aciertos = 0
    metodo.parameters.each {|tupla_parametro| if(@expresion_regular.match?(tupla_parametro[1].to_s)) then cantidad_aciertos+=1 end}
    return cant_parametros_buscados == cantidad_aciertos
  end
end

class CondicionNegada
  attr_accessor :condicion_a_negar

  def initialize(condicion_a_negar)
    @condicion_a_negar = condicion_a_negar
  end

  def seCumple?(metodo)
    not @condicion_a_negar.seCumple?(metodo)
  end
end

class CorredorDeCondiciones
  attr_accessor :origenAEvaluar

  def initialize(origen)
    @origenAEvaluar = origen
  end

  def where(*condiciones)
    @origenAEvaluar.mostrar_metodos.filter {|metodo| condiciones.all? {|condicion| condicion.seCumple?(@origenAEvaluar.obtener_metodo(metodo))}}
  end

  def name(regexp)
    condicion = CondicionName.new
    condicion.regex = regexp
    return condicion
  end

  def has_parameters(cant_parametros_buscados, tipo = default)

    if(tipo.is_a? Regexp) then
      Has_parametersRegexp.new(cant_parametros_buscados, tipo)#recordar que aca adentro tipo es la regexp
    else
      tipo.cant_parametros_buscados = cant_parametros_buscados
      return tipo
    end
  end

  def default
    Has_parametersDefault.new
  end

  def mandatory
    Has_parametersMandatory.new
  end

  def optional
    Has_parametersOptional.new
  end

  def neg(condicion_parametro)
    CondicionNegada.new(condicion_parametro)
  end

  def transform(metodos_a_evaluar, &bloque)
    resultado = metodos_a_evaluar.map { |metodo_a_evaluar| correrTransformacion(@origenAEvaluar, metodo_a_evaluar, &bloque)}
    resultado.flatten.uniq
  end

  def correrTransformacion(origen, metodo_a_evaluar, &bloque)
    contexto = CorredorDeTransformaciones.new(origen, metodo_a_evaluar)
    contexto.instance_eval(&bloque)
    contexto.transformar(origen, metodo_a_evaluar)
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