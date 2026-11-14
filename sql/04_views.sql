USE condominio;

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY DEFINER
VIEW vw_visitantes_presentes AS
SELECT v.id AS visitante_id,
       v.nome AS visitante,
       v.documento,
       m.nome AS morador,
       u.bloco,
       u.numero AS unidade,
       a.id AS acesso_id,
       a.data_hora AS entrada_em
  FROM visitantes v
  JOIN moradores m ON m.id = v.morador_id
  JOIN unidades u ON u.id = m.unidade_id
  JOIN acessos a ON a.visitante_id = v.id
 WHERE a.tipo = 'ENTRADA'
   AND NOT EXISTS (
       SELECT 1
         FROM acessos a2
        WHERE a2.visitante_id = a.visitante_id
          AND (a2.data_hora > a.data_hora
               OR (a2.data_hora = a.data_hora AND a2.id > a.id))
   );

CREATE OR REPLACE
    ALGORITHM = UNDEFINED
    SQL SECURITY DEFINER
VIEW vw_encomendas_pendentes AS
SELECT e.id AS encomenda_id,
       e.descricao,
       e.data_registro,
       m.id AS morador_id,
       m.nome AS destinatario,
       u.bloco,
       u.numero AS unidade,
       f.nome AS recebida_por
  FROM encomendas e
  JOIN moradores m ON m.id = e.destinatario_id
  JOIN unidades u ON u.id = e.unidade_id
  JOIN funcionarios f ON f.id = e.recebida_por_id
 WHERE e.retirada = FALSE;
