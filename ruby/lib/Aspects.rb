class Aspects
  class ArgumentError < ::StandardError
    #def initialize(msg = "wrong number of arguments (0 for +1)")
    #  super
    #end
  end

  def on(*args, &bloque)
    if args == [] then
      raise ArgumentError, "wrong number of arguments (0 for +1)"
    else args.each { |argumento| self.funcionMagica(argumento, &bloque)}
    #falta contemplar el caso de que si la clase no existe
    end

  end

  def where()
    yield
  end

  def funcionMagica(algo, &bloque)
    if(algo.class == Class)
      algo.class_eval(&bloque)
    end
    if(algo.class == Object)
      algo.instance_eval(&bloque)
    end
    if(algo.class == Module)
      algo.module_eval(&bloque)
    end
    if(algo.class == Regexp)
      #if ObjectSpace.each_object.any? {|objeto| funcionMasMagicaAun?(algo, objeto)} then#horrible esto
        ObjectSpace.each_object(Class) {|clase| if algo.match?(clase.to_s) then clase.class_eval(&bloque) end}
        ObjectSpace.each_object(Module) {|modulo| if algo.match?(modulo.to_s) then modulo.module_eval(&bloque) end}
      #else
      #  raise ArgumentError, msg = "origen vacío? la clase: #{algo} no existe"
      #end
    end
  end

  def funcionMasMagicaAun?(algo, objeto)
    if(objeto.class != NilClass) then algo.match?(objeto.to_s) end
  end

end

#Ejemplo
module UnModulo
end

class UnaClase
  include UnModulo
end

class UnaClase2
end

name = Proc.new do
|regex| regex.match
end

#where = Proc.new do
#  yield
#end

unBloque = Proc.new do
  def hola
    puts "hola"
  end
end

def where
  puts self
  yield
end

Aspects.new.on UnaClase do
  where &unBloque
end

clasesita = UnaClase.new
clasesita.send(:hola)
clasesita.hola
