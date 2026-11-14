# Estrutura do banco: modelagem, índices e geração de IDs

Decisões de modelagem do banco, uso de índices e geração de IDs. Scripts correspondentes: `sql/00_preparar_servidor.sql`, `sql/01_tabelas.sql`, `sql/02_indices.sql` e `sql/03_geracao_ids.sql`.

## 1. Visão geral

O banco `condominio` (MySQL 8.0) tem 14 tabelas do sistema e uma tabela auxiliar (`sequencias_id`), usada só na geração de IDs. Ele foi modelado a partir do sistema de gestão de condomínio desenvolvido na disciplina de POO e mantém as mesmas regras de negócio, agora garantidas também pelo próprio banco.

| Decisão | Justificativa |
| --- | --- |
| Engine InnoDB | É a engine do MySQL que oferece chaves estrangeiras, transações (`COMMIT`/`ROLLBACK`) e bloqueio por linha. |
| Charset `utf8mb4` | Aceita acentos e qualquer caractere Unicode em nomes e descrições. |
| `ON DELETE RESTRICT` como padrão nas chaves estrangeiras | Impede apagar um registro que ainda tem vínculos, como uma unidade com moradores, e preserva o histórico de acessos, encomendas e reservas. |
| Exceções ao `RESTRICT` | `pets` usa `CASCADE`, porque o pet só existe junto com o morador. `veiculos.vaga_id` e as FKs de `ocorrencias` usam `SET NULL`: excluir a vaga não apaga o carro, e excluir um morador não apaga a ocorrência que ele abriu. |
| `ENUM` para status e tipos | `ocorrencias.status`, `acessos.tipo` e `grupos_usuarios.nivel_acesso` só aceitam os valores previstos. O banco rejeita qualquer outro valor. |
| `CHECK` para regras de consistência | O banco rejeita dados inválidos mesmo se a aplicação falhar: salário negativo, reserva que termina antes de começar, retirada de encomenda anterior à chegada, usuário ligado a morador e a funcionário ao mesmo tempo. |
| `DECIMAL(10,2)` para salário | Valor monetário exato. `FLOAT` tem erro de arredondamento. |
| Nenhum acesso com root | O root só roda `00_preparar_servidor.sql`, uma única vez, para criar o banco e o usuário `admin_condominio`. Todo o resto roda com esse usuário, que tem poder total só dentro do banco `condominio`. |

## 2. Entidades e relacionamentos

O DER está em `docs/der.png` (fonte editável em `docs/der.mmd`). A tabela `sequencias_id` não aparece nele porque não se relaciona com nenhuma outra.

| Tabela | O que representa | Relacionamentos |
| --- | --- | --- |
| `grupos_usuarios` | Perfis de acesso: Administrador (total), Síndico (gerencial), Porteiro (operacional) e Morador (próprio) | 1:N com `usuarios` |
| `usuarios` | Contas de login. A senha fica guardada como hash SHA-256. | N:1 com `grupos_usuarios`; opcionalmente ligado a um morador **ou** a um funcionário |
| `unidades` | Apartamentos, identificados por bloco e número (`UNIQUE`) | 1:N com moradores, vagas, encomendas e ocorrências |
| `moradores` | Pessoas que moram em uma unidade | N:1 com `unidades`; 1:N com pets, veículos, reservas, visitantes e encomendas |
| `pets` | Animais do morador. Não é usuário do sistema, é um dado do morador. | N:1 com `moradores` |
| `funcionarios` | Porteiros, zelador, equipe de manutenção | 1:N com `acessos` (quem registrou) e `encomendas` (quem recebeu) |
| `vagas` | Vagas de garagem de cada unidade | N:1 com `unidades`; 1:1 opcional com `veiculos` |
| `veiculos` | Carros dos moradores | N:1 com `moradores`. Ocupa no máximo uma vaga, e cada vaga recebe no máximo um veículo (`UNIQUE` em `vaga_id`). |
| `areas_comuns` | Salão de festas, churrasqueira, quadra | 1:N com `reservas` |
| `reservas` | Uso agendado de uma área comum | N:1 com `areas_comuns` e com `moradores` |
| `ocorrencias` | Reclamações e problemas registrados | N:1 opcional com `moradores` e `unidades`: um problema na garagem não pertence a nenhuma unidade |
| `visitantes` | Pessoas que visitam um morador e precisam da autorização dele | N:1 com `moradores`; 1:N com `acessos` |
| `acessos` | Cada entrada ou saída de visitante na portaria | N:1 com `visitantes` e com `funcionarios` |
| `encomendas` | Pacotes recebidos na portaria | N:1 com `moradores` (destinatário), `unidades` e `funcionarios` (quem recebeu) |
| `sequencias_id` | Último número de ID emitido por prefixo e ano | Nenhum; usada só pela função `fn_gerar_id` |

Principais decisões de modelagem:

- **Usuário separado de morador e funcionário.** Nem todo morador ou funcionário usa o sistema, e o administrador não é nenhum dos dois. A regra "morador **ou** funcionário, nunca os dois" é garantida pelo `CHECK ck_usuarios_vinculo`.
- **Grupos em tabela própria, e não numa coluna de texto.** As permissões ficam centralizadas e cada usuário aponta para um grupo por chave estrangeira. Isso impede perfis com nome digitado errado, e um novo perfil é só um `INSERT`.
- **Acesso aponta para o visitante cadastrado, e não para um nome digitado.** Assim só entra quem foi cadastrado, e dá para consultar o histórico de cada visitante.
- **Encomenda guarda a unidade além do destinatário.** Se o morador se mudar, a encomenda continua ligada à unidade onde foi entregue.
- **`bloco` é `NOT NULL DEFAULT ''`.** Em MySQL, valores `NULL` não se repetem num `UNIQUE`. Com `bloco` nulo seria possível cadastrar duas unidades "101" sem bloco.

## 3. Índices

Já existem por causa das restrições: a `PRIMARY KEY` de cada tabela; os `UNIQUE` (login, placa, vaga do veículo, número da vaga, bloco + número da unidade, nome da área comum); e um índice em cada chave estrangeira, que o InnoDB cria sozinho.

Índices criados em `02_indices.sql` para as consultas mais frequentes:

| Índice | Consulta atendida | Por que essas colunas, nessa ordem |
| --- | --- | --- |
| `idx_acessos_visitante_data (visitante_id, data_hora)` | Última movimentação de um visitante: ele está dentro ou fora? | Filtra por visitante e lê o registro mais recente direto no índice. `acessos` é a tabela que mais cresce, porque cada visita gera duas linhas. |
| `idx_acessos_data_hora (data_hora)` | Relatório de movimentação por período | Consulta por faixa de datas (`BETWEEN`, `>=`). |
| `idx_reservas_area_data (area_id, data, hora_inicio)` | Verificar conflito de horário antes de gravar uma reserva | Área e data são filtros de igualdade, então o banco lê só as reservas daquela área naquele dia, já em ordem de horário. |
| `idx_ocorrencias_status_data (status, data_registro)` | Ocorrências abertas mais recentes e relatório por status | Filtra por status e já devolve na ordem de data, sem ordenar em memória. |
| `idx_encomendas_unidade_retirada (unidade_id, retirada)` | Encomendas pendentes de uma unidade | Dois filtros de igualdade, usados juntos pelo morador e pela portaria. |
| `idx_visitantes_documento (documento)` | Porteiro procura o visitante pelo documento | Não é `UNIQUE`: a mesma pessoa pode visitar moradores diferentes. |
| `idx_moradores_nome (nome)` | Busca de morador pelo nome (`LIKE 'Ana%'`) | Atende buscas pelo início do nome. |

Os índices compostos começam pela coluna da chave estrangeira, então substituem o índice automático da FK em vez de criar um segundo.

**Impacto esperado:** sem índice, o MySQL lê a tabela inteira (`type = ALL` no `EXPLAIN`), e o custo cresce junto com o histórico. Com índice, ele vai direto às linhas certas (`type = ref` ou `range`), e o custo passa a depender só de quantas linhas atendem ao filtro. O efeito aparece justamente nas tabelas de histórico (acessos, encomendas, ocorrências), que crescem todo dia.

**Custo:** cada índice ocupa espaço e deixa `INSERT`/`UPDATE` um pouco mais lentos. Por isso só foram criados índices para consultas que o sistema realmente faz.

**Verificação:** todos os índices foram conferidos com `EXPLAIN` no MySQL 8.0. Cada consulta da tabela acima usou o índice previsto. Os comandos estão em `sql/99_demonstracao.sql`.

## 4. Geração de IDs

### Dados críticos: ID próprio

Formato `PPP-AAAA-NNNNNN-D`, gerado pela função `fn_gerar_id(prefixo)`:

| Tabela | Prefixo | Exemplo | Por que é crítico |
| --- | --- | --- | --- |
| `usuarios` | USR | USR-2026-000001-3 | Credenciais de acesso ao sistema |
| `ocorrencias` | OCO | OCO-2026-000002-1 | Vira número de protocolo informado ao morador e pode embasar advertência ou multa |
| `encomendas` | ENC | ENC-2026-000003-0 | Código conferido na retirada; em caso de extravio, identifica o pacote |
| `acessos` | ACS | ACS-2026-000001-3 | Trilha de segurança da portaria, consultada em caso de incidente |

**Por que esse formato:** o ID pode ser falado ao telefone, impresso num recibo ou citado numa ata, e já mostra o tipo e o ano do registro. O dígito verificador (módulo 11, a mesma ideia do CPF) detecta erro de digitação: se o porteiro trocar um número do código da encomenda, `fn_id_valido` devolve falso antes mesmo da busca. A numeração recomeça a cada ano.

**Como funciona:**

1. `fn_gerar_id('ENC')` soma 1 na linha `(ENC, ano atual)` de `sequencias_id` com um único comando (`INSERT ... ON DUPLICATE KEY UPDATE`). Se for o primeiro registro do ano, cria a linha com 1.
2. Esse comando trava a linha da sequência até o fim da transação. Dois porteiros registrando encomendas no mesmo instante nunca recebem o mesmo número: o segundo espera o primeiro terminar. No teste com duas sessões simultâneas, a segunda esperou cerca de 2 segundos e recebeu o número seguinte. Em outro teste, 20 inserções em paralelo geraram 20 IDs diferentes e em sequência.
3. Se a transação sofrer `ROLLBACK`, o incremento também é desfeito e a numeração não fica com buracos. Isso também foi testado.
4. Um trigger `BEFORE INSERT` em cada uma das quatro tabelas gera o ID quando o `INSERT` chega sem ele. Quando a aplicação envia o ID, o trigger confere o prefixo e o dígito e recusa o que estiver errado.
5. A aplicação Java (JPA/Hibernate) precisa saber o ID antes de gravar. Por isso ela chama `SELECT fn_gerar_id('OCO')` dentro da mesma transação do `INSERT`.

Funções criadas: `fn_digito_verificador`, `fn_formatar_id`, `fn_gerar_id` e `fn_id_valido`.

### Cadastros: AUTO_INCREMENT (justificado)

`unidades`, `moradores`, `pets`, `funcionarios`, `vagas`, `veiculos`, `areas_comuns`, `reservas` e `visitantes` usam `AUTO_INCREMENT`, porque:

- **São cadastros internos.** O ID nunca aparece para o usuário nem sai do sistema. A unidade é identificada por "Bloco A, 101", o veículo pela placa, a vaga pelo número, e esses identificadores naturais têm `UNIQUE`.
- **Desempenho.** Uma chave inteira crescente é a melhor opção para a chave primária do InnoDB, porque a tabela é gravada fisicamente na ordem da chave. É também a chave mais compacta para as FKs que apontam para essas tabelas, e elas são muitas: `moradores` recebe 7 FKs.
- **Simplicidade.** O MySQL garante a unicidade sem bloqueio extra, e nenhuma regra de negócio exige um formato próprio para esses registros.

`grupos_usuarios` não usa nenhum dos dois: é uma tabela de domínio com 4 linhas fixas (ids 1 a 4), carregadas no próprio script.

## 5. Configuração do servidor (00_preparar_servidor.sql)

O MySQL 8 vem com o log binário ligado. Nessa configuração, só quem tem o privilégio `SUPER` pode criar funções e triggers. Dar `SUPER` ao `admin_condominio` o tornaria quase um root. Em vez disso, o script de preparação liga `log_bin_trust_function_creators`, o que permite criar funções e triggers a quem já tem `CREATE ROUTINE` e `TRIGGER` no banco. Assim, o root é usado uma única vez, só para preparar o servidor.
