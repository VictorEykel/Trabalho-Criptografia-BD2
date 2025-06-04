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

create or replace trigger tg_login
before insert on login
referencing new as new
for each row
begin
   -- Atribui o próximo valor da sequence no campo cod_login
   :new.cod_login := sq_login.nextval;
   
   -- Criptografa a senha usando a função fn_cripto
   :new.senha := fn_cripto(:new.cod_login, :new.senha);

   -- Insere o registro de acesso com a data e hora atual
   insert into acesso(data_hora, cod_login)
   values(systimestamp, :new.cod_login);

end;
/

create or REPLACE trigger tg_acesso
before insert on acesso
referencing new as new
for each row
declare
   val_login VARCHAR2(1000) := '';
   val_senha VARCHAR2(1000) := '';
   senha_decripto VARCHAR2(1000) := '';
begin
   SELECT login, senha into val_login, val_senha
   from login
   where cod_login = :new.cod_login;

   if val_login is not null and val_senha is not null then
      -- Acesso permitido, nada a fazer
      insert into acesso(data_hora, cod_login)
      values(systimestamp, :new.cod_login);

      update login set senha = fn_cripto(val_login, val_senha)
      where cod_login = val_login;
   else
      -- Acesso negado, lança erro
      raise_application_error(-20001, 'Login ou senha inválidos.');
   end if;
end;
/

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

   -- Percorre a primeira linha da matriz e concatena o seu conteúdo ao resultado
   for x in linha1.first..linha1.last loop
      if linha1.exists(x) 
       then resultado1 := resultado1 || linha1(x); 
      end if;
   end loop;

   -- Percorre a segunda linha da matriz e concatena o seu conteúdo ao resultado
   for y in linha2.first..linha2.last loop
      if linha2.exists(y) 
       then resultado1 := resultado1 || linha2(y); 
      end if;
   end loop;

   -- Percorre a terceira linha da matriz e concatena o seu conteúdo ao resultado
   for z in linha3.first..linha3.last loop
      if linha3.exists(z) 
       then resultado1 := resultado1 || linha3(z);
      end if;
   end loop;

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
   for i in 0..(trunc(length(resultado2) / 3) - 1) loop
      valor_ascii := to_number(substr(resultado2, i * 3 + 1, 3));
      novo_valor := valor_ascii + incremento;
      resultado3 := resultado3 || lpad(novo_valor, 3, '0');
   end loop;

   return resultado3;
end;
/

create or replace function fn_decripto(par_login VARCHAR2, par_senha VARCHAR2)
return varchar2
as
   codLogin       number := 0;
   senha_cripto    varchar2(4000) := '';
   senha_decripto  varchar2(1000) := '';
   valincremento   number := 0;
   resultado3      varchar2(4000) := '';
   resultado2      varchar2(1000) := '';
   resultado1      varchar2(1000) := '';
   
   -- Variáveis para reorganização da matriz 
   type array_linhas is table of varchar2(1) index by pls_integer;
   linha1          array_linhas;
   linha2          array_linhas;
   linha3          array_linhas;
   tamanho_total   number := 0;
   chars_por_linha number := 0;
   linha_atual     number := 1;
   coluna1         number := 1;
   coluna2         number := 1;
   coluna3         number := 1;
   valor_ascii     number := 0;
   novo_valor      number := 0;
   char_atual      varchar2(1) := '';

begin
   select count(*) into codLogin
   from login where login = par_login;

   -- Verifica se o login existe
   if codLogin = 0 
    then raise_application_error(-20001, 'Login ou senha inválidos.');
   end if;

   -- Busca os dados do usuário
   select cod_login, senha into codLogin, senha_cripto
   from login where login = par_login;

   -- Busca o incremento do último acesso
   select max(to_number(to_char(data_hora, 'FF1'))) into valincremento
   from acesso where cod_login = codLogin;

   if valincremento is null then
      valincremento := 0;
   end if;

   -- Decriptografia Etapa 3 Reversa
   -- Remove o incremento de cada bloco de 3 dígitos
   for i in 0..(trunc(length(senha_cripto) / 3) - 1) loop
      valor_ascii := to_number(substr(senha_cripto, i * 3 + 1, 3));
      novo_valor := valor_ascii - valincremento;
      resultado3 := resultado3 || lpad(novo_valor, 3, '0');
   end loop;

   -- Decriptografia Etapa 2 Reversa
   -- Converte blocos de 3 dígitos ASCII de volta para caractere
   for i in 0..(trunc(length(resultado3) / 3) - 1) loop
      valor_ascii := to_number(substr(resultado3, i * 3 + 1, 3));
      resultado2 := resultado2 || chr(valor_ascii);
   end loop;

   -- Decriptografia Etapa 1 Reversa
   tamanho_total := length(resultado2);
   chars_por_linha := ceil(tamanho_total / 3);
   
   -- Preenche as linhas da matriz
   
   for i in 1..chars_por_linha loop
      if i <= length(resultado2) then
         linha1(i) := substr(resultado2, i, 1);
      end if;
   end loop;

   for i in 1..chars_por_linha loop
      if (chars_por_linha + i) <= length(resultado2) then
         linha2(i) := substr(resultado2, chars_por_linha + i, 1);
      end if;
   end loop;

   for i in 1..chars_por_linha loop
      if (2 * chars_por_linha + i) <= length(resultado2) then
         linha3(i) := substr(resultado2, 2 * chars_por_linha + i, 1);
      end if;
   end loop;

   -- Reconstrói a senha original alternando entre as linhas
   for i in 1..chars_por_linha loop
      -- Linha 1
      if linha1.exists(i) and linha1(i) is not null
       then resultado1 := resultado1 || linha1(i);
      end if;
      
      -- Linha 2
      if linha2.exists(i) and linha2(i) is not null 
       then resultado1 := resultado1 || linha2(i);
      end if;
      
      -- Linha 3
      if linha3.exists(i) and linha3(i) is not null 
       then resultado1 := resultado1 || linha3(i);
      end if;
   end loop;

   senha_decripto := resultado1;
   
   -- Verifica se a senha decriptografada é igual à senha fornecida 
   if senha_decripto = par_senha
   then
      -- Registra o novo acesso
      insert into acesso values (systimestamp, codLogin);
      
      -- Atribui uma nova senha criptografada
      update login set senha = fn_cripto(codLogin, par_senha)
      where cod_login = codLogin;

      dbms_output.put_line('Acesso autorizado para o usuário: ' || par_login || '. Senha atualizada com sucesso.');
   else
      raise_application_error(-20001, 'Login ou senha inválidos.');
   end if;

   exception
   when others then
    rollback;
    raise_application_error(-20002, 'Erro durante a validação: ' || sqlerrm);
   

end;
/

create or replace procedure pr_acesso (par_login varchar2, par_senha varchar2)
as
   codLogin       number := 0;
   senha_cripto    varchar2(4000) := '';
   senha_decripto  varchar2(1000) := '';
   valincremento   number := 0;

begin
   select count(*) into codLogin
   from login where login = par_login;

   -- Verifica se o login existe
   if codLogin = 0 
    then raise_application_error(-20001, 'Login ou senha inválidos.');
   end if;

   senha_decripto := fn_decripto(par_login, par_senha);
   
   -- Busca os dados do usuário
   select cod_login, senha into codLogin, senha_cripto
   from login where login = par_login;

   -- Busca o incremento do último acesso
   select max(to_number(to_char(data_hora, 'FF1'))) into valincremento
   from acesso where cod_login = codLogin;

   if valincremento is null then
      valincremento := 0;
   end if;

   
   -- Verifica se a senha decriptografada é igual à senha fornecida 
   if senha_decripto = par_senha
   then
      -- Registra o novo acesso
      insert into acesso values (systimestamp, codLogin);
      
      -- Atribui uma nova senha criptografada
      update login set senha = fn_cripto(codLogin, par_senha)
      where cod_login = codLogin;

      dbms_output.put_line('Acesso autorizado para o usuário: ' || par_login || '. Senha atualizada com sucesso.');
   else
      raise_application_error(-20001, 'Login ou senha inválidos.');
   end if;

   exception
   when others then
    rollback;
    raise_application_error(-20002, 'Erro durante a validação: ' || sqlerrm);
end;
/

EXEC pr_acesso('pedro', 'COTEMIG123');

insert into login (login, senha) values ('pedro', 'COTEMIG123');



select * from acesso;
delete from acesso;

select * from login;
delete from login;

