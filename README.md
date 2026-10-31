# UltraBoost 🚀

**Otimização visual local para clientes de jogos Roblox.** O UltraBoost oferece perfis reversíveis que tentam reduzir parte do trabalho de renderização em cenas nas quais efeitos e sombras sejam um gargalo.

> **Estado: experimental — v0.2.0.** Ainda não há validação confirmada em aparelhos reais nem compatibilidade verificada com builds específicas do Delta. Os resultados variam de acordo com jogo, cena, aparelho e gargalo.

## Carregador

Copie esta linha para um ambiente cliente compatível:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/kawanzyn/UltraBoost-Release-/main/UltraBoost.lua"))()
```

O carregador depende de o executor oferecer `loadstring` e `game:HttpGet`. Essas funções pertencem ao ambiente que executa o carregador; o arquivo principal `UltraBoost.lua` usa APIs padrão do cliente e não depende de funções internas específicas de executores.

Arquivo direto: [UltraBoost.lua](UltraBoost.lua)

## Controles

- **Ultra:** desativa localmente efeitos visuais selecionados e sombras.
- **Equilibrado:** restaura a maioria das propriedades visuais monitoradas e mantém pós-processamento desativado.
- **Texturas/decals:** opção manual para ocultar decalques e texturas; vem desligada porque pode esconder sinais e informações úteis.
- **Restaurar original:** recupera os valores originais das propriedades modificadas.
- **×:** restaura as configurações e fecha o painel.

## Instalação e testes

Leia [Setup](docs/SETUP.md), [Compatibilidade](docs/COMPATIBILITY.md) e [Checklist de testes](docs/TESTING.md).

## Limitações importantes

- Não promete FPS específico, redução garantida de RAM, menor ping ou melhoria de desempenho do servidor.
- Alterar a transparência de uma textura não significa descarregar seu asset da memória.
- Atua apenas no cliente local; não altera estado do servidor, scripts de gameplay ou outros jogadores.
- Não remove instâncias, não chama eventos remotos e não tenta contornar anti-cheat.
- Use apenas em ambientes nos quais scripts locais sejam permitidos.

## Licença

MIT. Consulte [LICENSE](LICENSE).
