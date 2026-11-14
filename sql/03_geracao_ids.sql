USE condominio;

DROP FUNCTION IF EXISTS fn_digito_verificador;
DROP FUNCTION IF EXISTS fn_formatar_id;
DROP FUNCTION IF EXISTS fn_gerar_id;
DROP FUNCTION IF EXISTS fn_id_valido;
DROP FUNCTION IF EXISTS fn_proximo_id_usuario;
DROP FUNCTION IF EXISTS fn_proximo_id_ocorrencia;
DROP FUNCTION IF EXISTS fn_proximo_id_encomenda;
DROP FUNCTION IF EXISTS fn_proximo_id_acesso;

DELIMITER $$

CREATE FUNCTION fn_digito_verificador(numero VARCHAR(20))
RETURNS CHAR(1)
DETERMINISTIC NO SQL
BEGIN
    DECLARE soma INT DEFAULT 0;
    DECLARE peso INT DEFAULT 2;
    DECLARE pos  INT;
    DECLARE resto INT;

    IF numero IS NULL OR numero = '' OR numero NOT REGEXP '^[0-9]+$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'fn_digito_verificador: informe apenas digitos.';
    END IF;

    SET pos = CHAR_LENGTH(numero);
    WHILE pos > 0 DO
        SET soma = soma + CAST(SUBSTRING(numero, pos, 1) AS UNSIGNED) * peso;
        SET peso = IF(peso = 9, 2, peso + 1);
        SET pos = pos - 1;
    END WHILE;

    SET resto = 11 - (soma MOD 11);
    RETURN IF(resto >= 10, '0', CAST(resto AS CHAR));
END$$

CREATE FUNCTION fn_formatar_id(prefixo CHAR(3), ano SMALLINT UNSIGNED, sequencial INT UNSIGNED)
RETURNS CHAR(17)
DETERMINISTIC NO SQL
BEGIN
    DECLARE corpo CHAR(10);

    IF sequencial < 1 OR sequencial > 999999 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'fn_formatar_id: sequencial fora do intervalo 1..999999.';
    END IF;

    SET corpo = CONCAT(LPAD(ano, 4, '0'), LPAD(sequencial, 6, '0'));
    RETURN CONCAT(UPPER(prefixo), '-', LEFT(corpo, 4), '-', RIGHT(corpo, 6), '-',
                  fn_digito_verificador(corpo));
END$$

CREATE FUNCTION fn_gerar_id(p_prefixo CHAR(3))
RETURNS CHAR(17)
NOT DETERMINISTIC MODIFIES SQL DATA
BEGIN
    DECLARE v_ano SMALLINT UNSIGNED DEFAULT YEAR(CURDATE());
    DECLARE v_numero INT UNSIGNED;

    IF p_prefixo IS NULL OR UPPER(p_prefixo) NOT IN ('USR', 'OCO', 'ENC', 'ACS') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'fn_gerar_id: prefixo desconhecido (use USR, OCO, ENC ou ACS).';
    END IF;

    INSERT INTO sequencias_id (prefixo, ano, ultimo)
         VALUES (UPPER(p_prefixo), v_ano, 1)
    ON DUPLICATE KEY UPDATE ultimo = ultimo + 1;

    SELECT ultimo INTO v_numero
      FROM sequencias_id
     WHERE prefixo = UPPER(p_prefixo) AND ano = v_ano;

    RETURN fn_formatar_id(p_prefixo, v_ano, v_numero);
END$$

CREATE FUNCTION fn_id_valido(id VARCHAR(20))
RETURNS BOOLEAN
DETERMINISTIC NO SQL
BEGIN
    IF id IS NULL OR id NOT REGEXP '^[A-Z]{3}-[0-9]{4}-[0-9]{6}-[0-9]$' THEN
        RETURN FALSE;
    END IF;
    RETURN RIGHT(id, 1) = fn_digito_verificador(CONCAT(SUBSTRING(id, 5, 4), SUBSTRING(id, 10, 6)));
END$$

DROP TRIGGER IF EXISTS trg_usuarios_id$$
CREATE TRIGGER trg_usuarios_id
BEFORE INSERT ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '' THEN
        SET NEW.id = fn_gerar_id('USR');
    ELSEIF LEFT(NEW.id, 3) <> 'USR' OR NOT fn_id_valido(NEW.id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ID de usuario invalido (formato USR-AAAA-NNNNNN-D).';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_ocorrencias_id$$
CREATE TRIGGER trg_ocorrencias_id
BEFORE INSERT ON ocorrencias
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '' THEN
        SET NEW.id = fn_gerar_id('OCO');
    ELSEIF LEFT(NEW.id, 3) <> 'OCO' OR NOT fn_id_valido(NEW.id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ID de ocorrencia invalido (formato OCO-AAAA-NNNNNN-D).';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_encomendas_id$$
CREATE TRIGGER trg_encomendas_id
BEFORE INSERT ON encomendas
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '' THEN
        SET NEW.id = fn_gerar_id('ENC');
    ELSEIF LEFT(NEW.id, 3) <> 'ENC' OR NOT fn_id_valido(NEW.id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ID de encomenda invalido (formato ENC-AAAA-NNNNNN-D).';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_acessos_id$$
CREATE TRIGGER trg_acessos_id
BEFORE INSERT ON acessos
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '' THEN
        SET NEW.id = fn_gerar_id('ACS');
    ELSEIF LEFT(NEW.id, 3) <> 'ACS' OR NOT fn_id_valido(NEW.id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ID de acesso invalido (formato ACS-AAAA-NNNNNN-D).';
    END IF;
END$$

DELIMITER ;
