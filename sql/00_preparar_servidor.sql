CREATE DATABASE IF NOT EXISTS condominio
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;

CREATE USER IF NOT EXISTS 'admin_condominio'@'localhost' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON condominio.* TO 'admin_condominio'@'localhost' WITH GRANT OPTION;
GRANT CREATE USER ON *.* TO 'admin_condominio'@'localhost';

SET PERSIST log_bin_trust_function_creators = 1;
