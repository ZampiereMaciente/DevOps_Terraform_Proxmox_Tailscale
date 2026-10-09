# Proxmox LXC com Terraform e Tailscale

Este projeto mostra como automatizei a criação de containers LXC em um
homelab com Proxmox VE. O Terraform roda na minha máquina de gerenciamento,
conecta-se à API do Proxmox pela rede privada do Tailscale e clona containers
a partir de um template Debian já existente.

A configuração de exemplo cria dois containers:

| Container | Uso demonstrativo | CPU | Memória |
| --- | --- | ---: | ---: |
| `debian-app` | Aplicação | 1 core | 512 MB |
| `debian-db` | Banco de dados | 2 cores | 1024 MB |

Os nomes e recursos são exemplos. Adapte-os ao seu Proxmox, template e
necessidades.

## Como a conexão funciona

```text
Máquina com Terraform e Tailscale
              |
              | Tailnet privada / HTTPS / API do Proxmox
              v
     Proxmox VE no homelab
              |
              v
       Template LXC Debian
              |
       +------+------+
       |             |
    debian-app    debian-db
```

O Tailscale fornece a conectividade privada entre a máquina que executa o
Terraform e o Proxmox. O Terraform autentica separadamente na API do Proxmox
usando um API token. Estar conectado ao tailnet, por si só, não concede acesso à
API: o usuário/token do Proxmox também precisa ter as permissões necessárias.

## O que foi configurado

1. Preparei um host com Proxmox VE para o homelab e criei nele um template LXC
   Debian. O nome informado ao Terraform deve corresponder exatamente ao nome do
   template configurado no Proxmox.
2. Instalei e autentiquei o Tailscale no Proxmox e na máquina de onde executo o
   Terraform. Assim, consigo acessar a rede do homelab sem expor a API do
   Proxmox diretamente à Internet.
3. Criei um API token no Proxmox para a automação. Conceda apenas as
   permissões necessárias para clonar o template e criar/gerenciar os
   containers e seus recursos.
4. Configurei o provider `telmate/proxmox` e passei endpoint, token e nó por
   variáveis Terraform.
5. Criei o módulo `modules/proxmox_lxc` para descrever um container LXC e
   chamei-o duas vezes a partir do `main.tf`, com nomes e recursos diferentes.
6. Usei `terraform plan` para revisar as mudanças antes de criá-las com
   `terraform apply`.

O Tailscale pode ser instalado seguindo as instruções oficiais para o sistema
operacional do Proxmox e da máquina de gerenciamento. Depois da instalação,
confirme que ambos aparecem conectados ao mesmo tailnet. Use no endpoint da API
o endereço Tailscale ou o nome MagicDNS do Proxmox, por exemplo:

```text
https://<IP-TAILSCALE-OU-MAGICDNS-DO-PROXMOX>:8006/api2/json
```

O acesso também depende das ACLs do Tailscale e do firewall do Proxmox
permitirem a conexão à porta `8006` a partir da máquina de gerenciamento.
Não é necessário nem recomendado publicar essa porta na Internet para seguir
este exemplo.

## Estrutura do projeto

```text
.
├── main.tf                       # Provider Proxmox e dois módulos LXC
├── variables.tf                  # Endpoint, token e nó do Proxmox
├── outputs.tf                    # IDs dos containers criados
├── .terraform.lock.hcl           # Versões e checksums dos providers
├── .pre-commit-config.yaml       # Hooks de formatação e validação Terraform
└── modules/
    └── proxmox_lxc/
        ├── main.tf               # Recurso proxmox_lxc
        ├── variables.tf          # Parâmetros do container
        └── outputs.tf            # ID do container
```

O módulo utiliza `local-lvm` como storage, `vmbr0` como bridge, DHCP e um disco
raiz de `8G`. Esses valores estão definidos em
`modules/proxmox_lxc/main.tf`; se sua instalação usar nomes diferentes, ajuste
o módulo antes de aplicar.

O provider está fixado na versão `telmate/proxmox` `3.0.2-rc10`, conforme a
configuração atual do projeto. É uma versão release candidate; considere isso
ao adaptar o exemplo para ambientes importantes.

## Requisitos

- Um Proxmox VE configurado e acessível pelo tailnet.
- Tailscale instalado e conectado na máquina de gerenciamento e no Proxmox.
- Um template LXC disponível no nó de destino.
- Um API token Proxmox com permissões adequadas.
- Terraform `>= 1.5.0`.

## Configuração local

Depois de clonar este repositório, crie `terraform.tfvars` na raiz. Esse arquivo
é local e não deve ser enviado ao Git, pois contém credenciais e dados do seu
ambiente.

Exemplo de conteúdo:

```hcl
proxmox_api_url          = "https://<IP-TAILSCALE-OU-MAGICDNS>:8006/api2/json"
proxmox_api_token_id     = "usuario@pam!terraform"
proxmox_api_token_secret = "COLOQUE_O_SECRET_DO_SEU_TOKEN_AQUI"
proxmox_node             = "NOME_DO_NO_PROXMOX"
```

Substitua os valores ilustrativos pelos dados da sua instalação:

- `proxmox_api_url`: endereço Tailscale/MagicDNS do Proxmox e endpoint da API.
- `proxmox_api_token_id`: ID do token, no formato esperado pelo Proxmox.
- `proxmox_api_token_secret`: secret gerado ao criar o token.
- `proxmox_node`: nome exato do nó Proxmox de destino.

O template, hostname, CPU e memória dos dois containers são configurados nos
blocos de módulo em `main.tf`. O exemplo usa `Template-Container-Debian` como
nome do template; altere-o para o nome exato existente no seu Proxmox.

## Arquivos que não devem ser commitados

O `.gitignore` já ignora arquivos `*.tfvars`, state do Terraform, o diretório
`.terraform/` e arquivos locais de log. Um exemplo de arquivos que ficam somente
na sua máquina:

```text
terraform.tfvars          # endpoint, token e nome do nó do seu Proxmox
terraform.tfstate         # estado dos recursos gerenciados pelo Terraform
terraform.tfstate.backup  # backup local do estado
.terraform/               # plugins baixados e dados de inicialização
```

O state pode conter informações sensíveis. Não o publique, mesmo que o token
esteja em outro arquivo. Antes de criar um commit, confira:

```bash
git status --short
git check-ignore -v terraform.tfvars terraform.tfstate
```

Um arquivo `terraform.tfvars.example` com placeholders pode ser versionado
como referência, desde que não contenha IPs, nomes internos, tokens ou secrets
reais. Cada pessoa copia esse modelo para `terraform.tfvars` e preenche os
próprios valores.

O arquivo `.terraform.lock.hcl`, ao contrário do state, deve permanecer
versionado para registrar a seleção do provider. O `.pre-commit-config.yaml`
também é parte do projeto: ele configura os hooks compartilhados e não deve
conter credenciais.

## Executar o Terraform

Execute os comandos na raiz do repositório, onde estão `main.tf` e
`terraform.tfvars`:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

- `terraform init`: inicializa o projeto e baixa o provider necessário.
- `terraform fmt -recursive`: formata os arquivos Terraform, incluindo o módulo.
- `terraform validate`: verifica a sintaxe e a consistência da configuração.
- `terraform plan`: mostra o que será criado, alterado ou removido.

Revise o plano e confirme que ele aponta para o nó, template e containers
esperados. Para criar os recursos:

```bash
terraform apply
```

O Terraform solicitará confirmação. Esse comando aplica as alterações
aprovadas e cria ou atualiza os recursos no Proxmox.

Para remover os recursos gerenciados por esta configuração, revise
cuidadosamente e execute:

```bash
terraform destroy
```

Esse comando destrói os recursos gerenciados por esta configuração no Proxmox.
Confira o que será removido antes de confirmar.

## Configurar o pre-commit e os hooks

O projeto inclui `.pre-commit-config.yaml`, que configura dois hooks para os
arquivos Terraform:

- `terraform_fmt`: formata os arquivos Terraform antes do commit.
- `terraform_validate`: valida a configuração Terraform.

Instale o `pre-commit`. No macOS, você pode usar o Homebrew:

```bash
brew install pre-commit
```

Ou instale-o com `pipx`:

```bash
pipx install pre-commit
```

Confirme que o Terraform também está instalado e disponível no `PATH`. Na raiz
do repositório, onde está `.pre-commit-config.yaml`, instale o hook do Git:

```bash
pre-commit install
```

A partir daí, ao executar `git commit`, os hooks serão executados
automaticamente. Se algum hook falhar, o commit será interrompido. O hook de
formatação pode alterar os arquivos; revise as mudanças, adicione-as ao commit
e tente novamente.

Para executar os hooks manualmente em todos os arquivos:

```bash
pre-commit run --all-files
```

O comando `pre-commit install` configura o hook local em `.git/hooks/`; cada
pessoa que clonar o repositório precisa executá-lo uma vez. Esse hook local não
é commitado. Já `.pre-commit-config.yaml` deve ser mantido no Git para que todos
usem as mesmas verificações.
