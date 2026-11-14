# Sistema de Gestão de Condomínio (MySQL 8.0 + aplicação web)

## Criação do banco

Os scripts devem ser executados **nesta ordem**. Apenas o `00` usa uma conta administrativa do servidor (root), uma única vez por instalação. Os demais são executados com `admin_condominio`, a aplicação usa `app_condominio` e os relatórios podem usar `consulta_condominio`.

| Ordem | Script | Executar com | Conteúdo |
| --- | --- | --- | --- |
| 0 | `sql/00_preparar_servidor.sql` | root (uma vez) | Cria o banco `condominio` e o usuário `admin_condominio` |
| 1 | `sql/01_tabelas.sql` | admin_condominio | 14 tabelas + `sequencias_id`, chaves, `CHECK`s e os 4 grupos de usuários |
| 2 | `sql/02_indices.sql` | admin_condominio | 7 índices de consulta |
| 3 | `sql/03_geracao_ids.sql` | admin_condominio | 4 funções de geração de ID + 4 triggers que aplicam a regra |
| 4 | `sql/03_triggers.sql` | admin_condominio | Triggers de regras de negócio |
| 5 | `sql/04_views.sql` | admin_condominio | Views de visitantes presentes e encomendas pendentes |
| 6 | `sql/05_procedures_functions.sql` | admin_condominio | Procedures, function e controle de transação (COMMIT/ROLLBACK) |
| 7 | `sql/06_usuarios_permissoes.sql` | admin_condominio | Usuários do MySQL e `GRANT`s |
| 90 | `sql/90_dados_exemplo.sql` | admin_condominio | Dados de teste (por último, com todas as regras ativas) |
| 99 | `sql/99_demonstracao.sql` | admin_condominio | Consultas de demonstração (não altera dados) |

Pelo terminal:

```
mysql -u root -p < sql/00_preparar_servidor.sql
mysql -u admin_condominio -p < sql/01_tabelas.sql
mysql -u admin_condominio -p < sql/02_indices.sql
mysql -u admin_condominio -p < sql/03_geracao_ids.sql
mysql -u admin_condominio -p < sql/03_triggers.sql
mysql -u admin_condominio -p < sql/04_views.sql
mysql -u admin_condominio -p < sql/05_procedures_functions.sql
mysql -u admin_condominio -p < sql/06_usuarios_permissoes.sql
mysql -u admin_condominio -p < sql/90_dados_exemplo.sql
mysql -u admin_condominio -p < sql/99_demonstracao.sql
```

Pelo MySQL Workbench, cada script é aberto em File → Open SQL Script e executado numa conexão com o usuário `admin_condominio`.

O `01_tabelas.sql` apaga as tabelas e as recria do zero, então pode ser executado novamente para limpar o banco. Nesse caso, os scripts seguintes também precisam ser executados de novo.

Usuários de exemplo do sistema (a senha é igual ao login): `admin`, `renata` (síndica), `joao` (porteiro), `carlos` e `ana` (moradores).

O `99_demonstracao.sql` mostra estrutura, índices, IDs, triggers, views e funções sem alterar os dados. Os comandos que gravam dados ou que devem gerar erro estão em `docs/demonstracao-aplicacao.md`, para execução individual.

## Aplicação web (`app/`)

Node.js 18 ou mais novo + Express. A aplicação se conecta ao MySQL **sempre** com `app_condominio` e não inicia se o `.env` apontar para root.

```
cd app
cp .env.example .env
npm install
npm start
```

No Prompt de Comando do Windows, a segunda linha é `copy .env.example .env`.

A aplicação fica disponível em http://localhost:3000. A senha do `.env` deve ser a mesma definida para `app_condominio` no `06_usuarios_permissoes.sql`, entre aspas.

| O que a página mostra | Origem dos dados |
| --- | --- |
| Usuário conectado (canto superior direito) | `SELECT CURRENT_USER()`, evidência de que o acesso não usa root |
| Visitantes presentes | view `vw_visitantes_presentes` |
| Encomendas pendentes | view `vw_encomendas_pendentes` |
| Moradores | tabelas `moradores` + `unidades` |
| Últimas movimentações (IDs `ACS-...`) | tabela `acessos` |
| Botões Registrar entrada / saída | procedures `sp_registrar_entrada` e `sp_registrar_saida` (COMMIT/ROLLBACK) |

Rotas da API: `GET /api/conexao`, `/api/visitantes-presentes`, `/api/encomendas-pendentes`, `/api/moradores`, `/api/visitantes`, `/api/porteiros`, `/api/acessos` e `POST /api/acessos/entrada` e `/api/acessos/saida` (corpo `{"visitanteId": 2, "funcionarioId": 1}`).

## Documentação

- `docs/der.png` e `docs/der.svg`: Diagrama Entidade-Relacionamento. O `docs/der.mmd` é a fonte editável no [mermaid.live](https://mermaid.live).
- `docs/justificativas-estrutura.md`: modelagem, índices e geração de IDs.
- `docs/demonstracao-aplicacao.md`: roteiro de demonstração e tecnologias utilizadas.
