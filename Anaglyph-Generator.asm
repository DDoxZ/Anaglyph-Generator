extern terminate
extern printStrLn
extern readImageFile
extern writeImageFile

;====================================================================================================

section .data
LF equ 10
NULL equ 0
MAX_IMG_SIZE equ 1048576

INVALID_ARGS_MESSAGE db "Please insert >> ./Anaglifo <C or M> <left_image_name.bmp> <right_image_name.bmp> <anaglyph_name.bmp>", NULL
INVALID_ARGS_NUNMBER db "Please insert a valid number of arguments as shown >> ./Anaglifo <C or M> <left_image_name.bmp> <right_image_name.bmp> <anaglyph_name.bmp>", NULL
 
R_MULTIPLIER dd 0.299
G_MULTIPLIER dd 0.587
B_MULTIPLIER dd 0.114

;====================================================================================================

section .bss

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
    mov cl, [rsp]             
    cmp cl, 5                 
    jne invalidArgsNumber

    mov rdi, [rsp+16]         
    call argsCheck            

    mov rdi, [rsp+24]         
    mov rsi, buffer_esq       
    call readImageFile        
    mov rdi, [rsp+32]         
    mov rsi, buffer_dir       
    call readImageFile        

    xor ecx, ecx
writeHeader:                  
    mov al, [buffer_esq+ecx]  
    mov [buffer_ana+ecx], al
    inc ecx
    cmp ecx, [buffer_esq+10]
    jne writeHeader

    mov rdi, [rsp+16]         
    call algExe               
   
    mov rdi, [rsp+40]         
    mov rsi, buffer_ana       
    mov rdx, [buffer_esq+2]   
    call writeImageFile       
    call terminate            

;====================================================================================================
; argsCheck
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
;====================================================================================================
algExe:
    cmp byte [rdi], 'C'     
    je algColorSelected     
    call algMono
    jmp algExeReturn

algColorSelected:
    call algColor

algExeReturn:
    ret

;====================================================================================================
; algColor
;====================================================================================================
algColor:
    xor ecx, ecx                       
    mov ecx, [buffer_dir+10]           
loopColor:
    cmp ecx, [buffer_dir+2]             
    jge endColor                       

    mov al, [buffer_dir+ecx]           
    mov [buffer_ana+ecx], al

    mov al, [buffer_dir+ecx+1]         
    mov [buffer_ana+ecx+1], al

    mov al, [buffer_esq+ecx+2]         
    mov [buffer_ana+ecx+2], al

    mov byte [buffer_ana+ecx+3], 0xFF  

    add ecx, 4                         
    jmp loopColor                      

endColor:
    ret

;====================================================================================================
; algMono
;====================================================================================================
algMono:
    xor ecx, ecx                       
    mov ecx, [buffer_esq+10]           
loopMono:
    cmp ecx, [buffer_esq+2]            
    jge endMono                        

    mov al, [buffer_dir+ecx]           
    cvtsi2ss xmm0, eax                 
    mov al, [buffer_dir+ecx+1]
    cvtsi2ss xmm1, eax                 
    mov al, [buffer_dir+ecx+2]
    cvtsi2ss xmm2, eax                  
    mulss xmm0, [B_MULTIPLIER]         
    mulss xmm1, [G_MULTIPLIER]         
    mulss xmm2, [R_MULTIPLIER]         
    addss xmm0, xmm1                   
    addss xmm0, xmm2                   
    cvtss2si eax, xmm0                 
    mov [buffer_ana+ecx], al           
    mov [buffer_ana+ecx+1], al         

    mov al, [buffer_esq+ecx]           
    cvtsi2ss xmm0, eax                 
    mov al, [buffer_esq+ecx+1]
    cvtsi2ss xmm1, eax                 
    mov al, [buffer_esq+ecx+2]
    cvtsi2ss xmm2, eax                 
    mulss xmm0, [B_MULTIPLIER]         
    mulss xmm1, [G_MULTIPLIER]         
    mulss xmm2, [R_MULTIPLIER]         
    addss xmm0, xmm1                   
    addss xmm0, xmm2                   
    cvtss2si eax, xmm0                 
    mov [buffer_ana+ecx+2], al         

    mov byte [buffer_ana+ecx+3], 0xFF  
    add ecx, 4                         
    jmp loopMono                       

endMono:
    ret

invalidArgs:
    mov rdi, INVALID_ARGS_MESSAGE
    call printStrLn
    call terminate

invalidArgsNumber:
    mov rdi, INVALID_ARGS_NUNMBER
    call printStrLn
    call terminate
