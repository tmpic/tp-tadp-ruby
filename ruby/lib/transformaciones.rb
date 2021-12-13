class BuscadorDeTuplas
  def self.buscarTupla(metodo_original, key, hash)
    tupla = []
    parametros = metodo_original.parameters
    indice = parametros.find_index { |tupla| tupla[1].to_s == key.to_s }
    if(hash.class == Proc) then
      resultado_bloque = 1 #TODO no uso resultado_bloque porque lo asigno mas adelante
      tupla.append indice, resultado_bloque
    else
      tupla.append indice, hash[key]
    end
    return tupla
  end

  def self.ejecutar_bloque(objeto_receptor, selector, parametro_original, &bloque)
    objeto_receptor.instance_exec(objeto_receptor, selector, parametro_original, &bloque)
  end
end

class ReferenciaAMetodo
  attr_accessor :metodo, :metodo_original
  def initialize(metodo, metodo_original)
    @metodo=metodo
    @metodo_original=metodo_original
  end
end

module Transformaciones
  include Comparable

  def <=>(otraTransformacion)
    self.prioridad <=> otraTransformacion.prioridad
  end
end

class Transformador
  attr_accessor :metodo_a_ejecutar, :transformaciones_a_aplicar

  def initialize(metodo_a_ejecutar)
    @metodo_a_ejecutar = metodo_a_ejecutar
    @transformaciones_a_aplicar = []
  end

  def transformar(origen_a_evaluar, metodo_a_evaluar)
    metodo_original = origen_a_evaluar.obtener_metodo(metodo_a_evaluar)
    referencia_a_metodo_a_evaluar = ReferenciaAMetodo.new(@metodo_a_ejecutar, metodo_original)
    transformaciones_a_aplicar_posta = @transformaciones_a_aplicar

    blockaso = proc do |*args|
      transformaciones_a_aplicar_posta.sort.each { |transformacion| transformacion.ejecutar(referencia_a_metodo_a_evaluar, self, args) }
      metodo_a_ejecutar_posta = referencia_a_metodo_a_evaluar.metodo

      if(metodo_a_ejecutar_posta.is_a? UnboundMethod) then
        metodo_a_ejecutar_posta = metodo_a_ejecutar_posta.bind(self).to_proc
      end

      self.instance_exec(*args, &metodo_a_ejecutar_posta)
    end

    origen_a_evaluar.definir_metodo(metodo_a_evaluar, &blockaso)
  end
end

class Inject
  attr_accessor :hash
  include Transformaciones
  def prioridad
    3
  end
  def initialize(hash)
    @hash=hash
  end

  def ejecutar(referencia_a_metodo_a_evaluar, objeto, args)

    listaDeTuplasIndiceValor_a_ejecutar = @hash.keys.map { |key| BuscadorDeTuplas.buscarTupla(referencia_a_metodo_a_evaluar.metodo_original, key, @hash)}

    if(listaDeTuplasIndiceValor_a_ejecutar != nil) then
      listaDeTuplasIndiceValor_a_ejecutar.each do |indice, valor|
        if(valor.class == Proc) then
          parametro_anterior = args[indice]
          resultado = BuscadorDeTuplas.ejecutar_bloque(objeto, referencia_a_metodo_a_evaluar.metodo_original.name.to_s, parametro_anterior, &valor)#recordar que &valor es un bloque
          args[indice] = resultado
        else
          args[indice] = valor
        end
      end
    end
  end
end

class Redirect_to
  attr_accessor :objeto
  include Transformaciones
  def prioridad
    2
  end

  def initialize(objeto)
    @objeto=objeto
  end

  def ejecutar(referencia_a_metodo_a_evaluar, objeto, args)
    symbol = referencia_a_metodo_a_evaluar.metodo_original.name
    referencia_a_metodo_a_evaluar.metodo = @objeto.method(symbol)
  end
end

class Before
  attr_accessor :bloque
  include Transformaciones
  def prioridad
    1
  end
  def initialize(&bloque)
    @bloque=bloque
  end

  def ejecutar(referencia_a_metodo_a_evaluar, objeto, args)
    metodo_original = referencia_a_metodo_a_evaluar.metodo
    bloque = @bloque

    wrapped_block = proc do |*args|
      metodo_original = metodo_original.bind(objeto)
      objeto.instance_exec(objeto, metodo_original, *args, &bloque)
    end

    referencia_a_metodo_a_evaluar.metodo = wrapped_block
  end
end

class Instead_of
  attr_accessor :bloque
  include Transformaciones
  def prioridad
    1
  end
  def initialize(&bloque)
    @bloque=bloque
  end

  def ejecutar(referencia_a_metodo_a_evaluar, objeto, args)
    bloque = @bloque

    wrapped_block = proc do |*args|
      objeto.instance_exec(objeto, *args, &bloque)
    end

    referencia_a_metodo_a_evaluar.metodo = wrapped_block
  end
end

class After
  attr_accessor :bloque
  include Transformaciones
  def prioridad
    1
  end
  def initialize(&bloque)
    @bloque=bloque
  end

  def ejecutar(referencia_a_metodo_a_evaluar, objeto, args)
    metodo_original = referencia_a_metodo_a_evaluar.metodo
    bloque = @bloque

    wrapped_block = proc do |*args|
      metodo_original.bind(objeto).call(*args)
      objeto.instance_exec(objeto, *args, &bloque)
    end

    referencia_a_metodo_a_evaluar.metodo = wrapped_block
  end
end

class CorredorDeTransformaciones
  attr_accessor :origen_a_evaluar, :metodo_a_evaluar, :transformador

  def initialize(origen_a_evaluar, metodo_a_evaluar)
    @origen_a_evaluar = origen_a_evaluar
    @metodo_a_evaluar = metodo_a_evaluar
    @transformador = Transformador.new(origen_a_evaluar.obtener_metodo(metodo_a_evaluar))
  end

  def transformar(origen_a_evaluar, metodo_a_evaluar)
    @transformador.transformar(origen_a_evaluar, metodo_a_evaluar)
  end

  def inject(hash)
    instancia = Inject.new(hash)
    @transformador.transformaciones_a_aplicar.append(instancia)
  end

  def redirect_to(objeto)
    instancia = Redirect_to.new(objeto)
    @transformador.transformaciones_a_aplicar.append(instancia)
  end

  def before(&bloque)
    instancia = Before.new(&bloque)
    @transformador.transformaciones_a_aplicar.append(instancia)
  end

  def instead_of(&bloque)
    instancia = Instead_of.new(&bloque)
    @transformador.transformaciones_a_aplicar.append(instancia)
  end

  def after(&bloque)
    instancia = After.new(&bloque)
    @transformador.transformaciones_a_aplicar.append(instancia)
  end
end

