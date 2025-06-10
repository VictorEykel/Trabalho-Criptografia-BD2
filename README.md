# Sistema de Criptografia em Oracle PL/SQL

Um sistema de autenticação com criptografia personalizada implementado em Oracle Database usando PL/SQL, desenvolvido como trabalho acadêmico de Banco de Dados.

## 📋 Descrição

Este projeto implementa um sistema de login seguro com algoritmo de criptografia personalizado que combina:
- Reorganização matricial de caracteres
- Conversão para códigos ASCII
- Incremento baseado em timestamp
- Decriptografia integrada para validação

## 🏗️ Estrutura do Banco de Dados

### Tabelas

**`login`**
- `cod_login` (NUMBER, PK): Código único do usuário
- `login` (VARCHAR2(30)): Nome de usuário
- `senha` (VARCHAR2(150)): Senha criptografada

**`acesso`**
- `data_hora` (TIMESTAMP): Data e hora do acesso
- `cod_login` (NUMBER, FK): Referência ao usuário

### Objetos PL/SQL

- **Sequence**: `sq_login` - Geração automática de códigos
- **Triggers**: 
  - `tg_login` - Criptografia automática na inserção
  - `tg_login_after` - Registro de acesso pós-inserção
- **Function**: `fn_cripto` - Algoritmo de criptografia
- **Procedure**: `pr_acesso` - Validação de login com decriptografia

## 🔐 Algoritmo de Criptografia

### Etapa 1: Reorganização Matricial
Os caracteres da senha são distribuídos ciclicamente em 3 linhas:
```
Senha: "EXEMPLO"
Linha 1: E X M
Linha 2: X E P  
Linha 3: E L O
Resultado: EXMXEPELO
```

### Etapa 2: Conversão ASCII
Cada caractere é convertido para seu código ASCII com 3 dígitos:
```
E = 069, X = 088, M = 077...
Resultado: 069088077088069080069076079
```

### Etapa 3: Incremento Temporal
Adiciona incremento baseado nos centésimos de segundo do timestamp:
```
Incremento = 5
069 + 5 = 074, 088 + 5 = 093...
Resultado Final: 074093082093074085074081084
```

## 🚀 Como Usar

### 1. Configuração Inicial
```sql
-- Execute o script completo para criar todas as estruturas
@Trabalho_Criptografia_BD2.sql
```

### 2. Criando um Usuário
```sql
INSERT INTO login (login, senha) VALUES ('usuario', 'minha_senha');
```
*A criptografia é aplicada automaticamente via trigger*

### 3. Fazendo Login
```sql
EXEC pr_acesso('usuario', 'minha_senha');
```

### 4. Consultando Dados
```sql
-- Ver usuários cadastrados
SELECT cod_login, login, senha FROM login;

-- Ver histórico de acessos
SELECT * FROM acesso ORDER BY data_hora DESC;
```

## ⚡ Funcionalidades

- **Criptografia Automática**: Senhas são criptografadas automaticamente na inserção
- **Validação Segura**: Login realizado através de decriptografia e comparação
- **Atualização Dinâmica**: Senha é recriptografada a cada acesso válido
- **Auditoria**: Todos os acessos são registrados com timestamp
- **Incremento Temporal**: Cada criptografia é única baseada no tempo de acesso

## 🛠️ Tecnologias Utilizadas

- **Oracle Database** (11g ou superior)
- **PL/SQL** para lógica de negócio
- **Triggers** para automação
- **Sequences** para chaves primárias
- **Functions/Procedures** para processamento

## 📁 Arquivos do Projeto

- `Trabalho_Criptografia_BD2.sql` - Script completo com DDL e DML
- `README.md` - Documentação do projeto

## 🔍 Exemplo de Uso

```sql
-- 1. Criar usuário
INSERT INTO login (login, senha) VALUES ('pedro', 'COTEMIG123');

-- 2. Fazer login
EXEC pr_acesso('pedro', 'COTEMIG123');
-- Output: "Acesso autorizado para o usuário: pedro. Senha atualizada com sucesso."

-- 3. Verificar dados
SELECT * FROM login;
SELECT * FROM acesso;
```

## ⚠️ Observações Importantes

- A senha é recriptografada a cada acesso válido
- O incremento temporal garante que a mesma senha nunca gere o mesmo hash
- Sistema projetado para fins acadêmicos e demonstração de conceitos
- Para produção, recomenda-se usar algoritmos de hash padrão (SHA-256, bcrypt, etc.)

## 🎓 Contexto Acadêmico

Este projeto foi desenvolvido como trabalho acadêmico para demonstrar:
- Conhecimentos em PL/SQL e Oracle Database
- Implementação de algoritmos de criptografia customizados
- Uso de triggers, procedures e functions
- Boas práticas em segurança de dados (conceitual)

## 📝 Licença

Este projeto é destinado para fins educacionais e acadêmicos.

---

*Desenvolvido como trabalho de Banco de Dados - Criptografia em PL/SQL*
