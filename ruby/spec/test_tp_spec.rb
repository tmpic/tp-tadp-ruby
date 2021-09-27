require 'rspec'
require_relative '../lib/aspects'

describe 'tp ruby' do
  xit 'Aspects con Regexp' do
    Aspects.on MiClase, /^Foo.*/, /.*bar/ do
      def hola
        "hola"
      end
    end

    miclase = MiClase.new
    foo = Foo.new
    foobar = Foobar.new

    expect(miclase.hola).to eq "hola"
    expect(foo.hola).to eq "hola"
    expect(foobar.hola).to eq "hola"
  end

  xit 'Se debe de poder definir un aspecto para un objeto' do
    miObjeto = Object.new
    Aspects.on miObjeto do
      def hola
        "hola2"
      end
    end
    expect(miObjeto.hola).to eq "hola2"
  end

  it 'El framework no debe permitir la definición de un Origen vacío' do
    expect{Aspects.on}.to raise_error(ArgumentError, "wrong number of arguments (0 for +1)")
  end

  it 'El framework debe lanzar una excepcion ante la no existencia de un origen' do
    expect{Aspects.on /NombreDeClaseQueNoExiste/ do end }.to raise_error(ArgumentError, "origen vacío? el origen no existe")
  end

  it 'where me tiene que devolver los metodos que cumplen la condicion' do
    class Roberto
      def foo
      end
      def bar
      end
    end
    metodos = Aspects.on /Roberto/ do
      where name(/foo/)

    end

    expect(metodos).to eq [:foo]
  end

  it 'probando has_parameters' do
    class MiClase2
      def foo(p1, p2, p3, p4='a', p5='b', p6='c')
      end
      def bar(p1, p2='a', p3='b', p4='c')
      end
    end

    metodos = Aspects.on MiClase2 do
      where has_parameters(3, mandatory)
      #where has_parameters(6)
      # array con el método foo
    end

    expect(metodos).to eq [:foo]
  end

  it 'probando has_parameters2' do
    class MiClase3
      def foo(p1, p2, p3, p4='a', p5='b', p6='c')
      end
      def bar(p1, p2='a', p3='b', p4='c')
      end
    end

    metodos = Aspects.on MiClase3 do
      where has_parameters(3, optional)
      # array con los métodos foo y bar
    end

    expect(metodos).to eq [:foo, :bar]
  end

  it 'probando has_parameters3' do
    class MiClase4
      def foo(param1, param2)
      end

      def bar(param1)
      end
    end

    metodos = Aspects.on MiClase4 do
      where has_parameters(1, /param.*/)
      # array con el método bar

    end
    expect(metodos).to eq [:bar]
  end

  it 'NegaciónEsta condición recibe otras condiciones por parámetro y se cumple cuando ninguna de ellas se cumple.' do
    class MiClase5
      def foo1(p1)
      end
      def foo2(p1, p2)
      end
      def foo3(p1, p2, p3)
      end
    end

    metodos = Aspects.on MiClase5 do
      where neg(has_parameters(1))
      # array con los métodos foo2 y foo3
    end
    expect(metodos).to eq [:foo2, :foo3]
  end
end
