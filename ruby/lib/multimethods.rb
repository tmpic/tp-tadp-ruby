class PartialBlock
  class ArgumentError < StandardError
  end

  attr_accessor :argumentos, :bloque

  def initialize(args, &block)
    @argumentos = args
    @bloque = block
  end

  def matches?(*args)
    if(args.length == @argumentos.length)
      then args.zip(@argumentos).all? { |tupla| tupla[0].class.ancestors.any? { |ancestro| ancestro == tupla[1]} }
    else false
    end

  end

  def call(*args)
    if(self.matches?(*args))
      then @bloque.call(*args)
    else raise ArgumentError.new
    end
  end
end

helloBlock = PartialBlock.new([String]) do |who|
  puts "Hello #{who}"
end

helloBlock2 = PartialBlock.new([String, String]) do |who, who2|
  puts "Hello #{who} and #{who2}"
end

puts helloBlock.matches?('parametro')
helloBlock.call("carlos")

puts helloBlock2.call("carlos", "roberto")


