# Anaglyph-Generator

## Computer Systems Architecture Project

## About

Anaglyph Generator in x86-64bit assembly in the format Intel for nasm.
Creates an anaglyph from two images of a stereogram, using a color algorithm or a mono algorithm.

## Learned
 - x86-64bit assembly in the format Intel for nasm
 - BMP format, visualization and manipulation
 - COLOR and MONO algorithms for anaglyph generation

---
## Operations

```bash
./Anaglyph C [left_image.bmp] [right_image.bmp] [final_anaglyph_desired_name.bmp]
```
```bash
./Anaglyph M [left_image.bmp] [right_image.bmp] [final_anaglyph_desired_name.bmp]
```


---
## Compilation

```bash
nasm -F dwarf -f elf64 Biblioteca.asm
```
```bash
nasm -F dwarf -f elf64 Anaglyph-Generator.asm
```
```bash
ld Anaglyph-Generator.o Biblioteca.o -o Anaglyph
```


---
## Execution

```bash
./Anaglyph C [left_image.bmp] [right_image.bmp] [final_anaglyph_desired_name.bmp]
```
```bash
./Anaglyph M [left_image.bmp] [right_image.bmp] [final_anaglyph_desired_name.bmp]
```
 
