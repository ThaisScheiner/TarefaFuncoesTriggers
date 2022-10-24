create database bd_venda

use bd_venda

create table produto
(
	codigo			int				not null,
	nome			varchar(40)		not null,
	descricao		varchar(100)	not null,
	valorunitario   varchar(7,2)	not null	default 0
	primary key (codigo)
)

create table estoque
(
	codproduto	int				not null,
	qtdestoque	int				not null,
	estoquemin	int				not null
	primary key(codproduto)
)

create table venda
(
	notafiscal	int				not null,
	codproduto	int				not null,
	qtd			int				not null
	primary key (notafiscal)
)

-----------------------------------------------------------------------------------------------------------

create trigger tg_venda_insere_estoque
on venda
after insert
as
begin
	declare @qtdestoque int,
			@codp int,
			@qtdvenda int,
			@qtdminima int,
			@nomeproduto varchar(40)

	select @codp = codproduto
			,@qtdvenda = qtd
	from inserted

	select @qtdestoque = qtdestoque,
		   @qtdminima = estoquemin
	from estoque
	where codproduto = @codp

	if (not (@qtdvenda <= @qtdestoque))
	begin
		rollback transaction
		raiserror('não existe estoque para a realização da venda', 16,1)
	end
	else
	begin
		update estoque
		set qtdestoque = qtdestoque - @qtdvenda
		where codproduto = @codp

		select @qtdestoque = e.qtdestoque, 
			   @qtdminima = e.estoquemin,
			   @nomeproduto = p.nome
		from estoque as e, produto as p
		where e.codproduto = p.codigo and p.codigo = @codp

		if(@qtdestoque < @qtdminima)
		begin
			print 'o estoque do produto ' + @nomeproduto +' está abaixo do mínimo'
		end
	end
end

----------------------------------------------------------------------------------------------------

create function fn_notafiscal(@nota int)
returns @tab table(notafiscal int,codigoproduto int,nomeproduto varchar(40),descproduto varchar(100),valorunitario decimal(7,2),quantidade int,valortotal decimal(7,2))
as
begin
	insert into @tab 
	select 
		vd.notafiscal,
		pd.codigo as codigo_produto,
		pd.nome as nome_produto,
		pd.descricao as desc_produto,
		pd.valorunitario,
		vd.qtd as quantidade,
		pd.valorunitario * vd.qtd) as valor_total
	from venda as vd, produto as pd
	where vd.codproduto = pd.codigo and vd.notafiscal = @nota
	return		
end
