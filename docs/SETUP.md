# Instalação e utilização

## Arquivo standalone

O arquivo independente é dist/UltraBoost.lua no repositório privado e UltraBoost.lua no repositório público.

Para um ambiente cliente compatível que permita carregamento remoto, o carregador é:

    loadstring(game:HttpGet("https://raw.githubusercontent.com/kawanzyn/UltraBoost-Release-/main/UltraBoost.lua"))()

O carregador requer que o ambiente ofereça loadstring e game:HttpGet. Como alternativa, use o conteúdo completo do arquivo standalone em um contexto cliente compatível.

## Controles

1. **Ultra:** reduz a apresentação do cenário e oculta peças ambientais classificadas. O chão deve continuar visível.
2. **Equilibrado:** aplica uma aparência branca ao cenário compatível.
3. **Leve:** simplifica materiais e remove texturas/mapas compatíveis, preservando cores quando possível.
4. **Colisão ambiental:** alterna alterações locais de colisão em peças ancoradas elegíveis. Vem desligado por padrão e não garante atravessar obstáculos controlados pelo servidor.
5. **Monitor FPS:** liga/desliga a estimativa local.
6. **Restaurar original:** reverte as propriedades registradas pelo script.
7. **Mover interface:** arraste o cabeçalho para reposicionar o painel; quando minimizado, arraste o botão flutuante `UB`.
8. **Minimizar:** recolhe o painel sem encerrar o otimizador.
9. **Fechar (×):** restaura configurações e encerra o painel/conexões.

## Notas

- O chão é excluído da invisibilidade ambiental e da alteração de colisão.
- Personagens, modelos com Humanoid, ferramentas e objetos com nomes associados à jogabilidade são protegidos quando reconhecidos pela classificação.
- A classificação é heurística e pode variar de acordo com a hierarquia e a nomenclatura de cada experiência.
- Use a restauração antes de sair. Fechar o painel também restaura as alterações.
- A varredura inicial é processada em pequenas fatias para reduzir picos de CPU; mapas muito grandes ainda podem levar algum tempo para serem processados.
- Não há garantia de compatibilidade com toda versão de executor ou cliente.
