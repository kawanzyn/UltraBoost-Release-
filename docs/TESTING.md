# Checklist de validação

Este documento separa validações estáticas no repositório de verificações funcionais que precisam de um ambiente de execução. Compilar o Luau não comprova o comportamento visual ou o ganho de desempenho.

## Validação no repositório

- [ ] Compilar todos os arquivos .lua em src/ e dist/.
- [ ] Confirmar que o arquivo standalone contém Ultra, Equilibrado, Leve, monitor, controle de colisão e restauração.
- [ ] Revisar que a detecção incremental não inicia varreduras recorrentes.
- [ ] Verificar que visual e colisão usam snapshots separados.
- [ ] Verificar que o chão é excluído da ocultação ambiental e das alterações de colisão.
- [ ] Confirmar que o fluxo de publicação copia a versão standalone e os documentos correspondentes.
- [ ] Revisar o diff para excluir alterações não relacionadas.

## Verificações funcionais futuras

Em uma experiência de teste na qual scripts locais sejam permitidos:

- [ ] Confirmar que os três botões aplicam comportamentos visuais distintos.
- [ ] Confirmar que personagens, NPCs identificáveis e objetos de gameplay protegidos continuam visíveis.
- [ ] Confirmar que o chão permanece visível em todos os modos.
- [ ] Confirmar que o chão mantém a colisão original.
- [ ] Confirmar que o controle de colisão só afeta peças ambientais elegíveis.
- [ ] Adicionar peças/efeitos durante cada modo e confirmar a detecção automática.
- [ ] Alternar repetidamente entre os modos e verificar a restauração dos valores originais.
- [ ] Testar a restauração de Decal.Transparency, Texture.Transparency e dos mapas ColorMap/NormalMap/RoughnessMap/MetalnessMap de SurfaceAppearance.
- [ ] Desativar colisão e verificar a recuperação de CanCollide.
- [ ] Fechar o painel e confirmar restauração e desconexão dos eventos.
- [ ] Executar novamente o script após fechar e verificar ausência de painel/conexões duplicados.

## Avaliação de desempenho

- [ ] Comparar a mesma cena, ângulo de câmera e qualidade gráfica antes/depois de cada modo.
- [ ] Repetir medições e comparar mediana de FPS ou tempo de quadro.
- [ ] Comparar também durante a varredura inicial e depois que ela termina, para separar custo temporário de custo persistente.
- [ ] Separar FPS, memória, rede e desempenho do servidor; são métricas diferentes.
- [ ] Registrar modelo do aparelho, sistema operacional, versão do cliente, versão do executor, experiência e cena.
- [ ] Não afirmar aumento garantido de FPS ou redução de RAM com base em uma única observação.

A tela FPS do UltraBoost é uma estimativa leve, não substitui profiler e não demonstra causalidade entre o modo e uma eventual variação de desempenho.
