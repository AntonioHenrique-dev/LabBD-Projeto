USE condominio;

START TRANSACTION;

INSERT INTO unidades (bloco, numero) VALUES
    ('A', '101'), ('A', '102'), ('A', '201'), ('B', '101'), ('B', '202');

INSERT INTO moradores (nome, telefone, unidade_id) VALUES
    ('Carlos Silva',   '61 99999-0001', 1),
    ('Ana Souza',      '61 99999-0002', 2),
    ('Bruno Lima',     '61 99999-0003', 3),
    ('Daniela Rocha',  '61 99999-0004', 4),
    ('Eduardo Dias',   '61 99999-0005', 5);

INSERT INTO pets (nome, especie, morador_id) VALUES
    ('Thor', 'Cachorro', 1),
    ('Mia',  'Gato',     2);

INSERT INTO funcionarios (nome, cargo, salario) VALUES
    ('Joao Pereira',   'Porteiro',   2450.00),
    ('Marcia Alves',   'Porteiro',   2450.00),
    ('Paulo Mendes',   'Zelador',    2800.00),
    ('Renata Costa',   'Sindica',    4500.00);

INSERT INTO usuarios (login, senha_hash, grupo_id, morador_id, funcionario_id) VALUES
    ('admin',   SHA2('admin', 256),   1, NULL, NULL),
    ('renata',  SHA2('renata', 256),  2, NULL, 4),
    ('joao',    SHA2('joao', 256),    3, NULL, 1),
    ('carlos',  SHA2('carlos', 256),  4, 1,    NULL),
    ('ana',     SHA2('ana', 256),     4, 2,    NULL);

INSERT INTO vagas (numero, unidade_id) VALUES
    ('G-01', 1), ('G-02', 2), ('G-03', 3), ('G-04', 4);

INSERT INTO veiculos (placa, modelo, cor, morador_id, vaga_id) VALUES
    ('ABC1D23', 'Onix',  'Prata',  1, 1),
    ('XYZ9K88', 'HB20',  'Branco', 2, 2),
    ('JKL4M56', 'Kwid',  'Preto',  4, NULL);

INSERT INTO areas_comuns (nome, capacidade) VALUES
    ('Salao de festas', 60),
    ('Churrasqueira',   20),
    ('Quadra',          16);

INSERT INTO reservas (area_id, morador_id, data, hora_inicio, hora_fim) VALUES
    (1, 1, '2026-11-20', '18:00', '23:00'),
    (2, 2, '2026-11-21', '12:00', '17:00'),
    (3, 4, '2026-11-22', '09:00', '11:00');

INSERT INTO ocorrencias (descricao, registrado_por, morador_id, unidade_id, status) VALUES
    ('Barulho apos as 22h no apartamento vizinho', 'Carlos Silva',  1, 1, 'ABERTA'),
    ('Vazamento no teto da garagem',               'Paulo Mendes',  NULL, NULL, 'EM_ANDAMENTO'),
    ('Lampada queimada no hall do bloco B',        'Daniela Rocha', 4, 4, 'RESOLVIDA');

INSERT INTO visitantes (nome, documento, morador_id, autorizado) VALUES
    ('Fernanda Gomes', '12345678', 1, TRUE),
    ('Lucas Martins',  '87654321', 2, TRUE),
    ('Pedro Santos',   '11223344', 4, FALSE);

INSERT INTO acessos (visitante_id, tipo, data_hora, registrado_por_id) VALUES
    (1, 'ENTRADA', '2026-11-14 14:05:00', 1),
    (2, 'ENTRADA', '2026-11-14 15:30:00', 2),
    (2, 'SAIDA',   '2026-11-14 17:10:00', 2);

INSERT INTO encomendas (descricao, destinatario_id, unidade_id, recebida_por_id, retirada, data_retirada) VALUES
    ('Caixa media - Mercado Livre', 1, 1, 1, FALSE, NULL),
    ('Envelope - Correios',         2, 2, 1, FALSE, NULL),
    ('Caixa pequena - Amazon',      4, 4, 2, TRUE,  NOW());

COMMIT;
