class Usuario
  attr_accessor :edad

  def initialize(edad)
    @edad = edad
  end

  #def edad_de
  #  proc { puts edad }
  #end
end

#bloque = menor.edad_de
bloque = proc do
  edad
end

describe 'test' do
  it '' do
    Usuario.define_method(:edad_de, &bloque)
    menor = Usuario.new(15)
    mayor = Usuario.new(19)

    expect(menor.edad_de).to eq 15
    expect(mayor.edad_de).to eq 19
    expect(mayor.respond_to? :edad_de).to eq true
  end

  it '' do
    #Usuario.define_method(:edad_de, &bloque)
    Usuario.class_eval(&bloque)
    menor = Usuario.new(15)
    mayor = Usuario.new(19)

    expect(menor.edad_de).to eq 15
    expect(mayor.edad_de).to eq 19
    expect(mayor.respond_to? :edad_de).to eq true
  end

end

