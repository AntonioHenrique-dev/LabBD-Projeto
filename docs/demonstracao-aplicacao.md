# Aplicação web: demonstração e tecnologias

## Preparação

1. Recriar o banco limpo: executar os scripts de `01` a `06` e depois o `90_dados_exemplo.sql`, para que os dados de exemplo fiquem na situação esperada pelo roteiro.
2. Iniciar a aplicação (`cd app`, `npm start`) e abrir http://localhost:3000.
3. Abrir um terminal do MySQL conectado como `app_condominio`, para a verificação de permissões (passo 5).

Nos dados de exemplo, a Fernanda Gomes já está dentro do condomínio, o Lucas Martins já entrou e saiu, e o Pedro Santos **não** foi autorizado pelo morador.

## Roteiro

| Passo | Ação | Explicação |
| --- | --- | --- |
| 1 | Mostrar o canto superior direito: `usuário app_condominio@localhost` | "A aplicação acessa o banco com um usuário próprio, nunca com root. Se alguém configurar root, ela nem inicia." |
| 2 | Mostrar "Visitantes presentes" e "Encomendas pendentes" | "Essas duas tabelas vêm direto das views `vw_visitantes_presentes` e `vw_encomendas_pendentes`. A aplicação só faz `SELECT` nelas." |
| 3 | Escolher **Pedro Santos** e clicar em Registrar entrada | "O morador não autorizou, então a procedure recusa, faz ROLLBACK, e nada é gravado." A mensagem de erro aparece em vermelho. |
| 4 | Escolher **Lucas Martins**, clicar em Registrar entrada e depois em Registrar saída | "Agora a procedure valida, grava e faz COMMIT. O ID `ACS-2026-...` foi gerado pela nossa função `fn_gerar_id`." Mostrar a nova linha em "Últimas movimentações" e o Lucas entrando e saindo da lista de presentes. |
| 5 | No terminal, como `app_condominio`: `INSERT INTO acessos (visitante_id, tipo, registrado_por_id) VALUES (3, 'ENTRADA', 1);` | Dá `INSERT command denied`. "A aplicação não consegue gravar acessos direto na tabela: só pela procedure, que aplica as regras." |

Também é possível mostrar `SELECT * FROM sequencias_id;`, que é negado: o usuário da aplicação não consegue alterar a numeração dos IDs.

## Tecnologias utilizadas

| Tecnologia | Uso | Justificativa |
| --- | --- | --- |
| MySQL 8.0 | Banco de dados relacional | SGBD exigido pelo trabalho. A versão 8.0 aplica restrições `CHECK` e aceita vários triggers no mesmo evento, o que foi usado no projeto. |
| Node.js + Express | API (servidor) | Servidor HTTP leve, com poucas linhas para expor as rotas. A lógica de negócio fica no banco (procedures, triggers e views), então a API só repassa as chamadas e não precisa de um framework maior. |
| mysql2 | Driver de conexão | Suporta consultas parametrizadas (`?`), que impedem SQL injection, e chamadas a stored procedures (`CALL`). Usa pool de conexões. |
| HTML, CSS e JavaScript | Página web | Atende ao requisito de exibição sem etapa de compilação. A página consome a API com `fetch` e se adapta a celular e ao tema escuro. |
| dotenv | Configuração | As credenciais do banco ficam no arquivo `.env`, fora do código e fora do Git (`.gitignore`). |

**Segurança da conexão:** a aplicação usa o usuário `app_condominio`, que só tem `SELECT`, `INSERT` e `UPDATE` nas tabelas operacionais, `SELECT` nas views e `EXECUTE` nas procedures e funções necessárias. Ela não tem `DELETE`, não acessa `sequencias_id` e não grava em `acessos` diretamente. Ao iniciar, a aplicação confere com `SELECT CURRENT_USER()` qual conta foi autenticada e encerra se for root.

## Comandos para rodar um por vez (MySQL)

Os comandos são executados com `admin_condominio`, depois do `99_demonstracao.sql`, um de cada vez (no Workbench, Ctrl+Enter com o cursor no comando).

**Triggers: os dois comandos devem dar erro.** O primeiro tenta reservar o salão num horário que já está reservado em 20/11. O segundo tenta registrar a entrada do Pedro Santos, que o morador não autorizou.

```sql
INSERT INTO reservas (area_id, morador_id, data, hora_inicio, hora_fim)
VALUES (1, 2, '2026-11-20', '19:00', '21:00');

INSERT INTO acessos (visitante_id, tipo, registrado_por_id)
VALUES (3, 'ENTRADA', 1);
```

**Trigger: a data de retirada é preenchida automaticamente.**

```sql
UPDATE encomendas SET retirada = TRUE WHERE id = 'ENC-2026-000002-1';
SELECT retirada, data_retirada FROM encomendas WHERE id = 'ENC-2026-000002-1';
```

**Procedures com COMMIT e ROLLBACK.** Na ordem:

1. Entrada do Lucas: a procedure grava e confirma, e ele aparece em `vw_visitantes_presentes`.
2. Saída do Lucas: ele sai da view.
3. Entrada do Pedro, que não foi autorizado: dá erro, a procedure faz ROLLBACK e nada é gravado em `acessos`.
4. Retirada de encomenda pelo destinatário (Carlos, morador 1).

```sql
CALL sp_registrar_entrada(2, 1);
CALL sp_registrar_saida(2, 1);
CALL sp_registrar_entrada(3, 1);
CALL sp_registrar_retirada_encomenda('ENC-2026-000001-3', 1);
```

**Controle de acesso.** `SHOW GRANTS` mostra os privilégios de quem está conectado. Conectado como `consulta_condominio`, a primeira consulta abaixo funciona e a segunda é negada:

```sql
SHOW GRANTS;
SELECT * FROM vw_encomendas_pendentes;
SELECT * FROM encomendas;
```

Conectado como `app_condominio`, esta consulta é negada:

```sql
SELECT * FROM sequencias_id;
```

**Restrições: cada comando deve dar erro.** Na ordem: placa repetida, reserva que termina antes de começar, código de encomenda com dígito verificador errado e exclusão de unidade que ainda tem vínculos.

```sql
INSERT INTO veiculos (placa, modelo, morador_id) VALUES ('ABC1D23', 'Gol', 3);

INSERT INTO reservas (area_id, morador_id, data, hora_inicio, hora_fim)
VALUES (1, 1, '2026-12-01', '20:00', '18:00');

INSERT INTO encomendas (id, descricao, destinatario_id, unidade_id, recebida_por_id)
VALUES ('ENC-2026-000099-1', 'x', 1, 1, 1);

DELETE FROM unidades WHERE id = 1;
```

Para voltar os dados ao estado inicial depois da demonstração, basta executar novamente os scripts de `01` a `06` e o `90`.
