# PAGSEGURO

Este é um plugin do Ruby on Rails que permite utilizar o [PagSeguro](https://pagseguro.uol.com.br/?ind=689659), gateway de pagamentos do [UOL](http://uol.com.br).

## COMO USAR

### Configuração

O primeiro passo é instalar a biblioteca. Para isso, basta executar o comando

    gem install pagseguro

Adicione a biblioteca ao arquivo Gemfile:

~~~.ruby
gem "pagseguro", :git => 'git://github.com/fireho/pagseguro.git'
~~~

Lembre-se de utilizar a versão que você acabou de instalar.

Depois de instalar a biblioteca, você precisará executar gerar o arquivo de configuração, que deve residir em `config/pagseguro.yml`. Para gerar um arquivo de modelo execute

    rails generate pagseguro:install

O arquivo de configuração gerado será parecido com isto:

~~~.yml
development: &development
  developer: true
  base: "http://localhost:3000"
  return_to: "/pedido/efetuado"
  email: user@example.com

test:
  <<: *development

production:
  authenticity_token: 9CA8D46AF0C6177CB4C23D76CAF5E4B0
  email: user@example.com
  return_to: "/pedido/efetuado"
~~~

### Criando um Pagamento

Para criar um pagamento, você deverá utilizar a classe `PagSeguro::Order`. Esta classe deverá ser instanciada recebendo um identificador único do pedido. Este identificador permitirá identificar o pedido quando o [PagSeguro](https://pagseguro.uol.com.br/?ind=689659) notificar seu site sobre uma alteração no status do pedido.

~~~.ruby
class CartController < ApplicationController
  def checkout
    # Busca o pedido associado ao usuario; esta logica deve
    # ser implementada por voce, da maneira que achar melhor
    @invoice = current_user.invoices.first

    # Instanciando o objeto para geracao do formulario
    @order = PagSeguro::Order.new(@invoice.id)

    # adicionando os produtos do pedido ao objeto do formulario
    @invoice.items.each do |item|
      # Peso (:weight) padrão 0
      # Quantidade (:quantity) padrão 1
      # Frete (:shipping) padrão definido 0
      @order.add id: item.id, price: item.price, description: item.title
    end
  end
end
~~~

Se você precisar, pode definir o tipo de frete com o método `shipping_type`.

~~~.ruby
@order.shipping_type = "EN" || :pac      # 1 PAC
@order.shipping_type = "SD" || :sedex    # 2 Sedex
@order.shipping_type = "FT" || anything  # 3 Frete Proprio
~~~

Se você precisar, pode definir os dados de cobrança com o método `billing`.

~~~.ruby
@order.billing = {
  :name                  => "John Doe",
  :email                 => "john@doe.com",
  :address_zipcode       => "01234-567",
  :address_street        => "Rua Orobo",
  :address_number        => 72,
  :address_complement    => "Casa do fundo",
  :address_neighbourhood => "Tenorio",
  :address_city          => "Pantano Grande",
  :address_state         => "AC",
  :address_country       => "Brasil",
  :phone_area_code       => "22",
  :phone_number          => "12345678"
}
~~~
Se você precisar, você pode configurar um valor `extra`, para somar ou subtrair do valor total.

~~~.ruby
#desconto
@order.extra = -40.00

#acréscimo
@order.extra = 40.00

~~~

redirecione o usuário para pagamento:

~~~.ruby

class CartController < ApplicationController
    def checkout
        ....
        # envia requisição ao pagseguro
        @order.send

        redirect_to @order.link_to_pay
    end
end
~~~



### Recebendo notificações

Toda vez que o status de pagamento for alterado, o [PagSeguro](https://pagseguro.uol.com.br/?ind=689659) irá notificar sua URL de retorno com diversos dados. Você pode interceptar estas notificações com o método `pagseguro_notification`. O bloco receberá um objeto da classe `PagSeguro::Notification` e só será executado se for uma notificação verificada junto ao [PagSeguro](https://pagseguro.uol.com.br/?ind=689659).

~~~.ruby
class CartController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def confirm
    return unless request.post?

    pagseguro_notification do |notification|
      # Aqui voce deve verificar se o pedido possui os mesmos produtos
      # que voce cadastrou. O produto soh deve ser liberado caso o status
      # do pedido seja "completed" ou "approved"
    end

    render :nothing => true
  end
end
~~~
O método `pagseguro_notification` também pode receber como parâmetro o `authenticity_token` que será usado pra verificar a autenticação.

~~~.ruby
class CartController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def confirm
    return unless request.post?
    # Se voce receber pagamentos de contas diferentes, pode passar o
    # authenticity_token adequado como parametro para pagseguro_notification
    account = Account.find(params[:seller_id])
    pagseguro_notification(account.authenticity_token) do |notification|
    end

    render :nothing => true
  end
end
~~~

O objeto `notification` possui os seguintes métodos:

* `PagSeguro::Notification#products`: Lista de produtos enviados na notificação.
* `PagSeguro::Notification#shipping`: Valor do frete
* `PagSeguro::Notification#status`: Status do pedido
* `PagSeguro::Notification#payment_method`: Tipo de pagamento
* `PagSeguro::Notification#processed_at`: Data e hora da transação
* `PagSeguro::Notification#buyer`: Dados do comprador
* `PagSeguro::Notification#valid?(force=false)`: Verifica se a notificação é válida, confirmando-a junto ao PagSeguro. A resposta é jogada em cache e pode ser forçada com `PagSeguro::Notification#valid?(:force)`

**ATENÇÃO:** Não se esqueça de adicionar `skip_before_filter :verify_authenticity_token` ao controller que receberá a notificação; caso contrário, uma exceção será lançada.

### Utilizando modo de desenvolvimento

Toda vez que você enviar o formulário no modo de desenvolvimento, um arquivo YAML será criado em `tmp/pagseguro-#{Rails.env}.yml`. Esse arquivo conterá todos os pedidos enviados.

Depois, você será redirecionado para a URL de retorno que você configurou no arquivo `config/pagseguro.yml`. Para simular o envio de notificações, você deve utilizar a rake `pagseguro:notify`.

    $ rake pagseguro:notify ID=<id do pedido>

O ID do pedido deve ser o mesmo que foi informado quando você instanciou a class `PagSeguro::Order`. Por padrão, o status do pedido será `completed` e o tipo de pagamento `credit_card`. Você pode especificar esses parâmetros como no exemplo abaixo.

    $ rake pagseguro:notify ID=1 PAYMENT_METHOD=invoice STATUS=canceled NOTE="Enviar por motoboy" NAME="José da Silva" EMAIL="jose@dasilva.com"

#### PAYMENT_METHOD

* `credit_card`: Cartão de crédito
* `invoice`: Boleto
* `online_transfer`: Pagamento online
* `pagseguro`: Transferência entre contas do PagSeguro

#### STATUS

* `completed`: Completo
* `pending`: Aguardando pagamento
* `approved`: Aprovado
* `verifying`: Em análise
* `canceled`: Cancelado
* `refunded`: Devolvido

### Codificação (Encoding)

Esta biblioteca assume que você está usando UTF-8 como codificação de seu projeto. Neste caso, o único ponto onde os dados são convertidos para UTF-8 é quando uma notificação é enviada do UOL em ISO-8859-1.

Se você usa sua aplicação como ISO-8859-1, esta biblioteca NÃO IRÁ FUNCIONAR. Nenhum patch dando suporte ao ISO-8859-1 será aplicado; você sempre pode manter o seu próprio fork, caso precise.

## TROUBLESHOOTING

**Quero utilizar o servidor em Python para testar o retorno automático, mas recebo OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B)**

Neste caso, você precisa forçar a validação do POST enviado. Basta acrescentar a linha:

~~~.ruby
pagseguro_notification do |notification|
  notification.valid?(:force => true)
  # resto do codigo...
end
~~~

## AUTOR:

Nando Vieira (<http://simplesideias.com.br>)

Recomendar no [Working With Rails](http://www.workingwithrails.com/person/7846-nando-vieira)

## COLABORADORES:

* Nando Souza (<https://github.com/nandosousafr>)
* Elomar (<http://github.com/elomar>)
* Rafael (<http://github.com/rafaels>)
