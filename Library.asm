;********************************************************************
section .data
;********************************************************************
LF                  equ 10
NULL                equ 0
EXIT_SUCCESS        equ 0
STDIN               equ 0
STDOUT              equ 1
STDERR              equ 2
SYS_read            equ 0
SYS_write           equ 1
SYS_open            equ 2
SYS_close           equ 3
SYS_exit            equ 60
SYS_creat           equ 85
O_RDONLY            equ 000000q
S_IRUSR             equ 00400q
S_IWUSR             equ 00200q
MAX_FILENAME_SIZE   equ 255
MAX_IMG_SIZE        equ 1048576
bmpFileDesc         dq  0
errMsgOpenBmp       db "Error opening the BMP", LF, NULL
errMsgRead          db "Error reading the BMP", LF, NULL
errMsgWrite         db "Error write", LF, NULL
newLine             db LF,NULL

;********************************************************************
section .text
;********************************************************************

global terminate
global printStr
global printStrLn
global readImageFile
global writeImageFile

terminate:
    mov rax, SYS_exit
    mov rdi, EXIT_SUCCESS
    syscall

printStr:
    push rbp
    mov rbp, rsp
    push rbx
    mov rbx, rdi
    mov rdx, 0
strCountLoop:
    cmp byte [rbx], NULL
    je strCountDone
    inc rdx
    inc rbx
    jmp strCountLoop
strCountDone:
    cmp rdx, 0
    je prtDone
    mov rax, SYS_write
    mov rsi, rdi
    mov rdi, STDOUT 
    syscall  
prtDone:
    pop rbx
    pop rbp
    ret

printStrLn:
    call printStr
    mov rdi, newLine
    call printStr
    ret

readImageFile:
    push rsi 
    mov rax, SYS_open
    mov rsi, O_RDONLY
    syscall
    cmp rax,0
    jl errorOnOpenBmp 
    mov [bmpFileDesc], rax
    mov rax, SYS_read
    mov rdi, qword [bmpFileDesc]
    pop rsi 
    mov rdx, MAX_IMG_SIZE
    syscall
    cmp rax,0
    jl errorOnRead
    push rax 
    mov rax, SYS_close
    mov rdi, qword [bmpFileDesc]
    syscall 
    pop rax
    ret

writeImageFile:
    push rsi
    push rdx
    mov rax, SYS_creat
    mov rsi, S_IRUSR | S_IWUSR
    syscall
    cmp rax,0
    jl errorOnOpenBmp
    mov [bmpFileDesc], rax
    mov rax, SYS_write
    mov rdi, qword [bmpFileDesc]
    pop rdx 
    pop rsi
    syscall
    cmp rax, 0
    jl errorOnWrite
    mov rax, SYS_close
    mov rdi, qword [bmpFileDesc]
    syscall 
    ret

errorOnOpenBmp:
    mov rdi, errMsgOpenBmp
    call printStrLn
    call terminate
    
errorOnRead:
    mov rdi, errMsgRead
    call printStrLn
    call terminate

errorOnWrite:
    mov rdi, errMsgWrite
    call printStrLn
    call terminate