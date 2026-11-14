const path = require('path');
const express = require('express');
const { pool, usuarioConectado } = require('./db');

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'public')));

const rota = (fn) => async (req, res) => {
  try {
    await fn(req, res);
  } catch (erro) {
    res.status(statusDoErro(erro)).json({ erro: mensagemDoErro(erro) });
  }
};

function statusDoErro(erro) {
  if (erro.status) return erro.status;
  if (erro.sqlState === '45000') return 400;
  if (erro.code === 'ER_NO_REFERENCED_ROW_2') return 400;
  if (erro.code === 'ER_TABLEACCESS_DENIED_ERROR') return 403;
  if (erro.code === 'ER_PROCACCESS_DENIED_ERROR') return 403;
  return 500;
}

function mensagemDoErro(erro) {
  if (erro.status) return erro.message;
  if (erro.sqlState === '45000') return erro.sqlMessage;
  if (erro.code === 'ER_NO_REFERENCED_ROW_2') return 'Visitante ou funcionário inexistente.';
  if (erro.code === 'ER_TABLEACCESS_DENIED_ERROR' || erro.code === 'ER_PROCACCESS_DENIED_ERROR') {
    return 'Permissão negada para o usuário da aplicação: ' + erro.sqlMessage;
  }
  console.error(erro);
  return 'Erro inesperado no servidor.';
}

function idInteiro(valor, nome) {
  const n = Number(valor);
  if (!Number.isInteger(n) || n <= 0) {
    const erro = new Error(`Informe um ${nome} válido.`);
    erro.status = 400;
    throw erro;
  }
  return n;
}

app.get('/api/conexao', rota(async (req, res) => {
  res.json(await usuarioConectado());
}));

app.get('/api/visitantes-presentes', rota(async (req, res) => {
  const [linhas] = await pool.query(
    'SELECT * FROM vw_visitantes_presentes ORDER BY entrada_em'
  );
  res.json(linhas);
}));

app.get('/api/encomendas-pendentes', rota(async (req, res) => {
  const [linhas] = await pool.query(
    'SELECT * FROM vw_encomendas_pendentes ORDER BY data_registro'
  );
  res.json(linhas);
}));

app.get('/api/moradores', rota(async (req, res) => {
  const [linhas] = await pool.query(
    `SELECT m.id, m.nome, m.telefone, u.bloco, u.numero AS unidade
       FROM moradores m
       JOIN unidades u ON u.id = m.unidade_id
      ORDER BY u.bloco, u.numero, m.nome`
  );
  res.json(linhas);
}));

app.get('/api/visitantes', rota(async (req, res) => {
  const [linhas] = await pool.query(
    `SELECT v.id, v.nome, v.documento, v.autorizado, m.nome AS morador
       FROM visitantes v
       JOIN moradores m ON m.id = v.morador_id
      ORDER BY v.nome`
  );
  res.json(linhas.map((v) => ({ ...v, autorizado: Boolean(v.autorizado) })));
}));

app.get('/api/porteiros', rota(async (req, res) => {
  const [linhas] = await pool.query(
    "SELECT id, nome FROM funcionarios WHERE cargo = 'Porteiro' ORDER BY nome"
  );
  res.json(linhas);
}));

app.get('/api/acessos', rota(async (req, res) => {
  const [linhas] = await pool.query(
    `SELECT a.id, a.tipo, a.data_hora, v.nome AS visitante, f.nome AS registrado_por
       FROM acessos a
       JOIN visitantes v ON v.id = a.visitante_id
       JOIN funcionarios f ON f.id = a.registrado_por_id
      ORDER BY a.data_hora DESC, a.id DESC
      LIMIT 10`
  );
  res.json(linhas);
}));

app.post('/api/acessos/entrada', rota(async (req, res) => {
  const visitanteId = idInteiro(req.body.visitanteId, 'visitante');
  const funcionarioId = idInteiro(req.body.funcionarioId, 'porteiro');
  await pool.query('CALL sp_registrar_entrada(?, ?)', [visitanteId, funcionarioId]);
  res.status(201).json({ mensagem: 'Entrada registrada.' });
}));

app.post('/api/acessos/saida', rota(async (req, res) => {
  const visitanteId = idInteiro(req.body.visitanteId, 'visitante');
  const funcionarioId = idInteiro(req.body.funcionarioId, 'porteiro');
  await pool.query('CALL sp_registrar_saida(?, ?)', [visitanteId, funcionarioId]);
  res.status(201).json({ mensagem: 'Saída registrada.' });
}));

const PORTA = Number(process.env.PORT || 3000);

usuarioConectado()
  .then(({ usuario }) => {
    if (usuario.toLowerCase().startsWith('root@')) {
      console.error('A aplicacao nao pode usar o usuario root. Configure DB_USER=app_condominio no .env.');
      process.exit(1);
    }
    app.listen(PORTA, () => {
      console.log(`Conectado ao MySQL como ${usuario}`);
      console.log(`Aplicacao em http://localhost:${PORTA}`);
    });
  })
  .catch((erro) => {
    console.error('Nao foi possivel conectar ao MySQL:', erro.message);
    process.exit(1);
  });
