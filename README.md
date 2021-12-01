1. Utilizando apenas imagens base de SO do dockerhub, crie:
   * uma imagem que rode apenas um webserver (openresty, nginx, apache, lighttpd)
   * uma imagem rodando apenas php-fpm
   * uma imagem rodando apenas o mysql
   * uma imagem rodando jenkins


2. Com as imagens criadas na questão 1, suba os utilizando o docker-compose e:
   * com as imagens do webserver, php-fpm e mysql rode um wordpress de forma que o conteudo seja mantido e recuperado mesmo após a destruição do compose
   * crie um job no jenkins que publique mensagens no wordpress


3. Utilizando apenas a imagem do webserver:
   * crie quantos deploys forem necessários para compor uma estrutura com split de trafego entre processamento dinâmico e conteúdo estático,
   mantendo o comportamento original do wordpress
   
   
4. Criar os seguintes jobs no jenkins:
   * um job que troque a senha do mysql e wordpress (se necessário, altere configurações no wordpress e mysql para comportar essa tarefa)
   * crie um job no jenkins que possibilite o upgrade dos demais containers


Utilize alguma linguagem/ferramenta de sua preferência para gerar alguns ou todos os elementos do teste ao finalizar

A forma com que os processos forem organizados será levada em conta para a avaliação, quanto mais flexível e reutilizável o conceito, melhor
O exercício deverá ser entregue via git (se possível clonavel por https publicamente)

Envie também as instruções necessárias para replicar a execução tenha em mente que vamos rodar e criar nossas próprias modificações na sua estrutura como forma de avaliar, perguntas serão feitas sobre o motivo de suas escolhas #comentários de todos os tipos no código e commits serão bem vindos!
