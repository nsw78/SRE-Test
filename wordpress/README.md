Como instalar o WordPress com Docker Compose

Pré-requisitos

Para seguir este tutorial, você precisará de:

Um servidor executando Ubuntu 18.04, junto com um usuário não root com sudoprivilégios e um firewall ativo. Para obter orientação sobre como configurá-los, consulte este guia de configuração inicial do servidor .
Docker instalado em seu servidor, seguindo as etapas 1 e 2 de Como instalar e usar o Docker no Ubuntu 18.04 .
Docker Compose instalado em seu servidor, seguindo a Etapa 1 de Como instalar o Docker Compose no Ubuntu 18.04 .
Um nome de domínio registrado. Este tutorial usará example.com em toda parte. Você pode obter um gratuitamente na Freenom ou usar o registrador de domínio de sua escolha.
Ambos os registros DNS a seguir configurados para o seu servidor. Você pode seguir esta introdução ao DigitalOcean DNS para obter detalhes sobre como adicioná-los a uma conta DigitalOcean, se é isso que você está usando:

Um registro A example.comapontando para o endereço IP público do seu servidor.
Um registro A apontando para o endereço IP público do seu servidor.www.example.com
Etapa 1 - Definindo a configuração do servidor web
Antes de executar qualquer contêiner, nossa primeira etapa será definir a configuração de nosso servidor da web Nginx. Nosso arquivo de configuração incluirá alguns blocos de localização específicos do WordPress, junto com um bloco de localização para direcionar as solicitações de verificação do Let's Encrypt para o cliente Certbot para renovações automatizadas de certificados.

Primeiro, crie um diretório de projeto para a configuração do WordPress chamado wordpresse navegue até ele:

mkdir wordpress && cd wordpress
 
Em seguida, crie um diretório para o arquivo de configuração:

mkdir nginx-conf
 
Abra o arquivo com nanoou com seu editor favorito:

nano nginx-conf/nginx.conf
 
Neste arquivo, adicionaremos um bloco de servidor com diretivas para o nome do nosso servidor e raiz do documento, e blocos de localização para direcionar a solicitação do cliente Certbot por certificados, processamento de PHP e solicitações de ativos estáticos.

Cole o código a seguir no arquivo. Certifique-se de substituir example.compelo seu próprio nome de domínio:

~ / wordpress / nginx-conf / nginx.conf
server {
        listen 80;
        listen [::]:80;

        server_name example.com www.example.com;

        index index.php index.html index.htm;

        root /var/www/html;

        location ~ /.well-known/acme-challenge {
                allow all;
                root /var/www/html;
        }

        location / {
                try_files $uri $uri/ /index.php$is_args$args;
        }

        location ~ \.php$ {
                try_files $uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass wordpress:9000;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $fastcgi_path_info;
        }

        location ~ /\.ht {
                deny all;
        }

        location = /favicon.ico {
                log_not_found off; access_log off;
        }
        location = /robots.txt {
                log_not_found off; access_log off; allow all;
        }
        location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
                expires max;
                log_not_found off;
        }
}
 
Nosso bloco de servidor inclui as seguintes informações:

Diretivas:

listen: Isso diz ao Nginx para escutar na porta 80, o que nos permitirá usar o plug-in webroot do Certbot para nossas solicitações de certificado. Observe que ainda não estamos incluindo a porta 443- atualizaremos nossa configuração para incluir SSL assim que tivermos obtido nossos certificados.
server_name: Isso define o nome do seu servidor e o bloco do servidor que deve ser usado para solicitações ao seu servidor. Certifique-se de substituir example.comnesta linha pelo seu próprio nome de domínio.
index: A indexdiretiva define os arquivos que serão usados ​​como índices ao processar solicitações ao seu servidor. Modificamos a ordem de prioridade padrão aqui, movendo index.phpna frente de index.htmlpara que o Nginx priorize os arquivos chamados index.phpquando possível.
root: Nossa rootdiretiva nomeia o diretório raiz para solicitações ao nosso servidor. Este diretório ,,/var/www/html é criado como um ponto de montagem no momento da compilação pelas instruções em nosso Dockerfile do WordPress . Essas instruções do Dockerfile também garantem que os arquivos da versão do WordPress sejam montados neste volume.
Blocos de localização:

location ~ /.well-known/acme-challenge: Este bloco de localização tratará de solicitações ao .well-knowndiretório, onde Certbot colocará um arquivo temporário para validar que o DNS de nosso domínio resolve para nosso servidor. Com essa configuração em vigor, seremos capazes de usar o plugin webroot do Certbot para obter certificados para nosso domínio.
location /: Neste bloco de localização, usaremos uma try_filesdiretiva para verificar se há arquivos que correspondem a solicitações de URI individuais. Em vez de retornar um Not Foundstatus 404 como padrão, no entanto, passaremos o controle para o index.phparquivo do WordPress com os argumentos de solicitação.
location ~ \.php$: Este bloco de localização tratará do processamento de PHP e proxy dessas solicitações para nosso wordpresscontêiner. Como nossa imagem Docker do WordPress será baseada na php:fpmimagem , também incluiremos opções de configuração que são específicas para o protocolo FastCGI neste bloco. Nginx requer um processador PHP independente para solicitações de PHP: em nosso caso, essas solicitações serão tratadas pelo php-fpmprocessador que acompanha a php:fpmimagem. Além disso, este bloco de localização inclui diretivas, variáveis ​​e opções específicas de FastCGI que farão proxy de solicitações para o aplicativo WordPress em execução em nosso wordpresscontêiner, definirão o índice preferido para o URI de solicitação analisado e analisarão as solicitações de URI.
location ~ /\.ht: Este bloco tratará os .htaccessarquivos, já que o Nginx não os servirá. A deny_alldiretiva garante que os .htaccessarquivos nunca serão servidos aos usuários.
location = /favicon.ico, location = /robots.txt: Esses blocos garantem que as solicitações para /favicon.icoe /robots.txtnão serão registradas.
location ~* \.(css|gif|ico|jpeg|jpg|js|png)$: Este bloqueio desativa o registro para solicitações de ativos estáticos e garante que esses ativos sejam altamente armazenáveis ​​em cache, já que costumam ser caros para servir.
Para obter mais informações sobre o proxy FastCGI, consulte Compreendendo e implementando o proxy FastCGI no Nginx . Para obter informações sobre servidores e blocos de localização, consulte Noções básicas sobre o servidor Nginx e algoritmos de seleção de bloco de localização .

Salve e feche o arquivo quando terminar de editar. Se você usou nano, faça-o pressionando CTRL+X, Ye então ENTER.

Com a configuração do Nginx em vigor, você pode prosseguir para a criação de variáveis ​​de ambiente para passar para seus contêineres de aplicativo e banco de dados no tempo de execução.

Etapa 2 - Definindo Variáveis ​​de Ambiente
Seu banco de dados e contêineres de aplicativo WordPress precisarão de acesso a certas variáveis ​​de ambiente em tempo de execução para que os dados do aplicativo persistam e sejam acessíveis ao seu aplicativo. Essas variáveis ​​incluem informações confidenciais e não confidenciais: valores confidenciais para sua senha raiz do MySQL e usuário e senha do banco de dados do aplicativo, e informações não confidenciais para o nome e host do banco de dados do aplicativo.

Em vez de definir todos esses valores em nosso arquivo Docker Compose - o arquivo principal que contém informações sobre como nossos contêineres serão executados - podemos definir os valores confidenciais em um .envarquivo e restringir sua circulação. Isso impedirá que esses valores sejam copiados para nossos repositórios de projeto e sejam expostos publicamente.

No diretório principal do projeto , abra um arquivo chamado :~/wordpress.env

nano .env
 
Os valores confidenciais que definiremos neste arquivo incluem uma senha para nosso usuário root do MySQL e um nome de usuário e senha que o WordPress usará para acessar o banco de dados.

Adicione os seguintes nomes de variáveis ​​e valores ao arquivo. Lembre-se de fornecer seus próprios valores aqui para cada variável:

~ / wordpress / .env
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_USER=your_wordpress_database_user
MYSQL_PASSWORD=your_wordpress_database_password
 
Incluímos uma senha para a conta administrativa root , bem como nosso nome de usuário e senha preferenciais para nosso banco de dados de aplicativo.

Salve e feche o arquivo quando terminar de editar.

Como seu .envarquivo contém informações confidenciais, você desejará garantir que ele seja incluído nos arquivos .gitignoree do projeto .dockerignore, que informam ao Git e ao Docker quais arquivos não devem ser copiados para seus repositórios Git e imagens do Docker, respectivamente.

Se você planeja trabalhar com Git para controle de versão, inicialize seu diretório de trabalho atual como um repositório com git init:

git init
 
Em seguida, abra um .gitignorearquivo:

nano .gitignore
 
Adicione .envao arquivo:

~ / wordpress / .gitignore
.env
 
Salve e feche o arquivo quando terminar de editar.

Da mesma forma, é uma boa precaução adicionar .enva um .dockerignorearquivo, para que ele não vá parar em seus contêineres quando você estiver usando este diretório como seu contexto de construção.

Abra o arquivo:

nano .dockerignore
 
Adicione .envao arquivo:

~ / wordpress / .dockerignore
.env
 
Abaixo disso, você pode opcionalmente adicionar arquivos e diretórios associados ao desenvolvimento do seu aplicativo:

~ / wordpress / .dockerignore
.env
.git
docker-compose.yml
.dockerignore
 
Salve e feche o arquivo quando terminar.

Com suas informações confidenciais no lugar, agora você pode prosseguir para definir seus serviços em um docker-compose.ymlarquivo.

Etapa 3 - Definindo serviços com Docker Compose
Seu docker-compose.ymlarquivo conterá as definições de serviço para sua configuração. Um serviço no Compose é um contêiner em execução e as definições de serviço especificam informações sobre como cada contêiner será executado.

Usando o Compose, você pode definir diferentes serviços para executar aplicativos de vários contêineres, já que o Compose permite vincular esses serviços a redes e volumes compartilhados. Isso será útil para nossa configuração atual, pois criaremos diferentes contêineres para nosso banco de dados, aplicativo WordPress e servidor da web. Também criaremos um contêiner para executar o cliente Certbot a fim de obter certificados para nosso servidor web.

Para começar, abra o docker-compose.ymlarquivo:

nano docker-compose.yml
 
Adicione o seguinte código para definir a versão do arquivo Compose e o dbserviço de banco de dados:

~ / wordpress / docker-compose.yml
version: '3'

services:
  db:
    image: mysql:8.0
    container_name: db
    restart: unless-stopped
    env_file: .env
    environment:
      - MYSQL_DATABASE=wordpress
    volumes:
      - dbdata:/var/lib/mysql
    command: '--default-authentication-plugin=mysql_native_password'
    networks:
      - app-network
 
A dbdefinição de serviço contém as seguintes opções:

image: Isso informa ao Compose qual imagem extrair para criar o contêiner. Estamos fixando a imagem aqui para evitar conflitos futuros, pois a imagem continua sendo atualizada. Para obter mais informações sobre a fixação de versão e como evitar conflitos de dependência, consulte a documentação do Docker sobre as práticas recomendadas do Dockerfile .mysql:8.0mysql:latest
container_name: Isso especifica um nome para o contêiner.
restart: Isso define a política de reinicialização do contêiner. O padrão é no, mas definimos o contêiner para reiniciar a menos que seja interrompido manualmente.
env_file: Esta opção diz ao Compose que gostaríamos de adicionar variáveis ​​de ambiente de um arquivo chamado .env, localizado em nosso contexto de construção. Neste caso, o contexto de construção é nosso diretório atual.
environment: Esta opção permite adicionar variáveis ​​de ambiente adicionais, além daquelas definidas em seu .envarquivo. Definiremos a MYSQL_DATABASEvariável igual a wordpresspara fornecer um nome para nosso banco de dados de aplicativo. Como essas informações não são confidenciais, podemos incluí-las diretamente no docker-compose.ymlarquivo.
volumes: Aqui, estamos montando um volume nomeado chamado dbdatapara o /var/lib/mysqldiretório no contêiner. Este é o diretório de dados padrão para MySQL na maioria das distribuições.
command: Esta opção especifica um comando para substituir a instrução CMD padrão para a imagem. Em nosso caso, adicionaremos uma opção ao mysqldcomando padrão da imagem Docker , que inicia o servidor MySQL no contêiner. Esta opção --default-authentication-plugin=mysql_native_password,, define a --default-authentication-pluginvariável do sistema como mysql_native_password, especificando qual mecanismo de autenticação deve controlar novos pedidos de autenticação para o servidor. Uma vez que o PHP e, portanto, nossa imagem WordPress não suportam o padrão de autenticação mais recente do MySQL , devemos fazer esse ajuste para autenticar nosso usuário do banco de dados do aplicativo.
networks: Isso especifica que nosso serviço de aplicativo se conectará à app-networkrede, que definiremos na parte inferior do arquivo.
Em seguida, abaixo de sua dbdefinição de serviço, adicione a definição para seu wordpressserviço de aplicativo:

~ / wordpress / docker-compose.yml
...
  wordpress:
    depends_on:
      - db
    image: wordpress:5.1.1-fpm-alpine
    container_name: wordpress
    restart: unless-stopped
    env_file: .env
    environment:
      - WORDPRESS_DB_HOST=db:3306
      - WORDPRESS_DB_USER=$MYSQL_USER
      - WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - wordpress:/var/www/html
    networks:
      - app-network
 
Nesta definição de serviço, estamos nomeando nosso contêiner e definindo uma política de reinicialização, como fizemos com o dbserviço. Também estamos adicionando algumas opções específicas para este contêiner:

depends_on: Esta opção garante que nossos contêineres iniciarão em ordem de dependência, com o wordpresscontêiner iniciando após o dbcontêiner. Nosso aplicativo WordPress depende da existência de nosso banco de dados de aplicativo e usuário, portanto, expressar essa ordem de dependência permitirá que nosso aplicativo seja iniciado corretamente.
image: Para esta configuração, estamos usando a 5.1.1-fpm-alpineimagem WordPress . Conforme discutido na Etapa 1 , o uso dessa imagem garante que nosso aplicativo terá o php-fpmprocessador que o Nginx requer para lidar com o processamento de PHP. Esta também é uma alpineimagem, derivada do projeto Alpine Linux , que ajudará a manter o tamanho geral da imagem reduzido. Para obter mais informações sobre as vantagens e desvantagens de usar alpineimagens e se isso faz sentido ou não para o seu aplicativo, consulte a discussão completa na seção Variantes de imagem da página de imagem do Docker Hub WordPress .
env_file: Mais uma vez, especificamos que queremos extrair valores de nosso .envarquivo, pois é onde definimos nosso usuário e senha do banco de dados do aplicativo.
environment: Aqui, estamos usando os valores que definimos em nosso .envarquivo, mas os estamos atribuindo aos nomes de variáveis ​​que a imagem do WordPress espera: WORDPRESS_DB_USERe WORDPRESS_DB_PASSWORD. Também estamos definindo um WORDPRESS_DB_HOST, que será o servidor MySQL em execução no dbcontêiner acessível na porta padrão do MySQL 3306,. O nosso WORDPRESS_DB_NAMEserá o mesmo valor que especificado na definição do serviço MySQL para o nosso MYSQL_DATABASE: wordpress.
volumes: Estamos montando um volume nomeado chamado wordpresspara o /var/www/htmlponto de montagem criado pela imagem do WordPress . Usar um volume nomeado dessa forma nos permitirá compartilhar nosso código de aplicativo com outros contêineres.
networks: Também estamos adicionando o wordpresscontêiner à app-networkrede.
Em seguida, abaixo da wordpressdefinição de serviço de aplicativo, adicione a seguinte definição para seu webserverserviço Nginx:

~ / wordpress / docker-compose.yml
...
  webserver:
    depends_on:
      - wordpress
    image: nginx:1.15.12-alpine
    container_name: webserver
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - wordpress:/var/www/html
      - ./nginx-conf:/etc/nginx/conf.d
      - certbot-etc:/etc/letsencrypt
    networks:
      - app-network
 
Novamente, estamos nomeando nosso contêiner e tornando-o dependente do wordpresscontêiner na ordem de inicialização. Também estamos usando uma alpineimagem - a 1.15.12-alpineimagem Nginx .

Esta definição de serviço também inclui as seguintes opções:

ports: Isso expõe a porta 80para habilitar as opções de configuração que definimos em nosso nginx.confarquivo na Etapa 1 .
volumes: Aqui, estamos definindo uma combinação de volumes nomeados e montagens de ligação :
wordpress:/var/www/html: Isso montará nosso código de aplicativo WordPress no /var/www/htmldiretório, o diretório que definimos como rootem nosso bloco de servidor Nginx.
./nginx-conf:/etc/nginx/conf.d: Isso vinculará a montagem do diretório de configuração Nginx no host ao diretório relevante no contêiner, garantindo que todas as alterações feitas nos arquivos do host sejam refletidas no contêiner.
certbot-etc:/etc/letsencrypt: Isso montará os certificados e chaves do Let's Encrypt relevantes para o nosso domínio no diretório apropriado no contêiner.
E, novamente, adicionamos esse contêiner à app-networkrede.

Finalmente, abaixo de sua webserverdefinição, adicione sua última definição de serviço para o certbotserviço. Certifique-se de substituir o endereço de e-mail e os nomes de domínio listados aqui por suas próprias informações:

~ / wordpress / docker-compose.yml
certbot:
  depends_on:
    - webserver
  image: certbot/certbot
  container_name: certbot
  volumes:
    - certbot-etc:/etc/letsencrypt
    - wordpress:/var/www/html
  command: certonly --webroot --webroot-path=/var/www/html --email sammy@example.com --agree-tos --no-eff-email --staging -d example.com -d www.example.com
 
Esta definição diz ao Compose para extrair a certbot/certbotimagem do Docker Hub. Ele também usa volumes nomeados para compartilhar recursos com o contêiner Nginx, incluindo os certificados de domínio e a chave certbot-etce o código do aplicativo wordpress.

Novamente, costumamos depends_onespecificar que o certbotcontêiner deve ser iniciado assim que o webserverserviço estiver em execução.

Também incluímos uma commandopção que especifica um subcomando a ser executado com o certbotcomando padrão do contêiner . O certonlysubcomando obterá um certificado com as seguintes opções:

--webroot: Isso diz ao Certbot para usar o plug-in webroot para colocar arquivos na pasta webroot para autenticação. Este plug-in depende do método de validação HTTP-01 , que usa uma solicitação HTTP para provar que o Certbot pode acessar recursos de um servidor que responde a um determinado nome de domínio.
--webroot-path: Isso especifica o caminho do diretório webroot.
--email: Seu e-mail preferido para registro e recuperação.
--agree-tos: Isso especifica que você concorda com o Contrato de Assinante da ACME .
--no-eff-email: Isso diz ao Certbot que você não deseja compartilhar seu e-mail com a Electronic Frontier Foundation (EFF). Sinta-se à vontade para omitir isso se preferir.
--staging: Isso informa ao Certbot que você gostaria de usar o ambiente de teste do Let's Encrypt para obter certificados de teste. Usar esta opção permite que você teste suas opções de configuração e evite possíveis limites de solicitação de domínio. Para obter mais informações sobre esses limites, consulte a documentação de limites de taxa do Let's Encrypt .
-d: Isso permite que você especifique os nomes de domínio que gostaria de aplicar à sua solicitação. Nesse caso, incluímos example.come . Certifique-se de substituí-los pelo seu próprio domínio.www.example.com
Abaixo da certbotdefinição de serviço, adicione suas definições de rede e volume:

~ / wordpress / docker-compose.yml
...
volumes:
  certbot-etc:
  wordpress:
  dbdata:

networks:
  app-network:
    driver: bridge
 
Nosso alto nível volumesfundamental define os volumes certbot-etc, wordpresse dbdata. Quando o Docker cria volumes, o conteúdo do volume é armazenado em um diretório no sistema de arquivos do host /var/lib/docker/volumes/, que é gerenciado pelo Docker. O conteúdo de cada volume é então montado a partir desse diretório para qualquer contêiner que usa o volume. Dessa forma, é possível compartilhar código e dados entre contêineres.

A rede de ponte definida pelo usuário app-networkpermite a comunicação entre nossos contêineres, pois eles estão no mesmo host Docker daemon. Isso agiliza o tráfego e a comunicação dentro do aplicativo, pois abre todas as portas entre os contêineres na mesma rede de ponte sem expor nenhuma porta ao mundo externo. Assim, nossos db, wordpresse webserveros recipientes podem se comunicar uns com os outros, e só precisa expor port 80 para acesso front-end para o aplicativo.

O docker-compose.ymlarquivo finalizado terá a seguinte aparência:

~ / wordpress / docker-compose.yml
version: '3'

services:
  db:
    image: mysql:8.0
    container_name: db
    restart: unless-stopped
    env_file: .env
    environment:
      - MYSQL_DATABASE=wordpress
    volumes:
      - dbdata:/var/lib/mysql
    command: '--default-authentication-plugin=mysql_native_password'
    networks:
      - app-network

  wordpress:
    depends_on:
      - db
    image: wordpress:5.1.1-fpm-alpine
    container_name: wordpress
    restart: unless-stopped
    env_file: .env
    environment:
      - WORDPRESS_DB_HOST=db:3306
      - WORDPRESS_DB_USER=$MYSQL_USER
      - WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - wordpress:/var/www/html
    networks:
      - app-network

  webserver:
    depends_on:
      - wordpress
    image: nginx:1.15.12-alpine
    container_name: webserver
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - wordpress:/var/www/html
      - ./nginx-conf:/etc/nginx/conf.d
      - certbot-etc:/etc/letsencrypt
    networks:
      - app-network

  certbot:
    depends_on:
      - webserver
    image: certbot/certbot
    container_name: certbot
    volumes:
      - certbot-etc:/etc/letsencrypt
      - wordpress:/var/www/html
    command: certonly --webroot --webroot-path=/var/www/html --email sammy@example.com --agree-tos --no-eff-email --staging -d example.com -d www.example.com

volumes:
  certbot-etc:
  wordpress:
  dbdata:

networks:
  app-network:
    driver: bridge
 
Salve e feche o arquivo quando terminar de editar.

Com suas definições de serviço no lugar, você está pronto para iniciar os contêineres e testar suas solicitações de certificado.

Etapa 4 - Obtenção de certificados e credenciais SSL
Podemos iniciar nossos contêineres com o docker-compose upcomando, que criará e executará nossos contêineres na ordem que especificamos. Se nossas solicitações de domínio forem bem-sucedidas, veremos o status de saída correto em nossa saída e os certificados corretos montados na /etc/letsencrypt/livepasta do webservercontêiner.

Criar os recipientes com docker-compose upea -dbandeira, que irá executar o db, wordpresse webserverrecipientes no fundo:

docker-compose up -d
 
Você verá uma saída confirmando que seus serviços foram criados:

Output
Creating db ... done
Creating wordpress ... done
Creating webserver ... done
Creating certbot   ... done


Usando docker-compose ps, verifique o status de seus serviços:

docker-compose ps
 
Se tudo foi bem sucedida, o seu db, wordpress e webserverserviços será Up e o certbot recipiente irá ter saído com uma 0 mensagem de status:

Output
  Name                 Command               State           Ports       
-------------------------------------------------------------------------
certbot     certbot certonly --webroot ...   Exit 0                      
db          docker-entrypoint.sh --def ...   Up       3306/tcp, 33060/tcp
webserver   nginx -g daemon off;             Up       0.0.0.0:80->80/tcp 
wordpress   docker-entrypoint.sh php-fpm     Up       9000/tcp 


Se você ver outra coisa senão Upna Statecoluna para os db, wordpress ou webserverserviços, ou um estado de saída diferente 0para o certbotrecipiente, certifique-se de verificar os logs de serviços com o docker-compose logscomando:

docker-compose logs service_name
 
Agora você pode verificar se seus certificados foram montados no webservercontêiner com docker-compose exec:

docker-compose exec webserver ls -la /etc/letsencrypt/live
 
Se suas solicitações de certificado forem bem-sucedidas, você verá uma saída como esta:

Output
total 16
drwx------    3 root     root          4096 May 10 15:45 .
drwxr-xr-x    9 root     root          4096 May 10 15:45 ..
-rw-r--r--    1 root     root           740 May 10 15:45 README
drwxr-xr-x    2 root     root          4096 May 10 15:45 example.com
Agora que você sabe que sua solicitação será bem-sucedida, pode editar a certbotdefinição do serviço para remover o --stagingsinalizador.

Aberto docker-compose.yml:

nano docker-compose.yml
 
Encontre a seção do arquivo com a certbotdefinição de serviço e substitua o --stagingsinalizador na commandopção pelo --force-renewalsinalizador, o que dirá ao Certbot que você deseja solicitar um novo certificado com os mesmos domínios de um certificado existente. A certbotdefinição do serviço agora será semelhante a esta:

~ / wordpress / docker-compose.yml
...
  certbot:
    depends_on:
      - webserver
    image: certbot/certbot
    container_name: certbot
    volumes:
      - certbot-etc:/etc/letsencrypt
      - certbot-var:/var/lib/letsencrypt
      - wordpress:/var/www/html
    command: certonly --webroot --webroot-path=/var/www/html --email sammy@example.com --agree-tos --no-eff-email --force-renewal -d example.com -d www.example.com
...
 
Agora você pode executar docker-compose uppara recriar o certbotcontêiner. Também incluiremos a --no-depsopção de informar ao Compose que ele pode pular a inicialização do webserverserviço, pois já está em execução:

docker-compose up --force-recreate --no-deps certbot
 
Você verá uma saída indicando que sua solicitação de certificado foi bem-sucedida:

Output
Recreating certbot ... done
Attaching to certbot
certbot      | Saving debug log to /var/log/letsencrypt/letsencrypt.log
certbot      | Plugins selected: Authenticator webroot, Installer None
certbot      | Renewing an existing certificate
certbot      | Performing the following challenges:
certbot      | http-01 challenge for example.com
certbot      | http-01 challenge for www.example.com
certbot      | Using the webroot path /var/www/html for all unmatched domains.
certbot      | Waiting for verification...
certbot      | Cleaning up challenges
certbot      | IMPORTANT NOTES:
certbot      |  - Congratulations! Your certificate and chain have been saved at:
certbot      |    /etc/letsencrypt/live/example.com/fullchain.pem
certbot      |    Your key file has been saved at:
certbot      |    /etc/letsencrypt/live/example.com/privkey.pem
certbot      |    Your cert will expire on 2019-08-08. To obtain a new or tweaked
certbot      |    version of this certificate in the future, simply run certbot
certbot      |    again. To non-interactively renew *all* of your certificates, run
certbot      |    "certbot renew"
certbot      |  - Your account credentials have been saved in your Certbot
certbot      |    configuration directory at /etc/letsencrypt. You should make a
certbot      |    secure backup of this folder now. This configuration directory will
certbot      |    also contain certificates and private keys obtained by Certbot so
certbot      |    making regular backups of this folder is ideal.
certbot      |  - If you like Certbot, please consider supporting our work by:
certbot      | 
certbot      |    Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
certbot      |    Donating to EFF:                    https://eff.org/donate-le
certbot      | 
certbot exited with code 0
Com seus certificados instalados, você pode prosseguir para modificar a configuração do Nginx para incluir SSL.

Etapa 5 - Modificando a configuração do servidor web e definição de serviço
Habilitar SSL em nossa configuração Nginx envolverá adicionar um redirecionamento HTTP para HTTPS, especificando nosso certificado SSL e locais de chave, e adicionando parâmetros de segurança e cabeçalhos.

Como você vai recriar o webserverserviço para incluir essas adições, pode interrompê-lo agora:

docker-compose stop webserver
 
Antes de modificar o arquivo de configuração em si, vamos primeiro obter os parâmetros de segurança Nginx recomendados do Certbot usando curl:

curl -sSLo nginx-conf/options-ssl-nginx.conf https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
 
Este comando salvará esses parâmetros em um arquivo chamado options-ssl-nginx.conf, localizado no nginx-confdiretório.

Em seguida, remova o arquivo de configuração Nginx que você criou anteriormente:

rm nginx-conf/nginx.conf
 
Abra outra versão do arquivo:

nano nginx-conf/nginx.conf
 
Adicione o seguinte código ao arquivo para redirecionar HTTP para HTTPS e para adicionar credenciais SSL, protocolos e cabeçalhos de segurança. Lembre-se de substituir example.compelo seu próprio domínio:

~ / wordpress / nginx-conf / nginx.conf
server {
        listen 80;
        listen [::]:80;

        server_name example.com www.example.com;

        location ~ /.well-known/acme-challenge {
                allow all;
                root /var/www/html;
        }

        location / {
                rewrite ^ https://$host$request_uri? permanent;
        }
}

server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name example.com www.example.com;

        index index.php index.html index.htm;

        root /var/www/html;

        server_tokens off;

        ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

        include /etc/nginx/conf.d/options-ssl-nginx.conf;

        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src * data: 'unsafe-eval' 'unsafe-inline'" always;
        # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        # enable strict transport security only if you understand the implications

        location / {
                try_files $uri $uri/ /index.php$is_args$args;
        }

        location ~ \.php$ {
                try_files $uri =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass wordpress:9000;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $fastcgi_path_info;
        }

        location ~ /\.ht {
                deny all;
        }

        location = /favicon.ico {
                log_not_found off; access_log off;
        }
        location = /robots.txt {
                log_not_found off; access_log off; allow all;
        }
        location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
                expires max;
                log_not_found off;
        }
}
 
O bloco do servidor HTTP especifica o webroot para solicitações de renovação do Certbot para o .well-known/acme-challengediretório. Ele também inclui uma diretiva de reescrita que direciona as solicitações HTTP para o diretório raiz para HTTPS.

O bloco do servidor HTTPS ativa ssle http2. Para ler mais sobre como HTTP / 2 itera em protocolos HTTP e os benefícios que isso pode ter para o desempenho do site, consulte a introdução de Como configurar o Nginx com suporte a HTTP / 2 no Ubuntu 18.04 .

Este bloco também inclui nosso certificado SSL e locais de chave, junto com os parâmetros de segurança recomendados do Certbot em que salvamos nginx-conf/options-ssl-nginx.conf.

Além disso, incluímos alguns cabeçalhos de segurança que nos permitirão obter classificações A em itens como os sites de teste de servidor SSL Labs e Security Headers . Estes cabeçalhos incluir X-Frame-Options, X-Content-Type-Options, Referrer Policy, Content-Security-Policy, e X-XSS-Protection. O cabeçalho HTTPStrict Transport Security (HSTS) está comentado - habilite isso apenas se você entender as implicações e tiver avaliado sua funcionalidade de “pré-carregamento” .

Nossas diretivas roote indextambém estão localizadas neste bloco, assim como o restante dos blocos de localização específicos do WordPress discutidos na Etapa 1 .

Depois de terminar a edição, salve e feche o arquivo.

Antes de recriar o webserverserviço, você precisará adicionar um 443mapeamento de porta à sua webserverdefinição de serviço.

Abra seu docker-compose.ymlarquivo:

nano docker-compose.yml
 
Na webserverdefinição de serviço, adicione o seguinte mapeamento de porta:

~ / wordpress / docker-compose.yml
...
  webserver:
    depends_on:
      - wordpress
    image: nginx:1.15.12-alpine
    container_name: webserver
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - wordpress:/var/www/html
      - ./nginx-conf:/etc/nginx/conf.d
      - certbot-etc:/etc/letsencrypt
    networks:
      - app-network
 
O docker-compose.ymlarquivo ficará assim quando concluído:

~ / wordpress / docker-compose.yml
version: '3'

services:
  db:
    image: mysql:8.0
    container_name: db
    restart: unless-stopped
    env_file: .env
    environment:
      - MYSQL_DATABASE=wordpress
    volumes:
      - dbdata:/var/lib/mysql
    command: '--default-authentication-plugin=mysql_native_password'
    networks:
      - app-network

  wordpress:
    depends_on:
      - db
    image: wordpress:5.1.1-fpm-alpine
    container_name: wordpress
    restart: unless-stopped
    env_file: .env
    environment:
      - WORDPRESS_DB_HOST=db:3306
      - WORDPRESS_DB_USER=$MYSQL_USER
      - WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - wordpress:/var/www/html
    networks:
      - app-network

  webserver:
    depends_on:
      - wordpress
    image: nginx:1.15.12-alpine
    container_name: webserver
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - wordpress:/var/www/html
      - ./nginx-conf:/etc/nginx/conf.d
      - certbot-etc:/etc/letsencrypt
    networks:
      - app-network

  certbot:
    depends_on:
      - webserver
    image: certbot/certbot
    container_name: certbot
    volumes:
      - certbot-etc:/etc/letsencrypt
      - wordpress:/var/www/html
    command: certonly --webroot --webroot-path=/var/www/html --email sammy@example.com --agree-tos --no-eff-email --force-renewal -d example.com -d www.example.com

volumes:
  certbot-etc:
  wordpress:
  dbdata:

networks:
  app-network:
    driver: bridge
 
Salve e feche o arquivo quando terminar de editar.

Recrie o webserverserviço:

docker-compose up -d --force-recreate --no-deps webserver
 
Verifique seus serviços com docker-compose ps:

docker-compose ps
 
Você deve ver uma saída indicando que os seus db, wordpresse webserverserviços estão em execução:

Output
  Name                 Command               State                     Ports                  
----------------------------------------------------------------------------------------------
certbot     certbot certonly --webroot ...   Exit 0                                           
db          docker-entrypoint.sh --def ...   Up       3306/tcp, 33060/tcp                     
webserver   nginx -g daemon off;             Up       0.0.0.0:443->443/tcp, 0.0.0.0:80->80/tcp
wordpress   docker-entrypoint.sh php-fpm     Up       9000/tcp    

Com seus contêineres em execução, agora você pode concluir a instalação do WordPress por meio da interface da web.

Etapa 6 - Concluindo a instalação por meio da interface da web
Com nossos contêineres em execução, podemos concluir a instalação por meio da interface da web do WordPress.

No navegador da web, navegue até o domínio do servidor. Lembre-se de substituir example.comaqui por seu próprio nome de domínio:

https://example.com
Selecione o idioma que deseja usar:

Seletor de idioma do WordPress

Após clicar em Continuar , você chegará à página principal de configuração, onde deverá escolher um nome para o seu site e um nome de usuário. É uma boa ideia escolher um nome de usuário fácil de lembrar aqui (em vez de “admin”) e uma senha forte. Você pode usar a senha que o WordPress gera automaticamente ou criar a sua própria.

Finalmente, você precisará inserir seu endereço de e-mail e decidir se deseja desencorajar os mecanismos de pesquisa de indexar seu site:

Página de configuração principal do WordPress

Clicar em Instalar WordPress na parte inferior da página o levará a um prompt de login:

Tela de login do WordPress

Uma vez logado, você terá acesso ao painel de administração do WordPress:

Painel de administração principal do WordPress

Com a instalação do WordPress concluída, agora você pode tomar medidas para garantir que seus certificados SSL sejam renovados automaticamente.

Etapa 7 - Renovação de certificados
Os certificados do Let's Encrypt são válidos por 90 dias, portanto, convém configurar um processo de renovação automatizado para garantir que eles não expirem. Uma maneira de fazer isso é criar um trabalho com o cronutilitário de agendamento. Nesse caso, criaremos um crontrabalho para executar periodicamente um script que renovará nossos certificados e recarregará nossa configuração Nginx.

Primeiro, abra um script chamado ssl_renew.sh:

nano ssl_renew.sh
 
Adicione o seguinte código ao script para renovar seus certificados e recarregar a configuração do servidor da web. Lembre-se de substituir o nome de usuário de exemplo aqui pelo seu próprio nome de usuário não root:

~ / wordpress / ssl_renew.sh
#!/bin/bash

COMPOSE="/usr/local/bin/docker-compose --no-ansi"
DOCKER="/usr/bin/docker"

cd /home/sammy/wordpress/
$COMPOSE run certbot renew --dry-run && $COMPOSE kill -s SIGHUP webserver
$DOCKER system prune -af
 
Este script primeiro atribui o docker-composebinário a uma variável chamada COMPOSEe especifica a --no-ansiopção, que executará docker-composecomandos sem caracteres de controle ANSI . Em seguida, ele faz o mesmo com o dockerbinário. Por fim, ele muda para o ~/wordpressdiretório do projeto e executa os seguintes docker-composecomandos:

docker-compose run: Isso iniciará um certbotcontêiner e substituirá o commandfornecido em nossa certbotdefinição de serviço. Em vez de usar o certonlysubcomando, estamos usando o renewsubcomando aqui, que renovará os certificados que estão perto de expirar. Incluímos --dry-runaqui a opção de testar nosso script.
docker-compose kill: Isso enviará um SIGHUPsinal ao webservercontêiner para recarregar a configuração do Nginx. Para obter mais informações sobre como usar este processo para recarregar a configuração do Nginx, consulte esta postagem do blog do Docker sobre como implantar a imagem oficial do Nginx com o Docker .
Em seguida, ele é executado docker system prunepara remover todos os recipientes e imagens não utilizados.

Feche o arquivo quando terminar de editar. Torne-o executável:

chmod +x ssl_renew.sh
 
Em seguida, abra seu arquivo raiz crontab para executar o script de renovação em um intervalo especificado:

sudo crontab -e
 
Se esta for a primeira vez que você edita este arquivo, será solicitado que você escolha um editor:

Output
no crontab for root - using an empty one

Select an editor.  To change later, run 'select-editor'.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.basic
  3. /usr/bin/vim.tiny
  4. /bin/ed

Choose 1-4 [1]:
...
Na parte inferior do arquivo, adicione a seguinte linha:

crontab
...
*/5 * * * * /home/sammy/wordpress/ssl_renew.sh >> /var/log/cron.log 2>&1
 
Isso definirá o intervalo de trabalho para cada cinco minutos, para que você possa testar se sua solicitação de renovação funcionou conforme o planejado. Também criamos um arquivo de log,, cron.logpara registrar a saída relevante do trabalho.

Após cinco minutos, verifique cron.logse a solicitação de renovação foi bem-sucedida ou não:

tail -f /var/log/cron.log
 
Você deve ver uma saída confirmando uma renovação bem-sucedida:

Output
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
** DRY RUN: simulating 'certbot renew' close to cert expiry
**          (The test certificates below have not been saved.)

Congratulations, all renewals succeeded. The following certs have been renewed:
  /etc/letsencrypt/live/example.com/fullchain.pem (success)
** DRY RUN: simulating 'certbot renew' close to cert expiry
**          (The test certificates above have not been saved.)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Agora você pode modificar o crontabarquivo para definir um intervalo diário. Para executar o script todos os dias ao meio-dia, por exemplo, você modificaria a última linha do arquivo para ficar assim:

crontab
...
0 12 * * * /home/sammy/wordpress/ssl_renew.sh >> /var/log/cron.log 2>&1
 
Você também deseja remover a --dry-runopção do seu ssl_renew.shscript:

~ / wordpress / ssl_renew.sh
#!/bin/bash

COMPOSE="/usr/local/bin/docker-compose --no-ansi"
DOCKER="/usr/bin/docker"

cd /home/sammy/wordpress/
$COMPOSE run certbot renew && $COMPOSE kill -s SIGHUP webserver
$DOCKER system prune -af
 
Seu crontrabalho garantirá que seus certificados Let's Encrypt não expirem, renovando-os quando forem elegíveis. Você também pode configurar a rotação do log com o utilitário Logrotate para girar e compactar seus arquivos de log.

** Certibot
https://community.letsencrypt.org/t/how-to-manage-and-add-names-to-etc-letsencrypt-live/38923/2
