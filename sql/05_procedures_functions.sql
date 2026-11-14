USE condominio;

DROP PROCEDURE IF EXISTS sp_registrar_entrada;
DROP PROCEDURE IF EXISTS sp_registrar_saida;
DROP PROCEDURE IF EXISTS sp_registrar_retirada_encomenda;
DROP FUNCTION IF EXISTS fn_contar_encomendas_pendentes;

DELIMITER $$

CREATE PROCEDURE sp_registrar_entrada(
    IN p_visitante_id INT UNSIGNED,
    IN p_funcionario_id INT UNSIGNED
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_autorizado BOOLEAN DEFAULT FALSE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_autorizado = FALSE;

    START TRANSACTION;

    SELECT autorizado INTO v_autorizado
      FROM visitantes
     WHERE id = p_visitante_id
     FOR UPDATE;

    IF NOT v_autorizado THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Entrada nao registrada: visitante inexistente ou nao autorizado.';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM vw_visitantes_presentes
         WHERE visitante_id = p_visitante_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Entrada nao registrada: visitante ja esta no condominio.';
    END IF;

    INSERT INTO acessos (visitante_id, tipo, registrado_por_id)
    VALUES (p_visitante_id, 'ENTRADA', p_funcionario_id);

    COMMIT;
END$$

CREATE PROCEDURE sp_registrar_saida(
    IN p_visitante_id INT UNSIGNED,
    IN p_funcionario_id INT UNSIGNED
)
SQL SECURITY DEFINER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
          FROM vw_visitantes_presentes
         WHERE visitante_id = p_visitante_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Saida nao registrada: visitante nao esta no condominio.';
    END IF;

    INSERT INTO acessos (visitante_id, tipo, registrado_por_id)
    VALUES (p_visitante_id, 'SAIDA', p_funcionario_id);

    COMMIT;
END$$

CREATE PROCEDURE sp_registrar_retirada_encomenda(
    IN p_encomenda_id CHAR(17),
    IN p_morador_id INT UNSIGNED
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_alteradas INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    UPDATE encomendas
       SET retirada = TRUE
     WHERE id = p_encomenda_id
       AND destinatario_id = p_morador_id
       AND retirada = FALSE;

    SET v_alteradas = ROW_COUNT();
    IF v_alteradas <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Retirada nao registrada: encomenda pendente nao encontrada para este morador.';
    END IF;

    COMMIT;
END$$

CREATE FUNCTION fn_contar_encomendas_pendentes(p_unidade_id INT UNSIGNED)
RETURNS INT UNSIGNED
READS SQL DATA
SQL SECURITY DEFINER
BEGIN
    DECLARE v_total INT UNSIGNED DEFAULT 0;

    SELECT COUNT(*) INTO v_total
      FROM encomendas
     WHERE unidade_id = p_unidade_id
       AND retirada = FALSE;

    RETURN v_total;
END$$

DELIMITER ;
