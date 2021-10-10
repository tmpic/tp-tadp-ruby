class BuscadorDeTuplas
  def self.buscarTupla(metodo_original, key, hash)
    tupla = []
    parametros = metodo_original.parameters
    indice = parametros.find_index { |tupla| tupla[1].to_s == key.to_s }
    if(hash.class == Proc) then
      resultado_bloque = 1
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

class Transformador
  attr_accessor :metodo_a_ejecutar, :listaDeTuplasIndiceValor_a_ejecutar#TODO en lugar de tener partes del inject, podria tener el inject entero y hacerlo polimorfico

  def initialize(metodo_a_ejecutar)
    @metodo_a_ejecutar = metodo_a_ejecutar
  end

  def transformar(origen_a_evaluar, metodo_a_evaluar)#TODO juan me dijo que el codigo es poco extensible para aceptar una nueva transformacion, que haga objetos inject, exista una lista de transformaciones y que se les pueda definir un orden antes de ejecutar.(inject siempre va al final)
    metodo_a_ejecutar_posta = @metodo_a_ejecutar
    listaDeTuplasIndiceValor_a_ejecutar_posta = @listaDeTuplasIndiceValor_a_ejecutar

    blockaso = proc do |*args|
      if(listaDeTuplasIndiceValor_a_ejecutar_posta != nil) then
        listaDeTuplasIndiceValor_a_ejecutar_posta.each do |indice, valor|
          if(valor.class == Proc) then
            parametro_anterior = args[indice]
            resultado = BuscadorDeTuplas.ejecutar_bloque(self, metodo_a_evaluar.to_s, parametro_anterior, &valor)
            args[indice] = resultado
          else
            args[indice] = valor
          end
        end
      end

      if(metodo_a_ejecutar_posta.is_a? UnboundMethod) then
        metodo_a_ejecutar_posta = metodo_a_ejecutar_posta.bind(self).to_proc
      end

      self.instance_exec(*args, &metodo_a_ejecutar_posta)
    end

    origen_a_evaluar.definir_metodo(metodo_a_evaluar, &blockaso)
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

  def inject(hash)#TODO hacer objeto
    metodo_original = @origen_a_evaluar.obtener_metodo(@metodo_a_evaluar)
    @transformador.listaDeTuplasIndiceValor_a_ejecutar = hash.keys.map { |key| BuscadorDeTuplas.buscarTupla(metodo_original, key, hash)}
  end

  def redirect_to(objeto)
    @transformador.metodo_a_ejecutar = objeto.method(@metodo_a_evaluar)
  end

  def before(&bloque)
    metodo_original = @origen_a_evaluar.obtener_metodo(@metodo_a_evaluar)

    wrapped_block = proc do |*args|
      metodo_original = metodo_original.bind(self)
      self.instance_exec(self, metodo_original, *args, &bloque)
    end

    @transformador.metodo_a_ejecutar = wrapped_block
  end

  def instead_of(&bloque)
    wrapped_block = proc do |*args|
      self.instance_exec(self, *args, &bloque)
    end

    @transformador.metodo_a_ejecutar = wrapped_block
  end

  def after(&bloque)
    metodo_original = @origen_a_evaluar.obtener_metodo(@metodo_a_evaluar)

    wrapped_block = proc do |*args|
      metodo_original.bind(self).call(*args)
      self.instance_exec(self, *args, &bloque)
    end

    @transformador.metodo_a_ejecutar = wrapped_block
  end
end
