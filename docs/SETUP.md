# Instalação

## Opção 1 — carregador

1. Entre na experiência e abra o ambiente cliente compatível.
2. Execute o carregador abaixo:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kawanzyn/UltraBoost-Release-/main/UltraBoost.lua"))()
```

3. Comece pelo modo **Equilibrado**; compare com **Ultra** na mesma área.
4. Use **Restaurar original** antes de sair ou feche pelo botão ×.

O carregador exige que o executor disponibilize `loadstring` e `game:HttpGet`. A disponibilidade e o comportamento dessas funções variam entre ambientes e versões. Não há garantia de compatibilidade com qualquer build do Delta.

## Opção 2 — arquivo completo

Abra [UltraBoost.lua](../UltraBoost.lua), copie o conteúdo inteiro e execute-o em um contexto cliente compatível.

## Recomendações

- Teste primeiro em uma experiência privada/de teste.
- Compare a mesma cena, ângulo de câmera e qualidade gráfica.
- Não ative ocultação de texturas quando ela puder esconder placas, pistas ou informações do jogo.
- Use Restaurar original para reverter as alterações.
- Não use o projeto para alterar gameplay, interferir em outros jogadores ou contornar sistemas de proteção.
