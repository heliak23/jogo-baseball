# ⚾ Jogo de Baseball 2D (Godot Engine 4)

<p align="center">
  <img src="icon.png" alt="Ícone do Jogo de Baseball" width="128" height="128">
</p>

<p align="center">
  <strong>Um simulador de baseball 2D completo, tático e dinâmico desenvolvido na Godot Engine 4.</strong><br>
  Enfrente a IA em partidas emocionantes, dominando arremessos com controle de força, rebatidas precisas com timing milimétrico e estratégias defensivas completas!
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Godot%20Engine-4.x-478CBF?style=for-the-badge&logo=godotengine&logoColor=white" alt="Godot Engine 4">
  <img src="https://img.shields.io/badge/Linguagem-GDScript-355570?style=for-the-badge&logo=godotengine&logoColor=white" alt="GDScript">
  <img src="https://img.shields.io/badge/Plataforma-Windows%20Desktop-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows Desktop">
  <img src="https://img.shields.io/badge/Status-Concluído%20%2F%20Jogável-brightgreen?style=for-the-badge" alt="Status">
</p>

---

## 📋 Sumário

- [Visão Geral](#-visão-geral)
- [Principais Funcionalidades](#-principais-funcionalidades)
- [🎮 Controles do Jogo](#-controles-do-jogo)
- [⚾ Mecânicas Detalhadas](#-mecânicas-detalhadas)
  - [1. Arremesso (Pitching) e Controle de Força](#1-arremesso-pitching-e-controle-de-força)
  - [2. Rebatida (Batting) e Sistema de Timing](#2-rebatida-batting-e-sistema-de-timing)
  - [3. Sistema Defensivo e Eliminações (Fielding)](#3-sistema-defensivo-e-eliminações-fielding)
  - [4. Gerenciamento de Bases e Corredores](#4-gerenciamento-de-bases-e-corredores)
  - [5. Regras Oficiais e Ciclo da Partida](#5-regras-oficiais-e-ciclo-da-partida)
- [🤖 Inteligência Artificial da CPU](#-inteligência-artificial-da-cpu)
- [📁 Estrutura do Projeto](#-estrutura-do-projeto)
- [🚀 Como Executar o Jogo](#-como-executar-o-jogo)
  - [Opção 1: Executável Pré-Compilado (Windows)](#opção-1-executável-pré-compilado-windows)
  - [Opção 2: Pelo Editor da Godot Engine](#opção-2-pelo-editor-da-godot-engine)
  - [Opção 3: Executar os Testes Automatizados](#opção-3-executar-os-testes-automatizados)
- [⚙️ Configurações e Modos de Exibição](#️-configurações-e-modos-de-exibição)
- [🛠️ Tecnologias Utilizadas](#️-tecnologias-utilizadas)

---

## 🌟 Visão Geral

O **Jogo de Baseball 2D** é um projeto completo desenvolvido para reproduzir com fidelidade a emoção e as regras clássicas do baseball. O jogo apresenta uma partida em turnos alternados (**Innings**) entre o jogador e uma Inteligência Artificial balanceada:

* **Parte Superior da Entrada (TOP Inning):** Você comanda a **Defesa** no montinho de arremesso (*Pitcher*), escolhendo tipos de bolas e dosando a força para eliminar os batedores adversários.
* **Parte Inferior da Entrada (BOTTOM Inning):** Você assume o **Ataque** no bastão (*Batter*), lendo a trajetória dos arremessos da CPU para acertar rebatidas no tempo certo e conquistar corridas (*Runs*).

---

## ✨ Principais Funcionalidades

* **Física de Bola 2.5D:** Simulação realista que calcula deslocamento no plano X/Y, altura vertical (eixo Z), gravidade, quiques amortecidos e atrito com a grama e terra batida.
* **Mecânica de Arremesso com Carga (Hold & Release):** Segure o botão para carregar a barra de potência de 0% a 100%, variando a velocidade e o tempo de reação.
* **3 Tipos de Arremessos Únicos:** Fastball (bola rápida), Curveball (curva acentuada) e Changeup (quebra de ritmo).
* **Feedback de Rebatida em Milissegundos:** Avaliação precisa do contato (*Sweet Spot*, *Early*, *Late*) e classificação da trajetória (*Grounder*, *Line Drive*, *Fly Ball*, *Pop Up*, *Home Run*).
* **Defesa Ativa com 6 Defensores em Campo:** Infielders e Outfielders (Left, Center e Right Fielder) que correm dinamicamente para interceptar e arremessar a bola para a 1ª base.
* **Corredores e Avanço de Bases:** Sistema que rastreia corredores na 1B, 2B e 3B, computando avanços em rebatidas simples, duplas, triplas, walk e home runs.
* **Câmera Dinâmica Ampla:** Acompanhamento suave e cinematográfico da bola em jogadas profundas no outfield.
* **HUD Informativo e Intuitivo:** Exibição do placar em tempo real, contagem de bolas (*Balls*), *Strikes* e *Outs*, diagrama visual das bases ocupadas e indicador da barra de força.
* **Suporte Completo a Teclado e Mouse:** Jogue usando atalhos do teclado ou clicando diretamente nos botões interativos do HUD.
* **Modo Tela Cheia Inteligente:** Sistema persistente de escala e proporção (*Stretch Canvas Items*) que preserva o aspecto visual 16:9 em qualquer resolução ou monitor.

---

## 🎮 Controles do Jogo

O jogo pode ser controlado inteiramente pelo **Teclado** ou através dos **Botões na Tela** (compatível com Mouse ou telas Touch):

| Ação | Teclado | Interface (HUD) | Quando Usar |
| :--- | :---: | :---: | :--- |
| **Arremessar (Carregar Força)** | Segurar **`P`** | Botão **`ARREMESSAR [P]`** | Na **Defesa** (TOP Inning) |
| **Disparar o Arremesso** | Soltar **`P`** | Soltar o clique do botão | Na **Defesa** (TOP Inning) |
| **Selecionar Fastball (Reta)** | Tecla **`1`** | Botão **`1: FASTBALL`** | Na **Defesa** (TOP Inning) |
| **Selecionar Curveball (Curva)** | Tecla **`2`** | Botão **`2: CURVEBALL`** | Na **Defesa** (TOP Inning) |
| **Selecionar Changeup (Lenta)** | Tecla **`3`** | Botão **`3: CHANGEUP`** | Na **Defesa** (TOP Inning) |
| **Rebater (Swing)** | Tecla **`ESPAÇO`** | Botão **`REBATER [ESPAÇO]`** | No **Ataque** (BOTTOM Inning) |
| **Reiniciar Jogada / Partida** | Tecla **`R`** | Botão **`REINICIAR [R]`** | A qualquer momento ou no Fim de Jogo |
| **Alternar Tela Cheia (Fullscreen)** | — | Botão **`🖥️ TELA CHEIA`** | A qualquer momento no topo direito |

---

## ⚾ Mecânicas Detalhadas

### 1. Arremesso (Pitching) e Controle de Força

Ao arremessar, você pode escolher entre três tipos de arremesso e modular a intensidade do lançamento:

* **⚡ Fastball (Tecla 1):** O arremesso mais rápido (270 a 400 px/s). Viaja em linha reta e dá pouquíssimo tempo de reação ao batedor.
* **🔄 Curveball (Tecla 2):** Arremesso com efeito em arco (200 a 290 px/s). Desvia lateralmente em direção ao canto do home plate, quebrando o plano de swing.
* **⏳ Changeup (Tecla 3):** Arremesso desacelerado (140 a 210 px/s). Parece uma bola rápida no início, mas perde velocidade na aproximação, fazendo o batedor girar adiantado no vazio.
* **Mecânica de Carga:** Ao segurar a tecla `P` (ou o botão correspondente), o arremessador entra em postura de preparação e uma porcentagem de força aumenta até 100% em ~1.2 segundos. Quanto maior a carga, maior a velocidade de saída da bola.

---

### 2. Rebatida (Batting) e Sistema de Timing

Quando estiver no bastão, observe a chegada da bola sobre o *Home Plate* e aperte `ESPAÇO`:

* **Ponto Ideal (Sweet Spot - ~100ms):** Contato limpo que gera velocidade máxima de saída (*Exit Velocity* alta) e ângulo favorável, produzindo *Line Drives* fortes ou *Home Runs*.
* **Swing Adiantado (Early):** Puxa a bola em ângulo fechado para o lado esquerdo do campo. Se for muito cedo, vira *Foul Ball*.
* **Swing Atrasado (Late):** Empurra a bola para o campo direito. Se for muito tarde, também resulta em *Foul Ball*.
* **Swing no Vazio (Miss):** Se o taco passar muito antes ou depois da bola, resulta em *Strike* imediato.

---

### 3. Sistema Defensivo e Eliminações (Fielding)

O campo conta com defensores posicionados estrategicamente:
* **Pitcher e Catcher** (Montinho e Home Plate)
* **Infielders** cobrindo 1ª base, 2ª base e 3ª base
* **Outfielders** (Left Fielder, Center Fielder e Right Fielder)

Quando uma bola válida é rebatida:
1. O defensor mais próximo calcula a trajetória e corre para interceptar a bola.
2. **Fly Out:** Se o defensor alcançar a bola enquanto ela ainda estiver no ar, o batedor é **eliminado imediatamente**.
3. **Ground Out:** Se a bola tocar o chão, o defensor a recolhe e realiza o arremesso para a 1ª base. Se o arremesso chegar à base antes do tempo de corrida do batedor (~0.88s), é registrado um **Out**. Caso contrário, o batedor fica a salvo (**Safe!**).

---

### 4. Gerenciamento de Bases e Corredores

O módulo `BaseManager` controla o avanço dos corredores pelo diamante:
* **Single:** Avança todos os corredores em 1 base.
* **Double:** Avança todos os corredores em 2 bases.
* **Triple:** Avança todos os corredores em 3 bases.
* **Home Run:** Todos os corredores em base mais o batedor cruzam o *Home Plate*, somando pontos (*Runs*) para o time.
* **Walk (4 Balls):** O batedor avança forçadamente para a 1ª base, empurrando os demais corredores se as bases estiverem ocupadas.

---

### 5. Regras Oficiais e Ciclo da Partida

| Conceito | Regra Implementada |
| :--- | :--- |
| **Strike Zone** | Retângulo delimitado sobre o Home Plate (640, 620). Bolas que cruzam a zona sem tentativa de swing contam como **Strike**. |
| **Ball** | Bolas arremessadas fora da Strike Zone sem tentativa de swing pelo batedor contam como **Ball**. |
| **Strikeout** | Ao acumular **3 Strikes**, o batedor é eliminado. |
| **Walk** | Ao acumular **4 Balls**, o batedor ganha a 1ª base automaticamente. |
| **Foul Ball** | Rebatida para fora das linhas válidas do campo. Conta como strike caso o batedor tenha 0 ou 1 strike (com 2 strikes, a contagem não aumenta). |
| **3 Outs** | O time que está atacando encerra seu turno. Os times trocam de lado (*Change Sides*). |
| **Innings** | A partida é disputada em entradas completas (configurável para 3 ou 9 innings). Ao final, o time com maior pontuação vence. |

---

## 🤖 Inteligência Artificial da CPU

A CPU possui uma lógica de tomada de decisão probabilística e humanizada:
* **Leitura da Strike Zone:** Avalia se o arremesso está na zona de strike (75% de chance de tentar rebater) ou fora dela (22% de chance de perseguir bolas ruins).
* **Dificuldade por Tipo de Arremesso:** Sofre penalidades naturais de contato contra *Curveballs* (quebra de trajetória) e *Changeups* (quebra de ritmo).
* **Penalidade por Arremessos no Canto:** Bolas no limiar da zona de strike diminuem a chance de bom contato da CPU.
* **Erros Humanizados:** Quando a CPU falha, ela gera swings atrasados ou adiantados no vazio (*Swing & Miss*) e *Foul Balls* realistas.
* **Variação no Arremesso:** Quando a CPU está no montinho, ela alterna aleatoriamente entre bolas rápidas, curvas e lentas com cargas variadas de força.

---

## 📁 Estrutura do Projeto

```text
jogo-baseball/
├── build/                               # Compilação e executáveis para Windows
│   ├── Jogo-Baseball.exe               # Executável compilado do jogo
│   ├── Jogo-Baseball.pck               # Pacote de recursos do jogo
│   └── Jogo-Baseball-Windows.zip       # Pacote zip pronto para distribuição
├── scenes/                              # Cenas organizadas (.tscn)
│   ├── ball/
│   │   └── ball.tscn                   # Cena da bola de baseball
│   ├── field/
│   │   └── field.tscn                  # Campo, diamante, gramado e marcas
│   ├── game/
│   │   ├── base_manager.tscn           # Gerenciador de corredores nas bases
│   │   ├── defense_manager.tscn        # Gerenciador dos defensores e jogadas
│   │   └── main.tscn                   # Cena principal da partida
│   ├── players/
│   │   ├── batter.tscn                 # Batedor com animação de swing
│   │   ├── catcher.tscn                # Catcher agachado com luva
│   │   ├── fielder.tscn                # Defensores de campo (Infield e Outfield)
│   │   ├── pitcher.tscn                # Arremessador no montinho
│   │   └── runner.tscn                 # Corredor que percorre as bases
│   └── ui/
│       └── hud.tscn                    # Placar, contagem, botões e avisos visuais
├── scripts/                             # Scripts em GDScript (.gd)
│   ├── ball/
│   │   └── ball.gd                     # Física 2.5D da bola e detecção de zona
│   ├── field/
│   │   └── field.gd                    # Renderização procedural do campo e regras Fair/Foul/HR
│   ├── game/
│   │   ├── base_manager.gd             # Lógica de ocupação e avanço de bases
│   │   ├── defense_manager.gd          # Lógica de perseguição da bola e eliminações
│   │   ├── display_settings.gd         # Gerenciamento de tela cheia e escala
│   │   ├── game_camera.gd              # Câmera com interpolação suave
│   │   └── game_manager.gd             # Máquina de estados principal e regras da partida
│   ├── players/
│   │   ├── batter.gd                   # Lógica de bastão, sweet spot e faíscas de contato
│   │   ├── catcher.gd                  # Lógica de recepção da bola
│   │   ├── fielder.gd                  # Lógica de movimentação dos defensores
│   │   ├── pitcher.gd                  # Lógica de arremesso, carga e tipos de bola
│   │   └── runner.gd                   # Movimentação dos corredores entre os pontos das bases
│   └── ui/
│       └── hud.gd                      # Atualização do placar, animações e feedback
├── test_pitching_mechanics.gd           # Suíte de testes unitários de arremesso
├── test_player_vs_cpu.gd                # Suíte de testes integrados de jogabilidade e IA
├── export_presets.cfg                   # Configurações de exportação para Windows Desktop
├── icon.png                             # Ícone oficial em Pixel Art do jogo
└── project.godot                        # Arquivo de configuração principal da Godot
```

---

## 🚀 Como Executar o Jogo

### Opção 1: Executável Pré-Compilado (Windows)

Não é necessário ter a Godot instalada para jogar:
1. Navegue até a pasta [`build/`](build/).
2. Execute o arquivo **`Jogo-Baseball.exe`**.
3. O jogo iniciará imediatamente na resolução padrão de 1280x720 (redimensionável ou tela cheia).

---

### Opção 2: Pelo Editor da Godot Engine

1. Baixe e instale a **Godot Engine 4** (versão 4.2 ou superior) em [godotengine.org](https://godotengine.org/).
2. Abra a Godot e clique no botão **"Import" (Importar)**.
3. Selecione o arquivo [`project.godot`](project.godot) na raiz deste repositório.
4. Clique em **"Edit" (Editar)** para abrir o projeto.
5. Pressione **`F5`** (ou clique no ícone de Play no canto superior direito) para iniciar a partida.

---

### Opção 3: Executar os Testes Automatizados

O projeto inclui suítes de testes automatizados escritas em GDScript:

* **Teste de Mecânicas de Arremesso:**
  ```bash
  godot --headless -s test_pitching_mechanics.gd
  ```
* **Teste Completo de Gameplay (Player vs CPU e Regras):**
  ```bash
  godot --headless -s test_player_vs_cpu.gd
  ```

Os testes validam automaticamente posições iniciais, físicas de lançamento, zoom de câmera, escala de tela cheia e lógica de avanço das bases.

---

## ⚙️ Configurações e Modos de Exibição

* **Resolução Base:** 1280 x 720 (16:9).
* **Modo de Escala:** `Canvas Items` com aspecto `Keep` (mantém as proporções corretas em monitores ultrawide, widescreen ou 4:3 sem distorções visuais).
* **Tela Cheia:** Pressione o botão **`🖥️ TELA CHEIA`** no canto superior direito do HUD para alternar entre o modo janela e o modo tela cheia exclusivo. A configuração é salva automaticamente no arquivo `user://display_settings.cfg`.

---

## 🛠️ Tecnologias Utilizadas

* **Engine:** [Godot Engine 4](https://godotengine.org/) (Forward+ / GL Compatibility).
* **Linguagem:** GDScript 2.0.
* **Arte e Gráficos:** Renderização vetorial procedural 2D nativa da Godot (`_draw()`), proporcionando visuais nítidos em qualquer resolução sem perda de qualidade.
* **Ícone:** Pixel Art autoral customizado para a identidade visual do projeto.

---

<p align="center">
  Desenvolvido com dedicação para a disciplina de Jogos / Projetos de TI. ⚾ Divirta-se jogando!
</p>
