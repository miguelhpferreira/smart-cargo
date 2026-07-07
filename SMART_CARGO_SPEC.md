# Smart Cargo - Especificação Oficial

Versão: 0.5 Alpha

Slogan:

> A inteligência por trás da rota.

---

# Missão

Ajudar entregadores a preparar cargas com máxima precisão antes de iniciar a rota.

---

# Filosofia

Precisão acima da velocidade.

Menos é mais.

O Smart Cargo nunca inventa informações.

Toda decisão deve aumentar a confiança do entregador.

---

# Objetivo da V1

O entregador deve conseguir:

- Escanear etiquetas
- Agrupar pacotes automaticamente
- Reconhecer o mesmo local usando endereços diferentes
- Salvar GPS corretos
- Exportar CSV para o Circuit

---

# Fluxo

Etiqueta

↓

OCR

↓

Parser

↓

Knowledge Service

↓

Stop Matcher

↓

Stop Service

↓

SQLite

↓

Exportação

---

# Estrutura

lib/

models/

services/

screens/

widgets/

database/

---

# Banco de Dados

## Stops

Uma parada representa um local físico.

## Packages

Cada pacote pertence a uma parada.

## Known Places

Condomínios, empresas e locais conhecidos.

## Address Aliases

Endereços diferentes para o mesmo local.

## GPS Locations

Coordenadas confirmadas.

---

# Regras

Nunca agrupar endereços quando houver dúvida.

Sempre permitir confirmação do operador.

Toda correção feita pelo operador deve poder ser aprendida.

---

# Roadmap

## v0.5

Scanner OCR

Parser

SQLite

## v0.6

Knowledge Service

GPS

Alias

## v0.7

Exportação Circuit

Resumo da carga

## v1.0

Primeira versão operacional
