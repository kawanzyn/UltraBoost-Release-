# Notas de compatibilidade

## Alvo de implementação

O arquivo standalone utiliza APIs padrão do cliente, incluindo Players.LocalPlayer, PlayerGui, Instance.new, Workspace, Lighting, DescendantAdded, Heartbeat e propriedades de instâncias acessíveis pelo cliente.

Ele evita funções específicas de executor, APIs ocultas, chamadas remotas, remoção de instâncias e bypass de anticheat. O carregador opcional, por outro lado, requer que o ambiente ofereça loadstring e game:HttpGet.

## Estado conhecido

| Ambiente | Estado |
|---|---|
| Roblox Studio, em experiência própria | Ambiente de referência para a implementação modular; requer validação prática |
| Delta no Android | Compatibilidade não verificada em build/aparelho específico |
| Delta no iOS | Compatibilidade não verificada em build/aparelho específico |
| Outros executores | Não garantido |

Usar APIs padrão não assegura que qualquer executor ofereça o contexto, as permissões ou o comportamento necessários. O nome do executor, sem a versão exata, também não identifica um runtime imutável.

## Modos e classificação

- **Ultra** usa LocalTransparencyModifier em peças ambientais classificadas e conserva as peças reconhecidas como chão.
- **Equilibrado** modifica localmente cor e material de peças ambientais e tenta uniformizar as cores do Terrain.
- **Leve** simplifica materiais e tenta limpar mapas de SurfaceAppearance, além de ocultar Decal e Texture compatíveis.
- A classificação usa nomes, hierarquia, modelos com Humanoid e dimensões de superfícies horizontais. É heurística, não uma compreensão semântica do mapa.
- NPCs/modelos com Humanoid, personagens, ferramentas e nomes reconhecidos como objetos de gameplay são protegidos quando identificados.
- A detecção de novos objetos usa eventos de adição; a varredura inicial usa fatias de tempo e pula subárvores protegidas.
- Os snapshots de restauração usam referências fortes até a recuperação dos valores originais, evitando perda prematura de referências.
- O painel standalone e seu botão flutuante aceitam arrasto por toque ou mouse.

## Colisão local

O controle é separado dos modos visuais e vem desligado por padrão. Somente peças ambientais ancoradas que passem pelos critérios de classificação podem ter CanCollide alterado localmente. Chão, personagens, ferramentas e objetos protegidos são excluídos.

Uma alteração local de CanCollide não garante atravessar paredes ou obstáculos: a autoridade do servidor, a propriedade de rede e a lógica da experiência podem corrigir ou ignorar a alteração.

## Limitações

- O script atua somente no cliente local. Não melhora tempo de quadro do servidor, replicação, ping ou o dispositivo de outros jogadores.
- Alterações locais podem reduzir trabalho de renderização, mas não garantem descarregamento de assets nem redução de RAM.
- Algumas experiências usam partículas, luzes, pós-efeitos, decals e texturas para comunicar informações de gameplay.
- O número de FPS é uma estimativa derivada de Heartbeat, não um profiler.
- APIs e comportamento podem mudar com atualizações do cliente ou do executor.

Não marque compatibilidade com Delta como verificada até que uma build específica, num aparelho identificado, passe pela validação funcional apropriada.
