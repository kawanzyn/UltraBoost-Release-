# UltraBoost 🚀

UltraBoost é um otimizador visual executado no cliente, com três modos reversíveis para reduzir efeitos e simplificar a apresentação do cenário em dispositivos com recursos limitados.

> O ganho depende do jogo, da cena, do aparelho e do gargalo real. O UltraBoost não garante FPS específico, redução de RAM, menor ping ou melhoria do desempenho do servidor.

## Versões

- **dist/UltraBoost.lua** — arquivo standalone com interface adaptada para toque.
- **src/** — implementação modular para experiências próprias ou ambientes nos quais você tenha autorização para editar.

## Modos do arquivo standalone

- **Ultra:** oculta localmente peças ambientais classificadas como cenário, simplifica superfícies, reduz sombras e desativa efeitos selecionados. O chão permanece visível e sua colisão não é alterada pelo modo.
- **Equilibrado:** aplica branco às peças ambientais e às cores de material do Terrain, simplifica materiais e reduz efeitos selecionados.
- **Leve:** aplica SmoothPlastic e remove mapas/texturas compatíveis, preservando as cores das peças sempre que possível.
- **Colisão ambiental:** controle separado, desligado por padrão. Atua somente em peças ambientais ancoradas que passem pelos critérios de proteção. O chão, personagens, ferramentas e objetos com nomes associados a elementos de gameplay são excluídos.
- **Monitor FPS:** estimativa local atualizada em intervalos aproximados; pode ser desligada na interface.
- **Restaurar original:** recupera as propriedades capturadas antes das alterações, incluindo transparência de Decal/Texture e mapas de SurfaceAppearance.
- **Interface móvel:** arraste o cabeçalho para mover o painel e arraste o botão `UB` quando minimizado.
- **Fechar (×):** restaura as propriedades e encerra as conexões do painel.

Os critérios de identificação do cenário são heurísticos. Experiências com nomes ou hierarquias incomuns podem exigir ajustes; objetos protegidos por classificação conservadora podem não ser otimizados.

## Instalação

Arquivo público: https://github.com/kawanzyn/UltraBoost-Release-/blob/main/UltraBoost.lua

Carregador para ambientes que ofereçam loadstring e game:HttpGet:

    loadstring(game:HttpGet("https://raw.githubusercontent.com/kawanzyn/UltraBoost-Release-/main/UltraBoost.lua"))()

O carregador depende de recursos do ambiente de execução. O arquivo principal evita funções específicas de executor e utiliza APIs padrão do cliente. Isso, por si só, não comprova compatibilidade com todas as versões do Delta ou dispositivos.

Veja docs/SETUP.md, docs/COMPATIBILITY.md, docs/TESTING.md e docs/PUBLISHING.md.

## Limitações importantes

- As alterações são locais; não alteram o estado autoritativo do servidor, outros jogadores ou scripts de gameplay.
- Desativar localmente a colisão de uma peça não garante atravessar uma parede. A simulação e a validação do servidor podem prevalecer.
- O chão é protegido contra invisibilidade e alterações de colisão pelo UltraBoost.
- Efeitos e mapas de textura podem conter informação útil. A simplificação visual pode ocultar detalhes importantes.
- Alterar transparência ou mapas não significa descarregar os assets da memória.
- O FPS mostrado é uma estimativa baseada em Heartbeat, não um profiler nem uma medição de RAM.
- A varredura inicial é dividida em pequenas fatias de processamento para reduzir picos de tempo de quadro; ainda pode haver custo temporário em mapas muito grandes.
- O comportamento visual e o desempenho precisam ser verificados em cada ambiente-alvo; não há garantia universal.

## Segurança e escopo

O projeto não apaga instâncias, não dispara RemoteEvents, não altera estado do servidor e não implementa bypass de anticheat. Use apenas onde scripts locais sejam permitidos.

## Licença

MIT. Consulte LICENSE.
