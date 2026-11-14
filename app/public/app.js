const $ = (id) => document.getElementById(id);

function escapar(texto) {
  return String(texto ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function dataHora(valor) {
  if (!valor) return '';
  const [data, hora = ''] = String(valor).split(' ');
  const [a, m, d] = data.split('-');
  return `${d}/${m}/${a} ${hora.slice(0, 5)}`.trim();
}

function unidade(bloco, numero) {
  return bloco ? `Bloco ${bloco}, ${numero}` : numero;
}

async function api(caminho, opcoes) {
  const resposta = await fetch(caminho, opcoes);
  const corpo = await resposta.json();
  if (!resposta.ok) throw new Error(corpo.erro || 'Falha na requisição.');
  return corpo;
}

function desenharTabela(id, colunas, linhas, vazio) {
  const cabecalho = `<thead><tr>${colunas.map((c) => `<th>${c.titulo}</th>`).join('')}</tr></thead>`;
  const corpo = linhas.length
    ? linhas.map((l) => `<tr>${colunas.map((c) =>
        `<td class="${c.classe || ''}">${c.valor(l)}</td>`).join('')}</tr>`).join('')
    : `<tr><td class="vazio" colspan="${colunas.length}">${vazio}</td></tr>`;
  $(id).innerHTML = `${cabecalho}<tbody>${corpo}</tbody>`;
}

async function carregarConexao() {
  const caixa = $('conexao');
  try {
    const c = await api('/api/conexao');
    caixa.innerHTML = `usuário <strong>${escapar(c.usuario)}</strong> · banco ${escapar(c.banco)} · MySQL ${escapar(c.versao.split('-')[0])}`;
  } catch (e) {
    caixa.classList.add('falha');
    caixa.innerHTML = `<strong>sem conexão</strong> · ${escapar(e.message)}`;
  }
}

async function carregarPresentes() {
  const linhas = await api('/api/visitantes-presentes');
  desenharTabela('tab-presentes', [
    { titulo: 'Visitante', valor: (l) => escapar(l.visitante) },
    { titulo: 'Documento', valor: (l) => escapar(l.documento) },
    { titulo: 'Visita', valor: (l) => `${escapar(l.morador)} · ${escapar(unidade(l.bloco, l.unidade))}` },
    { titulo: 'Entrou em', valor: (l) => dataHora(l.entrada_em) },
  ], linhas, 'Nenhum visitante no condomínio agora.');
}

async function carregarAcessos() {
  const linhas = await api('/api/acessos');
  desenharTabela('tab-acessos', [
    { titulo: 'ID', valor: (l) => escapar(l.id), classe: 'codigo' },
    { titulo: 'Tipo', valor: (l) => `<span class="etiqueta ${l.tipo === 'ENTRADA' ? 'entrada' : 'saida'}">${l.tipo === 'ENTRADA' ? 'Entrada' : 'Saída'}</span>` },
    { titulo: 'Visitante', valor: (l) => escapar(l.visitante) },
    { titulo: 'Data e hora', valor: (l) => dataHora(l.data_hora) },
    { titulo: 'Registrado por', valor: (l) => escapar(l.registrado_por) },
  ], linhas, 'Nenhuma movimentação registrada.');
}

async function carregarEncomendas() {
  const linhas = await api('/api/encomendas-pendentes');
  desenharTabela('tab-encomendas', [
    { titulo: 'Código', valor: (l) => escapar(l.encomenda_id), classe: 'codigo' },
    { titulo: 'Descrição', valor: (l) => escapar(l.descricao) },
    { titulo: 'Destinatário', valor: (l) => escapar(l.destinatario) },
    { titulo: 'Unidade', valor: (l) => escapar(unidade(l.bloco, l.unidade)) },
    { titulo: 'Chegou em', valor: (l) => dataHora(l.data_registro) },
    { titulo: 'Recebida por', valor: (l) => escapar(l.recebida_por) },
  ], linhas, 'Nenhuma encomenda pendente.');
}

async function carregarMoradores() {
  const linhas = await api('/api/moradores');
  desenharTabela('tab-moradores', [
    { titulo: 'Nome', valor: (l) => escapar(l.nome) },
    { titulo: 'Unidade', valor: (l) => escapar(unidade(l.bloco, l.unidade)) },
    { titulo: 'Telefone', valor: (l) => escapar(l.telefone || '') },
  ], linhas, 'Nenhum morador cadastrado.');
}

async function carregarSelecoes() {
  const [visitantes, porteiros] = await Promise.all([api('/api/visitantes'), api('/api/porteiros')]);
  $('visitante').innerHTML = visitantes.map((v) =>
    `<option value="${v.id}">${escapar(v.nome)} (visita ${escapar(v.morador)})${v.autorizado ? '' : ' · não autorizado'}</option>`
  ).join('');
  $('porteiro').innerHTML = porteiros.map((p) =>
    `<option value="${p.id}">${escapar(p.nome)}</option>`
  ).join('');
}

function mostrarMensagem(texto, tipo) {
  const m = $('mensagem');
  m.textContent = texto;
  m.className = `mensagem ${tipo}`;
}

async function registrar(acao) {
  const botoes = document.querySelectorAll('#form-portaria button');
  botoes.forEach((b) => { b.disabled = true; });
  try {
    const r = await api(`/api/acessos/${acao}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ visitanteId: $('visitante').value, funcionarioId: $('porteiro').value }),
    });
    mostrarMensagem(r.mensagem, 'ok');
    await Promise.all([carregarPresentes(), carregarAcessos()]);
  } catch (e) {
    mostrarMensagem(e.message, 'erro');
  } finally {
    botoes.forEach((b) => { b.disabled = false; });
  }
}

$('form-portaria').addEventListener('submit', (evento) => {
  evento.preventDefault();
  registrar(evento.submitter?.dataset.acao || 'entrada');
});

async function iniciar() {
  await carregarConexao();
  const tarefas = [carregarSelecoes(), carregarPresentes(), carregarAcessos(), carregarEncomendas(), carregarMoradores()];
  const resultados = await Promise.allSettled(tarefas);
  const falha = resultados.find((r) => r.status === 'rejected');
  if (falha) mostrarMensagem(falha.reason.message, 'erro');
}

iniciar();
