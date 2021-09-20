class Aspects
  def on(*args, &bloque)
    args.each { |argumento| self.funcionMagica(argumento, &bloque)}
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
      puts "soy una regex jeje"
    end
  end

end

#Ejemplo
module UnModulo

end

class UnaClase
  include UnModulo
end

unBloque = proc do
  def hola
    puts "hola"
  end
end

Aspects.new.on UnModulo do
  def hola
    puts "hola"
  end
end

UnaClase.new.hola
#puts ObjectSpace.each_object.filter {|objeto| if !objeto.nil? then /^Foo.*/.match?(objeto.to_s.split("<")[1].split(":")[0]) end}
#puts ObjectSpace.each_object.filter {|objeto|  if !objeto.nil? then (if objeto.to_s == UnaClase.to_s then puts "salmon" end) end}
#puts ObjectSpace.each_object.filter {|a| a.is_a? UnModulo }#[0].to_s.split("<")[1].split(":")[0]
puts /^Foo.*/.match?("#<UnaClase:0x0000026970b312e0>")
#puts UnaClase.to_s
#puts global_variables
ObjectSpace.each_object {|a| puts a}