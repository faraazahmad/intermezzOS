global start

section .text
bits 32
start:

    ; point the first entry of the level 4 page table to the first entry 
    ; in the p3 table
    mov eax, p3_table
    or eax, 0b11 ; setting 'present' bit and 'writable' bit
    mov dword [p4_table + 0], eax

    ; similarly, pointing p3 to p2
    mov eax, p2_table
    or eax, 0b11
    mov dword [p3_table + 0], eax

    ; set up the level two page table to have valid references to pages
    mov ecx, 0
.map_p2_table:
    mov eax, 0x200000 ; 2MiB
    mul ecx
    or eax, 0b10000011 ; set first 2 bits and last bit 'huge page' bit
    mov [p2_table + ecx * 8], eax

    inc ecx
    cmp ecx, 512
    jne .map_p2_table

    ; move page table address to cr3
    mov eax, p4_table
    mov cr3, eax

    ; enable PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; set the long mode bit
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; enable paging
    mov eax, cr0
    or eax, 1 << 31
    or eax, 1 << 16
    mov cr0, eax

    lgdt [gdt64.pointer]

    ; update selectors
    mov ax, gdt64.data
    mov ss, ax
    mov ds, ax
    mov es, ax

    ; jump to long mode!
    jmp gdt64.code:long_mode_start

    hlt

section .bss
align 4096

; resb == 'reserve bytes'
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096

section .rodata
gdt64:
    dq 0

; 44: ‘descriptor type’: This has to be 1 for code and data segments
; 47: ‘present’: This is set to 1 if the entry is valid
; 41: ‘read/write’: If this is a code segment, 1 means that it’s readable
; 43: ‘executable’: Set to 1 for code segments
; 53: ‘64-bit’: if this is a 64-bit GDT, this should be set
.code: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)
.data: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41)

.pointer:
    dw .pointer - gdt64 - 1
    dq gdt64


section .text
bits 64
long_mode_start:
    
    mov rax, 0x2f592f412f4b2f4f
    mov qword [0xb8000], rax

    hlt
