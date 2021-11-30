Como automatizar a configuração do Jenkins com a configuração do Docker e do Jenkins como código

Etapa 1 - Desativar o assistente de configuração
O uso do JCasC elimina a necessidade de mostrar o assistente de configuração; portanto, nesta primeira etapa, você criará uma versão modificada da jenkins/jenkinsimagem oficial que tem o assistente de configuração desativado. Você fará isso criando um Dockerfilee construindo uma imagem personalizada do Jenkins a partir dele.

A jenkins/jenkinsimagem permite ativar ou desativar o assistente de configuração, passando uma propriedade do sistema nomeada jenkins.install.runSetupWizardpor JAVA_OPTSmeio da variável de ambiente. Os usuários da imagem podem passar a JAVA_OPTSvariável de ambiente em tempo de execução usando o --envsinalizador para docker run. No entanto, essa abordagem colocaria o ônus de desativar o assistente de configuração sobre o usuário da imagem. Em vez disso, você deve desabilitar o assistente de configuração no momento da construção, para que o assistente de configuração seja desabilitado por padrão.

Você pode conseguir isso criando um Dockerfilee usando a ENVinstrução para definir a JAVA_OPTSvariável de ambiente.

Primeiro, crie um novo diretório dentro do seu servidor para armazenar os arquivos que você criará neste tutorial:

mkdir -p $HOME/jenkins/jcasc
 
Em seguida, navegue dentro desse diretório:

cd $HOME/jenkins/jcasc
 
Em seguida, usando seu editor, crie um novo arquivo chamado Dockerfile:

nano $HOME/jenkins/jcasc/Dockerfile
 
Em seguida, copie o seguinte conteúdo no Dockerfile:

~ / jenkins / jcasc /
FROM jenkins/jenkins:latest
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
 
Aqui, você está usando a FROMinstrução para especificar jenkins/jenkins:latestcomo imagem base e a ENVinstrução para definir a JAVA_OPTSvariável de ambiente.

Salve o arquivo e saia do editor pressionando CTRL+Xseguido de Y.

Com essas modificações no lugar, construa uma nova imagem Docker personalizada e atribua a ela uma tag exclusiva (usaremos jcascaqui):

docker build -t jenkins:jcasc .
 
Você verá uma saída semelhante a esta:

Output
Sending build context to Docker daemon  2.048kB
Step 1/2 : FROM jenkins/jenkins:latest
 ---> 1f4b0aaa986e
Step 2/2 : ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
 ---> 7566b15547af
Successfully built 7566b15547af
Successfully tagged jenkins:jcasc
Depois de construída, execute sua imagem personalizada executando docker run:

docker run --name jenkins --rm -p 8080:8080 jenkins:jcasc
 
Você usou a --name jenkinsopção de dar ao seu contêiner um nome fácil de lembrar; caso contrário, um ID hexadecimal aleatório seria usado (por exemplo f1d701324553). Você também especificou o --rmsinalizador para que o contêiner seja removido automaticamente depois de interromper o processo do contêiner. Por último, você configurou a porta do host do servidor 8080para proxy para a porta do contêiner 8080usando o -psinalizador; 8080é a porta padrão de onde a IU da web do Jenkins é servida.

Jenkins levará um curto período de tempo para iniciar. Quando o Jenkins estiver pronto, você verá a seguinte linha na saída:

Output
... hudson.WebAppMain$3#run: Jenkins is fully up and running
Agora, abra seu navegador para server_ip:8080. Você verá imediatamente o painel sem o assistente de configuração.

O painel do Jenkins

Você acabou de confirmar que o assistente de configuração foi desativado. Para limpar, pare o recipiente pressionando CTRL+C. Se você especificou o --rmsinalizador anteriormente, o contêiner interrompido será removido automaticamente.

Nesta etapa, você criou uma imagem personalizada do Jenkins com o assistente de configuração desativado. No entanto, o canto superior direito da interface da web agora mostra um ícone de notificação vermelho indicando que há problemas com a configuração. Clique no ícone para ver os detalhes.

O painel do Jenkins mostrando problemas

O primeiro aviso informa que você não configurou o URL do Jenkins. O segundo informa que você não configurou nenhum esquema de autenticação e autorização e que os usuários anônimos têm permissões totais para executar todas as ações em sua instância do Jenkins. Anteriormente, o assistente de configuração o orientava na solução desses problemas. Agora que você o desabilitou, você precisa replicar as mesmas funções usando JCasC. O restante deste tutorial envolverá a modificação de sua Dockerfileconfiguração e do JCasC até que não haja mais problemas (ou seja, até que o ícone de notificação vermelho desapareça).

Na próxima etapa, você começará esse processo pré-instalando uma seleção de plug-ins do Jenkins, incluindo o plug-in Configuração como código, em sua imagem personalizada do Jenkins.

Etapa 2 - Instalando os plug-ins do Jenkins
Para usar o JCasC, você precisa instalar o plugin Configuração como Código. Atualmente, nenhum plug-in está instalado. Você pode confirmar isso navegando para .http://server_ip:8080/pluginManager/installed

Painel do Jenkins mostrando que nenhum plug-in está instalado

Nesta etapa, você modificará seu Dockerfilepara pré-instalar uma seleção de plug-ins, incluindo o plug-in Configuração como Código.

Para automatizar o processo de instalação do plug-in, você pode usar um script de instalação que vem com a jenkins/jenkinsimagem Docker. Você pode encontrá-lo dentro do contêiner em /usr/local/bin/install-plugins.sh. Para usá-lo, você precisa:

Crie um arquivo de texto contendo uma lista de plug-ins para instalar
Copie-o para a imagem Docker
Execute o install-plugins.shscript para instalar os plug-ins
Primeiro, usando seu editor, crie um novo arquivo chamado plugins.txt:

nano $HOME/jenkins/jcasc/plugins.txt
 
Em seguida, adicione a seguinte lista separada por nova linha de nomes e versões de plug-ins (usando o formato <id>:<version>):

~ / jenkins / jcasc / plugins.txt
ant:latest
antisamy-markup-formatter:latest
build-timeout:latest
cloudbees-folder:latest
configuration-as-code:latest
credentials-binding:latest
email-ext:latest
git:latest
github-branch-source:latest
gradle:latest
ldap:latest
mailer:latest
matrix-auth:latest
pam-auth:latest
pipeline-github-lib:latest
pipeline-stage-view:latest
ssh-slaves:latest
timestamper:latest
workflow-aggregator:latest
ws-cleanup:latest
 
Salve o arquivo e saia do editor.

A lista contém o plug-in Configuração como código, bem como todos os plug-ins sugeridos pelo assistente de configuração (correto a partir do Jenkins v2.251). Por exemplo, você tem o plug-in Git , que permite ao Jenkins trabalhar com repositórios Git; você também tem o plug-in Pipeline , que na verdade é um conjunto de plug-ins que permite definir jobs do Jenkins como código.

Observação: a lista mais atualizada de plug-ins sugeridos pode ser inferida a partir do código-fonte . Você também pode encontrar uma lista dos plug-ins mais populares contribuídos pela comunidade em plugins.jenkins.io . Sinta-se à vontade para incluir quaisquer outros plug-ins que desejar na lista.

Em seguida, abra o Dockerfilearquivo:

nano $HOME/jenkins/jcasc/Dockerfile
 
Nele, adicione uma COPYinstrução para copiar o plugins.txtarquivo para o /usr/share/jenkins/ref/diretório dentro da imagem; é aqui que o Jenkins normalmente procura plug-ins. Em seguida, inclua uma RUNinstrução adicional para executar o install-plugins.shscript:

~ / jenkins / jcasc / Dockerfile
FROM jenkins/jenkins
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
 
Salve o arquivo e saia do editor. Em seguida, crie uma nova imagem usando o revisado Dockerfile:

docker build -t jenkins:jcasc .
 
Esta etapa envolve o download e a instalação de vários plug-ins na imagem e pode levar algum tempo para ser executado, dependendo da sua conexão com a Internet. Assim que os plug-ins forem instalados, execute a nova imagem do Jenkins:

docker run --name jenkins --rm -p 8080:8080 jenkins:jcasc
 
Depois que a Jenkins is fully up and runningmensagem aparecer stdout, navegue até server_ip:8080/pluginManager/installedpara ver uma lista de plug-ins instalados. Você verá uma caixa de seleção sólida ao lado de todos os plug-ins especificados dentro plugins.txt, bem como uma caixa de seleção esmaecida ao lado dos plug-ins, que são dependências desses plug-ins.

Uma lista de plug-ins instalados

Depois de confirmar que o plug-in Configuração como código está instalado, encerre o processo do contêiner pressionando CTRL+C.

Nesta etapa, você instalou todos os plug-ins sugeridos do Jenkins e o plug-in Configuração como código. Agora você está pronto para usar o JCasC para resolver os problemas listados na caixa de notificação. Na próxima etapa, você corrigirá o primeiro problema, que avisa que o URL raiz do Jenkins está vazio .

Etapa 3 - Especificando o URL do Jenkins
O URL do Jenkins é um URL para a instância do Jenkins que pode ser roteado a partir dos dispositivos que precisam acessá-lo. Por exemplo, se você estiver implantando o Jenkins como um nó dentro de uma rede privada, o URL do Jenkins pode ser um endereço IP privado ou um nome DNS que pode ser resolvido usando um servidor DNS privado. Para este tutorial, é suficiente usar o endereço IP do servidor (ou 127.0.0.1para hosts locais) para formar a URL do Jenkins.

Você pode definir o URL do Jenkins na interface da web navegando server_ip:8080/configuree inserindo o valor no campo URL do Jenkins sob o título Localização do Jenkins . Veja como fazer o mesmo usando o plugin Configuração como Código:

Defina a configuração desejada de sua instância do Jenkins dentro de um arquivo de configuração declarativo (que chamaremos casc.yaml).
Copie o arquivo de configuração para a imagem Docker (assim como você fez para o seu plugins.txtarquivo).
Defina a CASC_JENKINS_CONFIGvariável de ambiente para o caminho do arquivo de configuração para instruir o plug-in Configuração como Código a lê-lo.
Primeiro, crie um novo arquivo chamado casc.yaml:

nano $HOME/jenkins/jcasc/casc.yaml
 
Em seguida, adicione as seguintes linhas:

~ / jenkins / jcasc / casc.yaml
unclassified:
  location:
    url: http://server_ip:8080/
 
unclassified.location.urlé o caminho para definir o URL do Jenkins. É apenas uma das inúmeras propriedades que podem ser definidas com o JCasC. As propriedades válidas são determinadas pelos plug-ins instalados. Por exemplo, a jenkins.authorizationStrategy.globalMatrix.permissionspropriedade só seria válida se o plugin Matrix Authorization Strategy estiver instalado. Para ver quais propriedades estão disponíveis, navegue até server_ip:8080/configuration-as-code/reference, e você encontrará uma página de documentação que é personalizada para sua instalação particular do Jenkins.

Salve o casc.yamlarquivo, saia do editor e abra o Dockerfilearquivo:

nano $HOME/jenkins/jcasc/Dockerfile
 
Adicione uma COPYinstrução ao final do seu Dockerfileque copie o casc.yamlarquivo na imagem em /var/jenkins_home/casc.yaml. Você escolheu /var/jenkins_home/porque esse é o diretório padrão onde o Jenkins armazena todos os seus dados:

~ / jenkins / jcasc / Dockerfile
FROM jenkins/jenkins:latest
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
COPY casc.yaml /var/jenkins_home/casc.yaml
 
Em seguida, adicione outra ENVinstrução que defina a CASC_JENKINS_CONFIGvariável de ambiente:

~ / jenkins / jcasc / Dockerfile
FROM jenkins/jenkins:latest
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
ENV CASC_JENKINS_CONFIG /var/jenkins_home/casc.yaml
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
COPY casc.yaml /var/jenkins_home/casc.yaml
 
Nota: você colocou a ENVinstrução perto do topo porque é algo que é improvável que você altere. Colocando-o antes das instruções COPYe RUN, você pode evitar a invalidação da camada em cache se atualizar o casc.yamlou plugins.txt.

Salve o arquivo e saia do editor. Em seguida, crie a imagem:

docker build -t jenkins:jcasc .
 
E execute a imagem atualizada do Jenkins:

docker run --name jenkins --rm -p 8080:8080 jenkins:jcasc
 
Assim que a Jenkins is fully up and runninglinha de log aparecer, navegue até server_ip:8080para visualizar o painel. Desta vez, você deve ter notado que a contagem de notificações foi reduzida em um e o aviso sobre o URL do Jenkins desapareceu.

Jenkins Dashboard mostrando o contador de notificação tem uma contagem de 1

Agora, navegue server_ip:8080/configuree role para baixo até o campo de URL do Jenkins . Confirme se o URL do Jenkins foi definido com o mesmo valor especificado no casc.yamlarquivo.

Por último, pare o processo de contêiner pressionando CTRL+C.

Nesta etapa, você usou o plug-in Configuração como código para definir a URL do Jenkins. Na próxima etapa, você tratará do segundo problema da lista de notificações (a mensagem do Jenkins no momento não é segura ).

Etapa 4 - Criação de um usuário
Até agora, sua configuração não implementou nenhum mecanismo de autenticação e autorização. Nesta etapa, você configurará um esquema de autenticação básico baseado em senha e criará um novo usuário chamado admin.

Comece abrindo seu casc.yamlarquivo:

nano $HOME/jenkins/jcasc/casc.yaml
 
Em seguida, adicione o trecho destacado:

~ / jenkins / jcasc / casc.yaml
jenkins:
  securityRealm:
    local:
      allowsSignup: false
      users:
       - id: ${JENKINS_ADMIN_ID}
         password: ${JENKINS_ADMIN_PASSWORD}
unclassified:
  ...
 
No contexto do Jenkins, um domínio de segurança é simplesmente um mecanismo de autenticação; o domínio de segurança local significa usar autenticação básica em que os usuários devem especificar seu ID / nome de usuário e senha. Outros domínios de segurança existem e são fornecidos por plug-ins. Por exemplo, o plug-in LDAP permite que você use um serviço de diretório LDAP existente como mecanismo de autenticação. O plug-in de autenticação do GitHub permite que você use suas credenciais do GitHub para autenticar via OAuth.

Observe que você também especificou allowsSignup: false, o que evita que usuários anônimos criem uma conta por meio da interface da web.

Finalmente, em vez de codificar o ID do usuário e a senha, você está usando variáveis ​​cujos valores podem ser preenchidos no tempo de execução. Isso é importante porque um dos benefícios de usar JCasC é que o casc.yamlarquivo pode ser confirmado no controle de origem; se você tivesse que armazenar senhas de usuário em texto simples dentro do arquivo de configuração, você teria efetivamente comprometido as credenciais. Em vez disso, as variáveis ​​são definidas usando a ${VARIABLE_NAME}sintaxe e seu valor pode ser preenchido usando uma variável de ambiente com o mesmo nome ou um arquivo com o mesmo nome que é colocado dentro do /run/secrets/diretório dentro da imagem do contêiner.

Em seguida, crie uma nova imagem para incorporar as alterações feitas no casc.yamlarquivo:

docker build -t jenkins:jcasc .
 
Em seguida, execute a imagem atualizada do Jenkins enquanto passa as variáveis ​​de ambiente JENKINS_ADMIN_IDe por JENKINS_ADMIN_PASSWORDmeio da --envopção (substitua <password>por uma senha de sua escolha):

docker run --name jenkins --rm -p 8080:8080 --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD=password jenkins:jcasc
 
Agora você pode acessar server_ip:8080/logine fazer login usando as credenciais especificadas.

Tela de login do Jenkins com os campos de ID de usuário e senha preenchidos

Depois de fazer o login com sucesso, você será redirecionado para o painel.

Jenkins Dashboard para usuário autenticado, mostrando a ID do usuário e um link de 'logout' próximo ao canto superior direito da página

Conclua esta etapa pressionando CTRL+Cpara parar o recipiente.

Nesta etapa, você usou JCasC para criar um novo usuário denominado admin. Você também aprendeu como manter dados confidenciais, como senhas, de arquivos rastreados por VCSs. No entanto, até agora você configurou apenas a autenticação do usuário; você não implementou nenhum mecanismo de autorização. Na próxima etapa, você usará o JCasC para conceder adminprivilégios administrativos ao usuário.

Etapa 5 - Configurando a autorização
Depois de configurar o domínio de segurança, você deve agora configurar a estratégia de autorização . Nesta etapa, você usará o plugin Matrix Authorization Strategy para configurar as permissões para o seu adminusuário.

Por padrão, a instalação principal do Jenkins nos fornece três estratégias de autorização:

unsecured: cada usuário, incluindo usuários anônimos, tem permissão total para fazer tudo
legacy: emula o Jenkins legado (anterior à v1.164), onde qualquer usuário com a função adminrecebe permissões completas, enquanto outros usuários, incluindo usuários anônimos, recebem acesso de leitura.
Observação: uma função no Jenkins pode ser um usuário (por exemplo, daniel) ou um grupo (por exemplo, developers)

loggedInUsersCanDoAnything: usuários anônimos não recebem acesso ou acesso somente leitura. Os usuários autenticados têm permissão total para fazer tudo. Ao permitir ações apenas para usuários autenticados, você pode ter uma trilha de auditoria de quais usuários realizaram quais ações.
Observação: você pode explorar outras estratégias de autorização e seus plug-ins relacionados na documentação ; isso inclui plug-ins que tratam de autenticação e autorização.

Todas essas estratégias de autorização são muito rudimentares e não permitem controle granular sobre como as permissões são definidas para diferentes usuários. Em vez disso, você pode usar o plugin Matrix Authorization Strategy que já foi incluído em sua plugins.txtlista. Este plug-in oferece uma estratégia de autorização mais granular e permite definir as permissões do usuário globalmente, bem como por projeto / trabalho.

O plugin Matrix Authorization Strategy permite que você use a jenkins.authorizationStrategy.globalMatrix.permissionspropriedade JCasC para definir permissões globais. Para usá-lo, abra seu casc.yamlarquivo:

nano $HOME/jenkins/jcasc/casc.yaml
 
E adicione o trecho destacado:

~ / jenkins / jcasc / casc.yaml
...
       - id: ${JENKINS_ADMIN_ID}
         password: ${JENKINS_ADMIN_PASSWORD}
  authorizationStrategy:
    globalMatrix:
      permissions:
        - "Overall/Administer:admin"
        - "Overall/Read:authenticated"
unclassified:
...
 
A globalMatrixpropriedade define permissões globais (em oposição às permissões por projeto). A permissionspropriedade é uma lista de strings com o formato <permission-group>/<permission-name>:<role>. Aqui, você está concedendo as Overall/Administerpermissões ao adminusuário. Você também está concedendo Overall/Readpermissões para authenticated, que é uma função especial que representa todos os usuários autenticados. Há outra função especial chamada anonymous, que agrupa todos os usuários não autenticados. Mas, como as permissões são negadas por padrão, se você não quiser conceder nenhuma permissão a usuários anônimos, não precisa incluir explicitamente uma entrada para ela.

Salve o casc.yamlarquivo, saia do editor e crie uma nova imagem:

docker build -t jenkins:jcasc .
 
Em seguida, execute a imagem atualizada do Jenkins:

docker run --name jenkins --rm -p 8080:8080 --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD=password jenkins:jcasc
 
Aguarde a Jenkins is fully up and runninglinha de log e navegue até server_ip:8080. Você será redirecionado para a página de login. Preencha suas credenciais e você será redirecionado para o painel principal.

Nesta etapa, você configurou permissões globais para seu adminusuário. No entanto, a resolução do problema de autorização revelou problemas adicionais que agora são mostrados no menu de notificação.

Jenkins Dashboard mostrando o menu de notificações com dois problemas

Portanto, na próxima etapa, você continuará a modificar sua imagem Docker, para resolver cada problema um por um até que nenhum permaneça.

Antes de continuar, pare o recipiente pressionando CTRL+C.

Etapa 6 - Configurando a autorização de compilação
O primeiro problema na lista de notificações está relacionado à autenticação do build. Por padrão, todos os trabalhos são executados como o usuário do sistema, que possui muitos privilégios de sistema. Portanto, um usuário Jenkins pode realizar escalonamento de privilégios simplesmente definindo e executando um pipeline ou trabalho malicioso; isso é inseguro.

Em vez disso, os trabalhos devem ser executados usando o mesmo usuário Jenkins que o configurou ou o acionou. Para conseguir isso, você precisa instalar um plug-in adicional denominado plug-in Autorizar Projeto .

Aberto plugins.txt:

nano $HOME/jenkins/jcasc/plugins.txt
 
E adicione a linha destacada:

~ / jenkins / jcasc / plugins.txt
ant:latest
antisamy-markup-formatter:latest
authorize-project:latest
build-timeout:latest
...
 
O plug-in fornece uma nova estratégia de autorização de construção, que você precisa especificar em sua configuração JCasC. Saia do plugins.txtarquivo e abra o casc.yamlarquivo:

nano $HOME/jenkins/jcasc/casc.yaml
 
Adicione o bloco destacado ao seu casc.yamlarquivo:

~ / jenkins / jcasc / casc.yaml
...
        - "Overall/Administer:admin"
        - "Overall/Read:authenticated"
security:
  queueItemAuthenticator:
    authenticators:
    - global:
        strategy: triggeringUsersAuthorizationStrategy
unclassified:
...
 
Salve o arquivo e saia do editor. Em seguida, crie uma nova imagem usando os arquivos plugins.txte modificados casc.yaml:

docker build -t jenkins:jcasc .
 
Em seguida, execute a imagem atualizada do Jenkins:

docker run --name jenkins --rm -p 8080:8080 --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD=password jenkins:jcasc
 
Aguarde a Jenkins is fully up and runninglinha de registro, navegue até server_ip:8080/login, preencha suas credenciais e chegue ao painel principal. Abra o menu de notificação e você verá que o problema relacionado à autenticação de compilação não aparece mais.

Menu de notificação do painel do Jenkins mostrando um único problema relacionado ao agente para o subsistema de segurança mestre sendo desativado

Pare o contêiner executando CTRL+Cantes de continuar.

Nesta etapa, você configurou o Jenkins para executar compilações usando o usuário que acionou a compilação, em vez do usuário do sistema. Isso elimina um dos problemas na lista de notificações. Na próxima etapa, você tratará do próximo problema relacionado ao Subsistema de Segurança do Agente para Controlador.

Etapa 7 - Habilitando Agente para Controle de Acesso do Controlador
Neste tutorial, você implantou apenas uma única instância do Jenkins, que executa todas as compilações. No entanto, o Jenkins oferece suporte a compilações distribuídas usando uma configuração de agente / controlador. O controlador é responsável por fornecer a IU da web, expor uma API para os clientes enviarem solicitações e coordenar as compilações. Os agentes são as instâncias que executam os jobs.

A vantagem dessa configuração é que ela é mais escalonável e tolerante a falhas. Se um dos servidores que executam o Jenkins cair, outras instâncias podem ocupar a carga extra.

No entanto, pode haver casos em que os agentes não sejam confiáveis ​​para o controlador. Por exemplo, a equipe OPS pode gerenciar o controlador Jenkins, enquanto um contratado externo gerencia seu próprio agente Jenkins com configuração personalizada. Sem o Subsistema de Segurança do Agente para o Controlador, o agente é capaz de instruir o controlador a executar quaisquer ações que ele solicitar, o que pode ser indesejável. Ao habilitar o Agente para Controle de Acesso do Controlador, você pode controlar quais comandos e arquivos os agentes têm acesso.

Para habilitar o Agente para Controle de Acesso do Controlador, abra o casc.yamlarquivo:

nano $HOME/jenkins/jcasc/casc.yaml
 
Em seguida, adicione as seguintes linhas destacadas:

~ / jenkins / jcasc / casc.yaml
...
        - "Overall/Administer:admin"
        - "Overall/Read:authenticated"
  remotingSecurity:
    enabled: true
security:
  queueItemAuthenticator:
...
 
Salve o arquivo e crie uma nova imagem:

docker build -t jenkins:jcasc .
 
Execute a imagem atualizada do Jenkins:

docker run --name jenkins --rm -p 8080:8080 --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD=password jenkins:jcasc
 
Navegue server_ip:8080/logine autentique como antes. Quando você chegar ao painel principal, o menu de notificações não mostrará mais problemas.

Painel do Jenkins sem problemas