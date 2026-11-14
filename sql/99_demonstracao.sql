USE condominio;

SHOW TABLES;

SELECT table_name AS tabela, column_name AS coluna,
       referenced_table_name AS referencia
  FROM information_schema.key_column_usage
 WHERE table_schema = 'condominio' AND referenced_table_name IS NOT NULL
 ORDER BY table_name, column_name;

SHOW INDEX FROM acessos;

EXPLAIN SELECT * FROM acessos
 WHERE visitante_id = 1 ORDER BY data_hora DESC LIMIT 1;

EXPLAIN SELECT * FROM reservas
 WHERE area_id = 1 AND data = '2026-11-20';

EXPLAIN SELECT * FROM ocorrencias
 WHERE status = 'ABERTA' ORDER BY data_registro DESC;

EXPLAIN SELECT * FROM encomendas
 WHERE unidade_id = 1 AND retirada = FALSE;

EXPLAIN SELECT * FROM visitantes WHERE documento = '12345678';

SELECT id, descricao FROM encomendas;
SELECT * FROM sequencias_id;

SELECT fn_id_valido('ENC-2026-000001-3') AS codigo_certo,
       fn_id_valido('ENC-2026-000001-4') AS digito_trocado;

START TRANSACTION;
INSERT INTO encomendas (descricao, destinatario_id, unidade_id, recebida_por_id)
VALUES ('teste da apresentacao', 1, 1, 1);
SELECT id FROM encomendas WHERE descricao = 'teste da apresentacao';
SELECT ultimo AS durante_transacao FROM sequencias_id WHERE prefixo = 'ENC';
ROLLBACK;
SELECT ultimo AS depois_do_rollback FROM sequencias_id WHERE prefixo = 'ENC';

SHOW TRIGGERS FROM condominio;

SELECT * FROM vw_visitantes_presentes;
SELECT * FROM vw_encomendas_pendentes;

SELECT fn_contar_encomendas_pendentes(1) AS pendentes_unidade_1;
