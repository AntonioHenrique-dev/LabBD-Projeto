USE condominio;

CREATE INDEX idx_acessos_visitante_data
    ON acessos (visitante_id, data_hora);

CREATE INDEX idx_acessos_data_hora
    ON acessos (data_hora);

CREATE INDEX idx_reservas_area_data
    ON reservas (area_id, data, hora_inicio);

CREATE INDEX idx_ocorrencias_status_data
    ON ocorrencias (status, data_registro);

CREATE INDEX idx_encomendas_unidade_retirada
    ON encomendas (unidade_id, retirada);

CREATE INDEX idx_visitantes_documento
    ON visitantes (documento);

CREATE INDEX idx_moradores_nome
    ON moradores (nome);
