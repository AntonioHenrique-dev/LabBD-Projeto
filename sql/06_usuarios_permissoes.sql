USE condominio;

CREATE USER IF NOT EXISTS 'app_condominio'@'localhost'
    IDENTIFIED BY '12345678';
CREATE USER IF NOT EXISTS 'consulta_condominio'@'localhost'
    IDENTIFIED BY '123456789';

GRANT SELECT, INSERT, UPDATE ON condominio.unidades
    TO 'app_condominio'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condominio.moradores
    TO 'app_condominio'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condominio.pets
    TO 'app_condominio'@'localhost';
GRANT SELECT ON condominio.grupos_usuarios
    TO 'app_condominio'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condominio.usuarios
    TO 'app_condominio'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condominio.funcionarios
    TO 'app_condominio'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condominio.vagas
    TO 'app_condominio'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condominio.veiculos
    TO 'app_condominio'@'localhost';
GRANT SELECT ON condominio.areas_comuns
    TO 'app_condominio'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condominio.reservas
    TO 'app_condominio'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condominio.ocorrencias
    TO 'app_condominio'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condominio.visitantes
    TO 'app_condominio'@'localhost';
GRANT SELECT ON condominio.acessos
    TO 'app_condominio'@'localhost';
GRANT SELECT, INSERT, UPDATE ON condominio.encomendas
    TO 'app_condominio'@'localhost';

GRANT EXECUTE ON FUNCTION condominio.fn_gerar_id
    TO 'app_condominio'@'localhost';
GRANT EXECUTE ON FUNCTION condominio.fn_id_valido
    TO 'app_condominio'@'localhost';
GRANT EXECUTE ON FUNCTION condominio.fn_contar_encomendas_pendentes
    TO 'app_condominio'@'localhost';
GRANT EXECUTE ON PROCEDURE condominio.sp_registrar_entrada
    TO 'app_condominio'@'localhost';
GRANT EXECUTE ON PROCEDURE condominio.sp_registrar_retirada_encomenda
    TO 'app_condominio'@'localhost';
GRANT EXECUTE ON PROCEDURE condominio.sp_registrar_saida
    TO 'app_condominio'@'localhost';

GRANT SELECT ON condominio.vw_visitantes_presentes
    TO 'app_condominio'@'localhost';
GRANT SELECT ON condominio.vw_encomendas_pendentes
    TO 'app_condominio'@'localhost';

GRANT SELECT ON condominio.vw_visitantes_presentes
    TO 'consulta_condominio'@'localhost';
GRANT SELECT ON condominio.vw_encomendas_pendentes
    TO 'consulta_condominio'@'localhost';
