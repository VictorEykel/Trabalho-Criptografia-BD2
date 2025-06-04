# Sistema de Autenticação com Criptografia em Oracle PL/SQL

Um sistema robusto de autenticação que implementa criptografia personalizada com base em timestamps e algoritmo de transposição matricial para segurança de senhas em Oracle Database.

## 📋 Índice

- [Características](#características)
- [Arquitetura](#arquitetura)
- [Algoritmo de Criptografia](#algoritmo-de-criptografia)
- [Estrutura do Banco de Dados](#estrutura-do-banco-de-dados)
- [Instalação](#instalação)
- [Como Usar](#como-usar)
- [Exemplos](#exemplos)
- [Segurança](#segurança)
- [Contribuições](#contribuições)

## 🚀 Características

- **Criptografia Dinâmica**: Senhas são re-criptografadas a cada acesso usando timestamps
- **Algoritmo Personalizado**: Combinação de transposição matricial, conversão ASCII e incremento temporal
- **Auditoria Completa**: Registro de todos os acessos com timestamps precisos
- **Triggers Automáticos**: Criptografia e validação automáticas
- **Validação Robusta**: Verificação de integridade de dados e usuários

## 🏗️ Arquitetura

O sistema é composto por:

- **2 Tabelas**: `LOGIN` e `ACESSO`
- **1 Sequence**: `SQ_LOGIN` para geração de IDs únicos
- **3 Triggers**: Para automação de processos
- **1 Função**: `FN_CRIPTO` para criptografia
- **1 Procedure**: `PR_ACESSO` para autenticação

## 🔐 Algoritmo de Criptografia

### Etapa 1: Transposição Matricial
A senha é distribuída em uma matriz 3x∞, alternando caracteres entre as linhas:
```
Senha: "COTEMIG123"
Linha 1: C T M G 3
Linha 2: O E I 1
Linha 3: T M G 2
```
Resultado: "CTMG3OEIG1TMG2"

### Etapa 2: Conversão ASCII
Cada caractere é convertido para seu valor ASCII com 3 dígitos:
```
C = 067, T = 084, M = 077, etc.
```

### Etapa 3: Incremento Temporal
Adiciona-se o centésimo de segundo do timestamp a cada bloco ASCII:
```
Se timestamp = XX.5 (5 centésimos)
067 + 5 = 072, 084 + 5 = 089, etc.
```

## 🗄️ Estrutura do Banco de Dados

### Tabela LOGIN
```sql
- cod_login (NUMBER, PK) - ID único do usuário
- login (VARCHAR2(30)) - Nome de usuário
- senha (VARCHAR2(150)) - Senha criptografada
```

### Tabela ACESSO
```sql
- data_hora (TIMESTAMP) - Timestamp do acesso
- cod_login (NUMBER, FK) - Referência ao usuário
```

## 📦 Instalação

1. **Pré-requisitos**
   - Oracle Database 11g ou superior
   - Privilégios para criar tabelas, sequences, triggers, functions e procedures

2. **Execução do Script**
   ```sql
   @Trabalho_Criptografia_BD2.sql
   ```

3. **Verificação da Instalação**
   ```sql
   SELECT table_name FROM user_tables WHERE table_name IN ('LOGIN', 'ACESSO');
   SELECT object_name FROM user_objects WHERE object_type = 'FUNCTION';
   ```

## 🔧 Como Usar

### Criar um Novo Usuário
```sql
INSERT INTO login (login, senha) VALUES ('usuario', 'senha123');
```

### Fazer Login
```sql
EXEC pr_acesso('usuario', 'senha123');
```

### Consultar Acessos
```sql
SELECT l.login, a.data_hora 
FROM login l 
JOIN acesso a ON l.cod_login = a.cod_login 
ORDER BY a.data_hora DESC;
```

## 📚 Exemplos

### Exemplo Completo de Uso
```sql
-- Criar usuário
INSERT INTO login (login, senha) VALUES ('pedro', 'COTEMIG123');

-- Fazer login (senha será re-criptografada)  
EXEC pr_acesso('pedro', 'COTEMIG123');

-- Verificar acessos
SELECT * FROM acesso WHERE cod_login = 1;

-- Tentar login novamente (funcionará com nova criptografia)
EXEC pr_acesso('pedro', 'COTEMIG123');
```

### Testando o Algoritmo de Criptografia
```sql
-- A função fn_cripto requer 2 parâmetros
SELECT fn_cripto(1, 'TESTE123') FROM dual;
```

## 🛡️ Segurança

### Características de Segurança
- **Senhas Nunca Armazenadas em Texto Plano**: Sempre criptografadas
- **Criptografia Dinâmica**: Mesmo senha gera hash diferente a cada acesso
- **Auditoria Completa**: Todo acesso é registrado com timestamp
- **Validação de Integridade**: Triggers impedem dados inconsistentes
- **Rollback Automático**: Em caso de erro, transações são desfeitas

### Limitações Conhecidas
- Algoritmo proprietário (não é padrão da indústria)
- Dependente de timestamps precisos do sistema
- Requer Oracle Database

## 🔄 Fluxo de Autenticação

1. **Criação de Usuário**:
   - Trigger `TG_LOGIN` gera ID sequencial
   - Senha é criptografada via `FN_CRIPTO`
   - Primeiro acesso é registrado

2. **Login**:
   - `PR_ACESSO` verifica existência do usuário
   - Decriptografa senha armazenada
   - Compara com senha fornecida
   - Se válida: registra acesso e re-criptografa senha

3. **Re-criptografia**:
   - A cada login bem-sucedido, senha é re-criptografada
   - Novo timestamp gera nova criptografia
   - Garante que hashs nunca se repetem

## 🧪 Testes

Execute os comandos de teste incluídos no script:
```sql
-- Limpar dados de teste
DELETE FROM acesso;
DELETE FROM login;

-- Criar usuário de teste
INSERT INTO login (login, senha) VALUES ('pedroTeste', 'SENHA123');

-- Testar autenticação
EXEC pr_acesso('pedroTeste', 'SENHA123');

-- Verificar logs
SELECT * FROM acesso;
SELECT * FROM login;
```

## 📈 Monitoramento

### Consultas Úteis para Monitoramento
```sql
-- Usuários mais ativos
SELECT l.login, COUNT(*) as total_acessos
FROM login l
JOIN acesso a ON l.cod_login = a.cod_login
GROUP BY l.login
ORDER BY total_acessos DESC;

-- Acessos por período
SELECT DATE(data_hora) as data, COUNT(*) as acessos
FROM acesso
GROUP BY DATE(data_hora)
ORDER BY data DESC;

-- Últimos acessos
SELECT l.login, MAX(a.data_hora) as ultimo_acesso
FROM login l
LEFT JOIN acesso a ON l.cod_login = a.cod_login
GROUP BY l.login
ORDER BY ultimo_acesso DESC;
```

## 🤝 Contribuições

Contribuições são bem-vindas! Por favor:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👥 Autores

- **Equipe de Desenvolvimento** - Projeto de Criptografia BD2

## 📞 Suporte

Para suporte e dúvidas:
- Abra uma issue no GitHub
- Consulte a documentação Oracle PL/SQL
- Verifique os logs de erro do banco de dados

---

⚠️ **Aviso**: Este é um projeto educacional. Para uso em produção, considere implementar algoritmos de criptografia padrão da indústria como bcrypt, scrypt ou Argon2.
