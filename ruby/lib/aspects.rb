require_relative 'transformaciones'

class OrigenModulo
  attr_accessor :origen

  def initialize(objeto)
    @origen = objeto
  end

  def definir_metodo(simbolo, &bloque)
    @origen.define_method(simbolo, &bloque)
  end

  def mostrar_metodos()
    @origen.instance_methods | @origen.private_instance_methods
  end

  def obtener_metodo(symbol)
      @origen.instance_method(symbol)
  end

  def metodo_privado_definido?(metodo)
    @origen.private_method_defined? metodo.name
  end

  def metodo_publico_definido?(metodo)
    @origen.public_method_defined? metodo.name
  end

  def responde_a?(symbol)
    begin
      @origen.instance_method(symbol)
    rescue NameError
      return nil
    end
  end
end

class OrigenObjeto
  attr_accessor :origen

  def initialize(objeto)
    @origen = objeto
  end

  def definir_metodo(simbolo, &bloque)
    @origen.define_singleton_method(simbolo, &bloque)
  end

  def obtener_metodo(symbol)
    @origen.method(symbol).unbind
  end

  def mostrar_metodos()
    metodos_publicos | metodos_privados
  end

  def metodos_publicos
    @origen.methods
  end

  def metodos_privados
    @origen.private_methods
  end

  def metodo_publico_definido?(metodo_parametro)
    metodos_publicos.include?(metodo_parametro)
  end

  def metodo_privado_definido?(metodo_parametro)
    metodos_privados.include?(metodo_parametro)
  end

  def responde_a?(symbol)
    begin
      @origen.method(symbol)
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

  def self.convertirEnOrigen(objeto)

    if(objeto.is_a? Module) then
      origen = OrigenModulo.new(objeto)
    else
      origen = OrigenObjeto.new(objeto)
    end

    return origen
  end
end

class CondicionName
  attr_accessor :regex
  def seCumple?(origen_a_evaluar, metodo)
    @regex.match? metodo.name.to_s
  end
end

class ChequeadorDeCondiciones
  attr_accessor :condicion, :cant_parametros_buscados

  def initialize(condicion, cant_parametros_buscados)
    @condicion = condicion
    @cant_parametros_buscados = cant_parametros_buscados
  end

  def seCumple?(origen_a_evaluar, metodo)
    cantidad_aciertos = metodo.parameters.count {|tupla_parametro| @condicion.seCumple?(origen_a_evaluar, tupla_parametro)}
    return @cant_parametros_buscados == cantidad_aciertos
  end
end

class Has_parametersOptional

  def seCumple?(origen_a_evaluar, tupla_parametro)
    tupla_parametro[0].to_s == :opt.to_s
  end
end

class Has_parametersMandatory

  def seCumple?(origen_a_evaluar, tupla_parametro)
    tupla_parametro[0].to_s == :req.to_s
  end
end

class Has_parametersDefault

  def seCumple?(origen_a_evaluar, tupla_parametro)
    true
  end
end

class Has_parametersRegexp
  attr_accessor :expresion_regular

  def initialize( regexp)
    @expresion_regular = regexp
  end

  def seCumple?(origen_a_evaluar, tupla_parametro)
    @expresion_regular.match?(tupla_parametro[1].to_s)
  end
end

class CondicionNegada
  attr_accessor :condicion_a_negar

  def initialize(condicion_a_negar)
    @condicion_a_negar = condicion_a_negar
  end

  def seCumple?(origen_a_evaluar, metodo)
    not @condicion_a_negar.seCumple?(origen_a_evaluar, metodo)
  end
end

class CondicionIs_private

  def seCumple?(origen_a_evaluar, metodo_parametro)
    origen_a_evaluar.metodo_privado_definido? metodo_parametro
  end
end

class CondicionIs_public

  def seCumple?(origen_a_evaluar, metodo_parametro)
    origen_a_evaluar.metodo_publico_definido? metodo_parametro
  end
end

class CorredorDeCondiciones
  attr_accessor :origenAEvaluar

  def initialize(origen)
    @origenAEvaluar = origen
  end

  def where(*condiciones)
    @origenAEvaluar.mostrar_metodos.filter {|metodo| condiciones.all? {|condicion| condicion.seCumple?(@origenAEvaluar, @origenAEvaluar.obtener_metodo(metodo))}}
  end

  def name(regexp)
    condicion = CondicionName.new
    condicion.regex = regexp
    return condicion
  end

  def is_private
    CondicionIs_private.new
  end

  def is_public
    CondicionIs_public.new
  end

  def has_parameters(cant_parametros_buscados, tipo = default)

    if(tipo.is_a? Regexp) then
      ChequeadorDeCondiciones.new(Has_parametersRegexp.new(tipo), cant_parametros_buscados)#recordar que aca adentro tipo es la regexp
    else
      ChequeadorDeCondiciones.new(tipo, cant_parametros_buscados)
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