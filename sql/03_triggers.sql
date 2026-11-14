USE condominio;

DROP TRIGGER IF EXISTS trg_reservas_sem_conflito_bi;
DROP TRIGGER IF EXISTS trg_reservas_sem_conflito_bu;
DROP TRIGGER IF EXISTS trg_encomendas_retirada_bi;
DROP TRIGGER IF EXISTS trg_encomendas_retirada_bu;
DROP TRIGGER IF EXISTS trg_acessos_visitante_autorizado_bi;

DELIMITER $$

CREATE TRIGGER trg_reservas_sem_conflito_bi
BEFORE INSERT ON reservas
FOR EACH ROW
BEGIN
    DECLARE v_conflitos INT DEFAULT 0;

    SELECT COUNT(*) INTO v_conflitos
      FROM reservas
     WHERE area_id = NEW.area_id
       AND data = NEW.data
       AND hora_inicio < NEW.hora_fim
       AND hora_fim > NEW.hora_inicio;

    IF v_conflitos > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ja existe reserva da area neste intervalo.';
    END IF;
END$$

CREATE TRIGGER trg_reservas_sem_conflito_bu
BEFORE UPDATE ON reservas
FOR EACH ROW
BEGIN
    DECLARE v_conflitos INT DEFAULT 0;

    SELECT COUNT(*) INTO v_conflitos
      FROM reservas
     WHERE area_id = NEW.area_id
       AND data = NEW.data
       AND hora_inicio < NEW.hora_fim
       AND hora_fim > NEW.hora_inicio
       AND id <> OLD.id;

    IF v_conflitos > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ja existe reserva da area neste intervalo.';
    END IF;
END$$

CREATE TRIGGER trg_encomendas_retirada_bi
BEFORE INSERT ON encomendas
FOR EACH ROW FOLLOWS trg_encomendas_id
BEGIN
    IF NEW.retirada THEN
        SET NEW.data_retirada = COALESCE(NEW.data_retirada, NOW());
    ELSE
        SET NEW.data_retirada = NULL;
    END IF;
END$$

CREATE TRIGGER trg_encomendas_retirada_bu
BEFORE UPDATE ON encomendas
FOR EACH ROW
BEGIN
    IF NEW.retirada AND NOT OLD.retirada THEN
        SET NEW.data_retirada = COALESCE(NEW.data_retirada, NOW());
    ELSEIF NOT NEW.retirada THEN
        SET NEW.data_retirada = NULL;
    END IF;
END$$

CREATE TRIGGER trg_acessos_visitante_autorizado_bi
BEFORE INSERT ON acessos
FOR EACH ROW
BEGIN
    DECLARE v_autorizado BOOLEAN DEFAULT FALSE;

    IF NEW.tipo = 'ENTRADA' THEN
        SELECT COALESCE(MAX(autorizado), FALSE) INTO v_autorizado
          FROM visitantes
         WHERE id = NEW.visitante_id;

        IF NOT v_autorizado THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Entrada bloqueada: visitante nao autorizado.';
        END IF;
    END IF;
END$$

DELIMITER ;
