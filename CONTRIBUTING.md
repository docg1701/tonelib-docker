# Contribuindo para tonelib-docker

Obrigado por considerar contribuir! 🎸

## Como Contribuir

### Reportar Bugs

Encontrou um problema? Abra uma [issue](https://github.com/SEU_USUARIO/tonelib-docker/issues) com:

- **Descrição clara** do problema
- **Passos para reproduzir**
- **Comportamento esperado** vs **comportamento atual**
- **Ambiente:** Distro Linux, versão do Docker, versão do ToneLib-GFX
- **Logs/screenshots** se aplicável

### Sugerir Melhorias

Tem uma ideia? Abra uma issue com tag `enhancement` descrevendo:

- O problema que você quer resolver
- Sua solução proposta
- Alternativas que você considerou

### Testar em Outras Distros

Testou em uma distro não listada no README? Por favor:

1. Fork o repositório
2. Adicione sua distro na seção "Testado em:" do README.md
3. Envie um Pull Request

Exemplo:
```markdown
- [x] Linux Mint 21.3 (Cinnamon)
- [x] Ubuntu 22.04 ← Adicione aqui
```

### Melhorias de Código

1. **Fork** o repositório
2. **Clone** seu fork
3. **Crie um branch** para sua feature: `git checkout -b minha-feature`
4. **Faça suas alterações**
5. **Teste** localmente
6. **Commit** com mensagem clara: `git commit -m "Adiciona suporte para X"`
7. **Push**: `git push origin minha-feature`
8. Abra um **Pull Request**

### Diretrizes de Código

#### Dockerfile
- Mantenha camadas otimizadas (minimize número de layers)
- Comente alterações não óbvias
- Minimize tamanho da imagem

#### Scripts (run.sh, install-desktop.sh)
- Use `#!/bin/bash` no shebang
- Adicione `set -e` para falhar em erros
- Mensagens de erro claras
- Comente lógica complexa

#### compose.yml
- Mantenha formatação consistente (2 espaços)
- Comente configurações não padrão
- Valide com: `docker compose config`

### Testes

Antes de enviar PR, teste:

```bash
# Limpar ambiente
docker compose down
docker rmi tonelib-gfx:latest
docker volume rm tonelib-docker_tonelib-config tonelib-docker_tonelib-data

# Build limpo
docker compose build --no-cache

# Testar execução
./run.sh

# Testar instalação do ícone
./install-desktop.sh
```

Verifique:
- ✅ Aplicativo abre corretamente
- ✅ Interface gráfica sem corrupção
- ✅ Áudio funciona
- ✅ Configurações persistem entre execuções

### Documentação

Atualizações no README são muito bem-vindas! Especialmente:

- Correções de typos
- Clarificações
- Exemplos adicionais
- Traduções

### O Que NÃO Fazer

❌ **NÃO inclua o arquivo .deb no repositório**
- Por questões de licenciamento, o ToneLib-GFX.deb não pode ser distribuído aqui

❌ **NÃO modifique o binário do ToneLib-GFX**
- Este projeto apenas facilita a execução, não modifica o software

❌ **NÃO adicione dependências desnecessárias**
- Mantenha a imagem leve

## Código de Conduta

- Seja respeitoso e construtivo
- Foque no problema, não na pessoa
- Aceite críticas construtivas
- Ajude outros contribuidores

## Dúvidas?

Abra uma issue com tag `question` ou entre em contato!

## Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a Licença MIT.

---

**Obrigado por ajudar a melhorar este projeto!** 🚀
