create table login (
   cod_login number primary key,
   login     varchar2(30),
   senha     varchar2(150)
);

create table acesso (
   data_hora timestamp,
   cod_login number constraint fk_login references login (cod_login)
);

create sequence sq_login;

select * from login;
select * from acesso;

create or replace trigger tg_login
before insert on login
referencing new as new
for each row
begin
   -- Atribui o próximo valor da sequence no campo cod_login
   :new.cod_login := sq_login.nextval;
   
   -- Criptografa a senha usando a função fn_cripto
   :new.senha := fn_cripto(:new.cod_login, :new.senha);

end;
/

create or replace trigger tg_login_after
after insert on login
referencing new as new
for each row
begin

   insert into acesso(data_hora, cod_login)
   values(systimestamp, :new.cod_login);

end;
/

-- TRIGGER tg_acesso REMOVIDO (tinha lógica problemática)

create or replace function fn_cripto (cod_login number, senha varchar2)
return varchar2 
as
-- Define o tipo da matriz e o tamanho de cada posição
type array_linhas is table of varchar2(1) index by pls_integer;

   -- Define as linhas 
   linha1 array_linhas;
   linha2 array_linhas;
   linha3 array_linhas;
   linha_atual number := 1;
   
   -- Define as colunas
   coluna1     number := 1;
   coluna2     number := 1;
   coluna3     number := 1;
   
   -- Declara as variáveis a serem utilizadas
   resultado1  varchar2(1000) := '';
   resultado2  varchar2(4000) := '';
   resultado3  varchar2(4000) := '';
   incremento  number := 0;
   valor_ascii number := 0;
   novo_valor  number := 0;
begin
   -- Etapa 1: Preenche as 3 linhas da matriz
   for i in 1..length(senha) loop
      case linha_atual
         when 1 then
            linha1(coluna1) := substr(senha, i, 1);
            coluna1 := coluna1 + 1;
         when 2 then
            linha2(coluna2) := substr(senha, i, 1);
            coluna2 := coluna2 + 1;
         when 3 then
            linha3(coluna3) := substr(senha, i, 1);
            coluna3 := coluna3 + 1;
      end case;

      linha_atual := linha_atual + 1;
      -- Retorna para a primeira linha caso esteja na terceira
      if linha_atual > 3 then
         linha_atual := 1;
      end if;
   end loop;

   if linha1.count > 0 then 
   -- Percorre a primeira linha da matriz e concatena o seu conteúdo ao resultado
      for x in linha1.first..linha1.last loop
         if linha1.exists(x) 
         then resultado1 := resultado1 || linha1(x); 
         end if;
      end loop;
   end if;

   if linha2.count > 0 then 
   -- Percorre a segunda linha da matriz e concatena o seu conteúdo ao resultado
      for y in linha2.first..linha2.last loop
         if linha2.exists(y) 
         then resultado1 := resultado1 || linha2(y); 
         end if;
      end loop;
   end if;

   if linha3.count > 0 then 
   -- Percorre a terceira linha da matriz e concatena o seu conteúdo ao resultado
      for z in linha3.first..linha3.last loop
         if linha3.exists(z) 
         then resultado1 := resultado1 || linha3(z);
         end if;
      end loop;
   end if;

   -- Etapa 2: Conversão para ASCII
   for i in 1..length(resultado1) loop
      resultado2 := resultado2 || lpad(ascii(substr(resultado1, i, 1)), 3, '0');
   end loop;

   -- Etapa 3: Incremento com centésimos de segundo
   
   -- Verifica se é primeiro acesso ou acesso subsequente
   select case
     when count(*) = 0 
      then to_number(to_char(systimestamp, 'FF1'))
     else 
      max(to_number(to_char(data_hora, 'FF1')))
     end 
      into incremento from acesso
     where cod_login = fn_cripto.cod_login;
   
   -- Aplica o incremento em cada bloco de 3 dígitos 
   for i in 0..(length(resultado2) / 3 - 1) loop
      valor_ascii := to_number(substr(resultado2, i * 3 + 1, 3));
      novo_valor := valor_ascii + incremento;
      resultado3 := resultado3 || lpad(novo_valor, 3, '0');
   end loop;
   
   dbms_output.put_line('Valor do incremento: ' || incremento);

   return resultado3;
end;
/

-- PROCEDURE MODIFICADA COM DECRIPTOGRAFIA INTEGRADA
create or replace procedure pr_acesso (par_login varchar2, par_senha varchar2)
as
   codLogin       number := 0;
   senha_cripto   varchar2(4000) := '';
   senha_decripto varchar2(1000) := '';
   valincremento  number := 0;
   
   -- Variáveis para decriptografia
   resultado3     varchar2(4000) := '';
   resultado2     varchar2(1000) := '';
   resultado1     varchar2(1000) := '';
   
   -- Variáveis para reorganização da matriz 
   type array_linhas is table of varchar2(1) index by pls_integer;
   linha1          array_linhas;
   linha2          array_linhas;
   linha3          array_linhas;
   tamanho_total   number := 0;
   chars_por_linha number := 0;
   valor_ascii     number := 0;
   novo_valor      number := 0;

begin
   -- Verifica se o login existe
   select count(*) into codLogin
   from login where login = par_login;

   if codLogin = 0 then
      raise_application_error(-20003, 'Login ou senha inválidos.');
   end if;

   -- Busca os dados do usuário
   select cod_login, senha into codLogin, senha_cripto
   from login where login = par_login;

   -- Busca o incremento do último acesso
   select max(to_number(to_char(data_hora, 'FF1'))) into valincremento
   from acesso where cod_login = codLogin;

   if valincremento is null then
      select max(to_number(to_char(systimestamp, 'FF1'))) into valincremento
      from dual;
   end if;

   -- INÍCIO DA DECRIPTOGRAFIA
   
   -- Etapa 3 Reversa: Remove o incremento de cada bloco de 3 dígitos
   for i in 0..(length(senha_cripto) / 3 - 1) loop
      valor_ascii := to_number(substr(senha_cripto, i * 3 + 1, 3));
      novo_valor := valor_ascii - valincremento;
      resultado3 := resultado3 || lpad(novo_valor, 3, '0');
   end loop;

   -- Etapa 2 Reversa: Converte blocos de 3 dígitos ASCII de volta para caractere
   for i in 0..(length(resultado3) / 3 - 1) loop
      valor_ascii := to_number(substr(resultado3, i * 3 + 1, 3));
      resultado2 := resultado2 || chr(valor_ascii);
   end loop;

   -- *** PARTE DE ORDENAMENTO DOS CARACTERES - DECRIPTOGRAFIA ***
   -- Etapa 1 Reversa: Reorganiza a matriz (PROCESSO INVERSO DA CRIPTOGRAFIA)
   
   -- A criptografia distribui os caracteres em 3 linhas de forma cíclica (1->2->3->1->2->3...)
   -- e depois concatena linha1 + linha2 + linha3
   -- Para reverter, precisamos separar o resultado2 de volta nas 3 linhas
   
   tamanho_total := length(resultado2);
   chars_por_linha := ceil(tamanho_total / 3);
   
   -- Calcula quantos caracteres cada linha realmente tem
   declare
      chars_linha1 number;
      chars_linha2 number;  
      chars_linha3 number;
      pos_atual number := 1;
   begin
      -- Distribui os caracteres da mesma forma que na criptografia
      chars_linha1 := ceil(tamanho_total / 3);
      chars_linha2 := case when tamanho_total > chars_linha1 then ceil((tamanho_total - chars_linha1) / 2) else 0 end;
      chars_linha3 := tamanho_total - chars_linha1 - chars_linha2;
      
      -- Reconstói as linhas a partir do resultado2 (que é linha1+linha2+linha3 concatenados)
      -- Primeira linha
      for i in 1..chars_linha1 loop
         linha1(i) := substr(resultado2, pos_atual, 1);
         pos_atual := pos_atual + 1;
      end loop;
      
      -- Segunda linha  
      for i in 1..chars_linha2 loop
         linha2(i) := substr(resultado2, pos_atual, 1);
         pos_atual := pos_atual + 1;
      end loop;
      
      -- Terceira linha
      for i in 1..chars_linha3 loop
         linha3(i) := substr(resultado2, pos_atual, 1);
         pos_atual := pos_atual + 1;
      end loop;
   end;

   -- Reconstrói a senha original intercalando as linhas (PROCESSO INVERSO)
   -- Na criptografia: caracteres vão para linha1, linha2, linha3, linha1, linha2, linha3...
   -- Na decriptografia: pegamos linha1[1], linha2[1], linha3[1], linha1[2], linha2[2], linha3[2]...
   declare
      max_chars number := greatest(nvl(linha1.count, 0), nvl(linha2.count, 0), nvl(linha3.count, 0));
   begin
      for i in 1..max_chars loop
         -- Linha 1
         if linha1.exists(i) and linha1(i) is not null then
            resultado1 := resultado1 || linha1(i);
         end if;
         
         -- Linha 2
         if linha2.exists(i) and linha2(i) is not null then
            resultado1 := resultado1 || linha2(i);
         end if;
         
         -- Linha 3
         if linha3.exists(i) and linha3(i) is not null then
            resultado1 := resultado1 || linha3(i);
         end if;
      end loop;
   end;

   senha_decripto := resultado1;
   
   -- FIM DA DECRIPTOGRAFIA
   
   -- Verifica se a senha decriptografada é igual à senha fornecida 
   if senha_decripto = par_senha then
      -- Registra o novo acesso
      insert into acesso values (systimestamp, codLogin);
      
      -- Atualiza a senha com nova criptografia
      update login set senha = fn_cripto(codLogin, par_senha)
      where cod_login = codLogin;

      dbms_output.put_line('Acesso autorizado para o usuário: ' || par_login || '. Senha atualizada com sucesso.');
      dbms_output.put_line('Valor do incremento: ' || valincremento  );
   else
      raise_application_error(-20001, 'Login ou senha inválidos. ' || par_senha || ' != ' || senha_decripto);
   end if;

exception
   when others then
      rollback;
      raise_application_error(-20002, 'Erro durante a validação: ' || sqlerrm);
end;
/

-- 074076078058086084056091080057
-- 075077079059087085057092081058

-- 067069071051079077049084073050
-- 072074076056084082054089078055

-- Teste da procedure
EXEC pr_acesso('pedro', 'COTEMIG123');

-- Inserção de dados de teste
insert into login (login, senha) values ('pedro', 'COTEMIG123');

-- Consultas para verificação
select * from acesso;
select * from login;
delete from acesso;
delete from login;

-- Comandos de limpeza (comentados para segurança)
-- delete from acesso;
-- delete from login;