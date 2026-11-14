USE condominio;

DROP TABLE IF EXISTS encomendas, acessos, visitantes, ocorrencias, reservas,
    areas_comuns, veiculos, vagas, usuarios, funcionarios, pets, moradores,
    unidades, grupos_usuarios, sequencias_id;

CREATE TABLE sequencias_id (
    prefixo  CHAR(3)           NOT NULL,
    ano      SMALLINT UNSIGNED NOT NULL,
    ultimo   INT UNSIGNED      NOT NULL,
    CONSTRAINT pk_sequencias_id PRIMARY KEY (prefixo, ano),
    CONSTRAINT ck_sequencias_id_prefixo CHECK (prefixo IN ('USR', 'OCO', 'ENC', 'ACS')),
    CONSTRAINT ck_sequencias_id_ultimo CHECK (ultimo BETWEEN 1 AND 999999)
) ENGINE = InnoDB;

CREATE TABLE grupos_usuarios (
    id            TINYINT UNSIGNED NOT NULL,
    nome          VARCHAR(30)      NOT NULL,
    nivel_acesso  ENUM('TOTAL', 'GERENCIAL', 'OPERACIONAL', 'PROPRIO') NOT NULL,
    descricao     VARCHAR(200)     NOT NULL,
    CONSTRAINT pk_grupos_usuarios PRIMARY KEY (id),
    CONSTRAINT uq_grupos_usuarios_nome UNIQUE (nome)
) ENGINE = InnoDB;

INSERT INTO grupos_usuarios (id, nome, nivel_acesso, descricao) VALUES
    (1, 'ADMINISTRADOR', 'TOTAL',       'Cadastros, relatorios e configuracoes'),
    (2, 'SINDICO',       'GERENCIAL',   'Ocorrencias, areas comuns e relatorios'),
    (3, 'PORTEIRO',      'OPERACIONAL', 'Visitantes, acessos, encomendas e veiculos'),
    (4, 'MORADOR',       'PROPRIO',     'Reservas, encomendas, visitantes e ocorrencias proprias');

CREATE TABLE unidades (
    id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    bloco   VARCHAR(20)  NOT NULL DEFAULT '',
    numero  VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_unidades PRIMARY KEY (id),
    CONSTRAINT uq_unidades_bloco_numero UNIQUE (bloco, numero)
) ENGINE = InnoDB;

CREATE TABLE moradores (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(100) NOT NULL,
    telefone    VARCHAR(20)  NULL,
    unidade_id  INT UNSIGNED NOT NULL,
    CONSTRAINT pk_moradores PRIMARY KEY (id),
    CONSTRAINT fk_moradores_unidade FOREIGN KEY (unidade_id)
        REFERENCES unidades (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE pets (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(50)  NOT NULL,
    especie     VARCHAR(30)  NOT NULL,
    morador_id  INT UNSIGNED NOT NULL,
    CONSTRAINT pk_pets PRIMARY KEY (id),
    CONSTRAINT fk_pets_morador FOREIGN KEY (morador_id)
        REFERENCES moradores (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE funcionarios (
    id       INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nome     VARCHAR(100)  NOT NULL,
    cargo    VARCHAR(50)   NOT NULL,
    salario  DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_funcionarios PRIMARY KEY (id),
    CONSTRAINT ck_funcionarios_salario CHECK (salario >= 0)
) ENGINE = InnoDB;

CREATE TABLE usuarios (
    id              CHAR(17)         NOT NULL DEFAULT '',
    login           VARCHAR(50)      NOT NULL,
    senha_hash      CHAR(64)         NOT NULL,
    grupo_id        TINYINT UNSIGNED NOT NULL,
    morador_id      INT UNSIGNED     NULL,
    funcionario_id  INT UNSIGNED     NULL,
    ativo           BOOLEAN          NOT NULL DEFAULT TRUE,
    criado_em       DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_usuarios PRIMARY KEY (id),
    CONSTRAINT uq_usuarios_login UNIQUE (login),
    CONSTRAINT fk_usuarios_grupo FOREIGN KEY (grupo_id)
        REFERENCES grupos_usuarios (id),
    CONSTRAINT fk_usuarios_morador FOREIGN KEY (morador_id)
        REFERENCES moradores (id),
    CONSTRAINT fk_usuarios_funcionario FOREIGN KEY (funcionario_id)
        REFERENCES funcionarios (id),
    CONSTRAINT ck_usuarios_vinculo CHECK (morador_id IS NULL OR funcionario_id IS NULL)
) ENGINE = InnoDB;

CREATE TABLE vagas (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    numero      VARCHAR(10)  NOT NULL,
    unidade_id  INT UNSIGNED NOT NULL,
    CONSTRAINT pk_vagas PRIMARY KEY (id),
    CONSTRAINT uq_vagas_numero UNIQUE (numero),
    CONSTRAINT fk_vagas_unidade FOREIGN KEY (unidade_id)
        REFERENCES unidades (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE veiculos (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    placa       VARCHAR(10)  NOT NULL,
    modelo      VARCHAR(50)  NOT NULL,
    cor         VARCHAR(30)  NULL,
    morador_id  INT UNSIGNED NOT NULL,
    vaga_id     INT UNSIGNED NULL,
    CONSTRAINT pk_veiculos PRIMARY KEY (id),
    CONSTRAINT uq_veiculos_placa UNIQUE (placa),
    CONSTRAINT uq_veiculos_vaga UNIQUE (vaga_id),
    CONSTRAINT fk_veiculos_morador FOREIGN KEY (morador_id)
        REFERENCES moradores (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_veiculos_vaga FOREIGN KEY (vaga_id)
        REFERENCES vagas (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE areas_comuns (
    id          INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(100)      NOT NULL,
    capacidade  SMALLINT UNSIGNED NOT NULL,
    CONSTRAINT pk_areas_comuns PRIMARY KEY (id),
    CONSTRAINT uq_areas_comuns_nome UNIQUE (nome),
    CONSTRAINT ck_areas_comuns_capacidade CHECK (capacidade > 0)
) ENGINE = InnoDB;

CREATE TABLE reservas (
    id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    area_id      INT UNSIGNED NOT NULL,
    morador_id   INT UNSIGNED NOT NULL,
    data         DATE         NOT NULL,
    hora_inicio  TIME         NOT NULL,
    hora_fim     TIME         NOT NULL,
    CONSTRAINT pk_reservas PRIMARY KEY (id),
    CONSTRAINT fk_reservas_area FOREIGN KEY (area_id)
        REFERENCES areas_comuns (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reservas_morador FOREIGN KEY (morador_id)
        REFERENCES moradores (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_reservas_horario CHECK (hora_fim > hora_inicio)
) ENGINE = InnoDB;

CREATE TABLE ocorrencias (
    id              CHAR(17)     NOT NULL DEFAULT '',
    descricao       VARCHAR(500) NOT NULL,
    registrado_por  VARCHAR(100) NOT NULL,
    morador_id      INT UNSIGNED NULL,
    unidade_id      INT UNSIGNED NULL,
    data_registro   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          ENUM('ABERTA', 'EM_ANDAMENTO', 'RESOLVIDA') NOT NULL DEFAULT 'ABERTA',
    CONSTRAINT pk_ocorrencias PRIMARY KEY (id),
    CONSTRAINT fk_ocorrencias_morador FOREIGN KEY (morador_id)
        REFERENCES moradores (id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_ocorrencias_unidade FOREIGN KEY (unidade_id)
        REFERENCES unidades (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE visitantes (
    id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome           VARCHAR(100) NOT NULL,
    documento      VARCHAR(20)  NOT NULL,
    morador_id     INT UNSIGNED NOT NULL,
    autorizado     BOOLEAN      NOT NULL DEFAULT FALSE,
    data_registro  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_visitantes PRIMARY KEY (id),
    CONSTRAINT fk_visitantes_morador FOREIGN KEY (morador_id)
        REFERENCES moradores (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE acessos (
    id                 CHAR(17)     NOT NULL DEFAULT '',
    visitante_id       INT UNSIGNED NOT NULL,
    tipo               ENUM('ENTRADA', 'SAIDA') NOT NULL,
    data_hora          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    registrado_por_id  INT UNSIGNED NOT NULL,
    CONSTRAINT pk_acessos PRIMARY KEY (id),
    CONSTRAINT fk_acessos_visitante FOREIGN KEY (visitante_id)
        REFERENCES visitantes (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_acessos_funcionario FOREIGN KEY (registrado_por_id)
        REFERENCES funcionarios (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE encomendas (
    id               CHAR(17)     NOT NULL DEFAULT '',
    descricao        VARCHAR(200) NOT NULL,
    destinatario_id  INT UNSIGNED NOT NULL,
    unidade_id       INT UNSIGNED NOT NULL,
    recebida_por_id  INT UNSIGNED NOT NULL,
    data_registro    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retirada         BOOLEAN      NOT NULL DEFAULT FALSE,
    data_retirada    DATETIME     NULL,
    CONSTRAINT pk_encomendas PRIMARY KEY (id),
    CONSTRAINT fk_encomendas_destinatario FOREIGN KEY (destinatario_id)
        REFERENCES moradores (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_encomendas_unidade FOREIGN KEY (unidade_id)
        REFERENCES unidades (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_encomendas_funcionario FOREIGN KEY (recebida_por_id)
        REFERENCES funcionarios (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_encomendas_retirada CHECK (data_retirada IS NULL OR data_retirada >= data_registro)
) ENGINE = InnoDB;
