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

  it 'Negación Esta condición recibe otras condiciones por parámetro y se cumple cuando ninguna de ellas se cumple.' do
    class MiClase5
      def foo1(p1)
      end
      def foo2(p1, p2)
      end
      def foo3(p1, p2, p3)
      end
    end

    metodos = Aspects.on MiClase5 do
      where name(/foo\d/), neg(has_parameters(1))
      # array con los métodos foo2 y foo3
    end
    expect(metodos).to eq [:foo2, :foo3]
  end

  xit 'Transformacion con inyeccion de parametro' do
    class MiClase6
      def hace_algo(p1, p2)
        p1 + '-' + p2
      end
      def hace_otra_cosa(p2, ppp)
        p2 + ':' + ppp
      end
    end

    Aspects.on MiClase6 do
      transform(where has_parameters(2, /p2/)) do
        inject(p2: 'bar')
      end
    end

    instancia = MiClase6.new
    #expect(instancia.hace_algo("foo")).to eq "foo-bar"
    # "foo-bar"


  end

  it 'Transformacion con Redirección de objeto sustituto por parámetro' do
    class A
      def saludar(x)
        "Hola, " + x
      end
    end

    class C
      def saludar(x)
        "Hola, " + x
      end
    end

    class B
      def saludar(x)
        "Adiosín, " + x
      end
    end

    Aspects.on A, C do
      transform(where name(/saludar/)) do
        redirect_to(B.new)
      end
    end

    respuesta_instancia_A = A.new.saludar("Mundo")
    respuesta_instancia_C = C.new.saludar("Mundo")
    expect(respuesta_instancia_A).to eq "Adiosín, Mundo"
    expect(respuesta_instancia_C).to eq "Adiosín, Mundo"
    #"Adiosín, Mundo"

  end

  it 'Inyeccion de logica' do
    class MiClase
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClase do
      transform(where name(/m1/)) do
        before do |instance, cont, *args|

          @x = 10
          new_args = args.map{ |arg| arg * 10 }
          cont.call(self, nil, *new_args)

        end
      end
    end

    instancia = MiClase.new
    expect(instancia.m1(1, 2)).to eq 30


  end

  xit 'Inyeccion de logica2' do
    class MiClase
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClase do
      transform(where name(/m3/)) do
        instead_of do |instance, *args|
          puts instance
          puts *args.inspect
          puts self
          @x = 123
        end
      end
    end

    instancia = MiClase.new
    expect(instancia.m3(48)).to eq 123
  end

  xit 'Inyeccion de logica3' do
    class MiClasarda
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClasarda do
      transform(where name(/m3/)) do
        instead_of do |instance, *args|
          args
        end
      end
    end

    instancia = MiClasarda.new
    expect(instancia.m3(1, 2, 3)).to eq [1, 2, 3]
  end

  it 'after' do
    class MiClasarda2
      attr_accessor :x

      def m1(x, y)
        x + y
      end

      def m2(x)
        @x = x
      end

      def m3(x)
        @x = x
      end
    end

    Aspects.on MiClasarda2 do
      transform(where name(/m2/)) do
        after do |instance, *args|
          puts self
          puts instance
          puts @x
          puts args.inspect

          if @x > 100
            2 * @x
          else
            @x
          end
        end
      end
    end

    instancia = MiClasarda2.new
    expect(instancia.m2(10)).to eq 10
  end
end
