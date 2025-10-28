# Criar arquivo README.md
cat > README.md << 'EOF'
# Sistema CRUD de Cadastro de Pessoas

##  Descrição
Sistema de gerenciamento de pessoas desenvolvido em Swift como avaliação prática de Pós-Graduação.

##  Funcionalidades
-  **CREATE**: Cadastrar nova pessoa com validações
-  **READ**: Buscar e exibir uma ou todas as pessoas
-  **UPDATE**: Alterar dados de pessoa existente
-  **DELETE**: Remover pessoa com confirmação

##  Estrutura de Dados
```swift
// Dicionário conforme especificação
var pessoas: [String: [String]] = [:]
// Chave: nome (String)
// Valor: [email, telefone, idade]
```

##  Recursos Adicionais
- Validação de email (regex)
- Validação de celular (mínimo 10 dígitos)
- Busca inteligente por fragmento de nome
- Interface colorida com tabelas profissionais
- Persistência automática em JSON
- Normalização de dados
