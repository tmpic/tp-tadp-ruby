
class CorredorDeTransformaciones#TODO JUAN hacer que el CorredorDeTransformaciones reciba 1 origen y 1 metodo_a_evaluar. Instanciar un CorredorDeTransformaciones por cada par(origen y metodo) y que lo evalue
  attr_accessor :listaDeOrigenes, :metodos_a_evaluar

  def initialize(listaDeOrigenes, metodos_a_evaluar)
    @listaDeOrigenes = listaDeOrigenes
    @metodos_a_evaluar = metodos_a_evaluar
  end

  def inject(*parametros_a_modificar)
    #TODO JUAN lo que me dijo es que unbindee el metodo(hacer algo parecido con after). Y se puede hacer *["roberto", "carlos"] que se traduce en metodo(p1: "roberto", p2: "carlos")
  end

  def redirect_to(objeto)
    metodos_del_objeto_en_simbolos = @metodos_a_evaluar.map { |metodo_buscado| objeto.class.instance_methods.find {|metodo_del_objeto| metodo_del_objeto == metodo_buscado} }
    metodos_del_objeto = metodos_del_objeto_en_simbolos.map { |metodo_sym|  objeto.method metodo_sym}
    metodos_del_objeto.each { |metodo_del_objeto| @listaDeOrigenes.each { |origen| origen.define_method(metodo_del_objeto.original_name, metodo_del_objeto.to_proc) }}
  end#TODO no entiendo porque no me tira el error de que estoy tratando de bindearlo un metodo a otra clase.
  #origen.class.send(:define_method, metodo_del_objeto.original_name, metodo_del_objeto.to_proc)
  # --ambas versiones funcionan sin el .class
  # old ver: origen.class.define_method(metodo_del_objeto.original_name, metodo_del_objeto.to_proc)
  #TODO JUAN esto se tendria que modificar en base a los cambios con CorredorDeCondiciones y CorredorDeTransformaciones

  def before(&bloque)
    contexto = CorredorDeLogica.new(@listaDeOrigenes, @metodos_a_evaluar)
    #@listaDeOrigenes.each {|origen| origen.instance_exec(&bloque)}
    #@listaDeOrigenes.each {|origen| @metodos_a_evaluar.each { |metodo| if origen.new.respond_to?(metodo) then  origen.define_method(metodo, &bloque) end}}
    #
    metodo_miclase = @listaDeOrigenes[0].new.method(:m1)
    proc_original = metodo_miclase.to_proc
    # proc_original.define_singleton_method :call do
    #   puts "reemplace call estoy re loco"
    # end
    # puts proc_original

    wrapped_block = proc do |*args|
      self.instance_exec(self, proc_original, *args, &bloque)#TODO JUAN, me dijo que lo haga distinto al enunciado, que reciba los mismos parametros que el original
    end

    @listaDeOrigenes.each {|origen| @metodos_a_evaluar.each { |metodo| if origen.new.respond_to?(metodo) then  origen.define_method(metodo, &wrapped_block) end}}
  end

  def instead_of(&bloque)
    params_metodo_original = @listaDeOrigenes[0].new.method(:m3).arity

    wrapped_block = proc do |*args|
      self.instance_exec(self, *args, &bloque)
    end

    @listaDeOrigenes.each {|origen| @metodos_a_evaluar.each { |metodo| if origen.new.respond_to?(metodo) then  origen.define_method(metodo, &wrapped_block) end}}
    #TODO JUAN esto parece estar bien, cambiaria en base a : cambios con CorredorDeCondiciones y CorredorDeTransformaciones
  end

  def after(&bloque)
    metodo_original = @listaDeOrigenes[0].new.method(:m2).unbind
    params_metodo_original = metodo_original.arity

    wrapped_block = proc do |*args|
      metodo_original.bind(self).call(10)
      self.instance_exec(self, *args, &bloque)
    end

    @listaDeOrigenes.each {|origen| @metodos_a_evaluar.each { |metodo| if origen.new.respond_to?(metodo) then
                                                                         origen.define_method(metodo, &wrapped_block)
                                                                       end}}
    #TODO JUAN esto parece estar bien, cambiaria en base a : cambios con CorredorDeCondiciones y CorredorDeTransformaciones
  end
end
