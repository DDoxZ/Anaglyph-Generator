extern terminate
extern printStrLn
extern readImageFile
extern writeImageFile

;====================================================================================================

section .data
; constantes
LF equ 10
NULL equ 0
MAX_IMG_SIZE equ 1048576

; mensagens de erro
INVALID_ARGS_MESSAGE db "Please insert >> ./Anaglifo <C or M> <left_image_name.bmp> <right_image_name.bmp> <anaglyph_name.bmp>", NULL
INVALID_ARGS_NUNMBER db "Please insert a valid number of arguments as shown >> ./Anaglifo <C or M> <left_image_name.bmp> <right_image_name.bmp> <anaglyph_name.bmp>", NULL

; multiplicadores 
R_MULTIPLIER dd 0.299
G_MULTIPLIER dd 0.587
B_MULTIPLIER dd 0.114


;====================================================================================================

section .bss

; reserva de espaco para os buffers
buffer_esq:
    resb MAX_IMG_SIZE
buffer_dir:
    resb MAX_IMG_SIZE
buffer_ana:
    resb MAX_IMG_SIZE

;====================================================================================================

section .text
global _start
_start:
    mov cl, [rsp]             ; verificar a quantidade de argumentos
    cmp cl, 5                 
    jne invalidArgsNumber

    mov rdi, [rsp+16]         ; verificar se o 1o argumento (algoritmo) E valido
    call argsCheck            

    mov rdi, [rsp+24]         
    mov rsi, buffer_esq       
    call readImageFile        ; carregar a imagem da esquerda para o respetivo buffer
    mov rdi, [rsp+32]         
    mov rsi, buffer_dir       
    call readImageFile        ; carregar a imagem da direita para o respetivo buffer

    xor ecx, ecx
writeHeader:                  ; escrever o cabecalho do novo anaglifo
    mov al, [buffer_esq+ecx]  ; para isso podemos copiar o de uma das imagens
    mov [buffer_ana+ecx], al
    inc ecx
    cmp ecx, [buffer_esq+10]
    jne writeHeader

    mov rdi, [rsp+16]         ; passagem do algoritmo escolhido
    call algExe               ; escolhe o algoritmo que o utilizador escreveu e executa-o
   
    mov rdi, [rsp+40]         ; passagem do nome do ficheiro final (o mesmo que o utilizador escolheu no ultimo param)
    mov rsi, buffer_ana       ; passagem do buffer que contém os bytes da imagem modificada para a escrever
    mov rdx, [buffer_esq+2]   ; quantidade de bytes para escrever no anaglifo (ficheiro final)
    call writeImageFile       ; produzir anaglifo (ficheiro final)
    call terminate            ; terminar o programa

;====================================================================================================
; argsCheck
; Objetivo: Verificar se o primeiro argumento corresponde a C ou M, caso nao seja, erro
; Entrada : 
;   RDI - Conteudo do primeiro argumento
; Saida : Nada
; Destrói: Nada
;====================================================================================================
argsCheck:      
    cmp byte [rdi+1], 0
    jne invalidArgs            
    cmp byte [rdi], 'C'      
    je argCheckReturn        
    cmp byte [rdi], 'M'      
    je argCheckReturn
    jmp invalidArgs

argCheckReturn:
    ret

;====================================================================================================
; algExe
; Objetivo: Ver a escolha do utilizador no que toca ao algoritmo e executá-lo
; Entrada : 
;   RDI - Conteúdo do primeiro argumento
; Saida : Nada
; Destrói: Nada
;====================================================================================================
algExe:
    cmp byte [rdi], 'C'     ; Se o algoritmo escolhido foi o Color executamos o algoritmo Color
    je algColorSelected     ; senão, executamos o algoritmo Mono
    call algMono
    jmp algExeReturn

algColorSelected:
    call algColor

algExeReturn:
    ret

;====================================================================================================
; algColor
; Objetivo: Executar o algoritmo color, onde guarda numa imagem os pixeis vermelhos da imagem da
;           esquerda, e os verdes e azuis da imagem da direita. Os pixeis Alfa = 0xFF
; Entrada : Nada
; Saida : Nada
; Destrói: ecx, al
;====================================================================================================
algColor:
    xor ecx, ecx                       ; ecx = 0
    mov ecx, [buffer_dir+10]           ; ecx = offset da imagem direita = das outras imagens
loopColor:
    cmp ecx, [buffer_dir+2]            ; comparar com o size da imagem da direita = das outras imagens, 
    jge endColor                       ; quando chegar ao mesmo termina

    mov al, [buffer_dir+ecx]           ; pixeis azuis da imagem da direita para o anaglifo
    mov [buffer_ana+ecx], al

    mov al, [buffer_dir+ecx+1]         ; pixeis verdes da imagem da direita para o anaglifo
    mov [buffer_ana+ecx+1], al

    mov al, [buffer_esq+ecx+2]         ; pixeis vermelhos da imagem da esquerda para o anaglifo
    mov [buffer_ana+ecx+2], al

    mov byte [buffer_ana+ecx+3], 0xFF  ; pixeis alfa da imagem do anaglifo = 0xFF

    add ecx, 4                         ; adicionar 4 ao indice para saltar de pixel em pixel
    jmp loopColor                      ; repetir ate modificar toda a imagem

endColor:
    ret

;====================================================================================================
; algMono
; Objetivo: Executar o algoritmo mono, onde: r_a = 0.299*r_e + 0.587*g_e + 0.114*b_e
;                                            g_a = 0.299*r_d + 0.587*g_d + 0.114*b_d
;                                            b_a = g_a
;                                            A_a = 0xFF
;           Sendo r -> pixeis vermelhos, g -> pixeis verdes, b -> pixeis azuis, A -> alfa
;           e     a -> anaglifo, e -> imagem da esquerda, d -> imagem da direita
;
; Entrada : Nada
; Saida : Nada
; Destrói: ecx, al, xmm0, xmm1, xmm2
;====================================================================================================
algMono:
    xor ecx, ecx                       ; ecx = 0
    mov ecx, [buffer_esq+10]           ; ecx = offset da imagem esquerda = das outras imagens
loopMono:
    cmp ecx, [buffer_esq+2]            ; comparar com o size da imagem da esquerda = das outras imagens, com esta imagem
    jge endMono                        ; quando chegar ao mesmo termina

    mov al, [buffer_dir+ecx]           ; Para os pixeis azuis e verdes do anaglifo:
    cvtsi2ss xmm0, eax                 ; converter o valor dos pixeis azuis da imagem da direita para virgula flutuante
    mov al, [buffer_dir+ecx+1]
    cvtsi2ss xmm1, eax                 ; converter o valor dos pixeis verdes da imagem da direita para virgula flutuante
    mov al, [buffer_dir+ecx+2]
    cvtsi2ss xmm2, eax                 ; converter o valor dos pixeis vermelhos da imagem da direita para virgula flutuante
    mulss xmm0, [B_MULTIPLIER]         ; multiplicar o valor dos pixeis azuis por 0.114
    mulss xmm1, [G_MULTIPLIER]         ; multiplicar o valor dos pixeis verdes por 0.587
    mulss xmm2, [R_MULTIPLIER]         ; multiplicar o valor dos pixeis vermelhos por 0.299
    addss xmm0, xmm1                   ; somar os 3 valores
    addss xmm0, xmm2                   ; continuacao da soma dos 3 valores
    cvtss2si eax, xmm0                 ; converter o valor final novamente para inteiros
    mov [buffer_ana+ecx], al           ; guardar o valor nos pixeis azuis do anaglifo
    mov [buffer_ana+ecx+1], al         ; guardar o valor nos pixeis verdes do anaglifo

    mov al, [buffer_esq+ecx]           ; Para os pixeis vermelhos do anaglifo:
    cvtsi2ss xmm0, eax                 ; converter o valor dos pixeis azuis da imagem da esquerda para virgula flutuante
    mov al, [buffer_esq+ecx+1]
    cvtsi2ss xmm1, eax                 ; converter o valor dos pixeis verdes da imagem da esquerda para virgula flutuante
    mov al, [buffer_esq+ecx+2]
    cvtsi2ss xmm2, eax                 ; converter o valor dos pixeis vermelhos da imagem da esquerda para virgula flutuante
    mulss xmm0, [B_MULTIPLIER]         ; multiplicar o valor dos pixeis azuis por 0.114
    mulss xmm1, [G_MULTIPLIER]         ; multiplicar o valor dos pixeis verdes por 0.587
    mulss xmm2, [R_MULTIPLIER]         ; multiplicar o valor dos pixeis vermelhos por 0.299
    addss xmm0, xmm1                   ; somar os 3 valores
    addss xmm0, xmm2                   ; continuacao da soma dos 3 valores
    cvtss2si eax, xmm0                 ; converter o valor final novamente para inteiros
    mov [buffer_ana+ecx+2], al         ; guardar o valor nos pixeis vermelhos do anaglifo

    mov byte [buffer_ana+ecx+3], 0xFF  ; pixeis alfa da imagem do anaglifo = 0xFF
    add ecx, 4                         ; adicionar 4 ao indice para saltar de pixel em pixel
    jmp loopMono                       ; repetir ate modificar toda a imagem

endMono:
    ret

; execucao das mensagens de erro quando necessario
invalidArgs:
    mov rdi, INVALID_ARGS_MESSAGE
    call printStrLn
    call terminate

invalidArgsNumber:
    mov rdi, INVALID_ARGS_NUNMBER
    call printStrLn
    call terminate
