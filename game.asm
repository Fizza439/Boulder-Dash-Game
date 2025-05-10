[org 100h]

jmp start
find_player:
push ax
push es
push di
push cx
mov ax, 0xb800
mov es, ax
mov di, 0
mov cx, 2000
f_p:
cmp word[es:di],0x0f02
je fnd
add di, 2
loop f_p
fnd:
mov [loc], di 
pop cx
pop di
pop es
pop ax
ret

dis_score:
push ax
push es
push si
push bx
push cx
push di
mov ax, 0xb800
mov es, ax
mov ah, 0x07
mov bx, str1
mov si, 0
mov di, 3840
mov cx, 7
p:
mov al, [bx+si]
mov [es:di], ax
add si, 1
add di, 2
loop p
push word[score]
call printnum
pop di
pop cx
pop bx
pop si
pop es
pop ax
ret

printnum:
 push bp
 mov bp, sp
 push es
 push ax
 push bx
 push cx
 push dx
 push di
 mov ax, 0xb800
 mov es, ax ; point es to video base
 mov ax, [bp+4] ; load number in ax
 mov bx, 10 ; use base 10 for division
 mov cx, 0 ; initialize count of digits
nextdigit: mov dx, 0 ; zero upper half of dividend
 div bx ; divide by 10
 add dl, 0x30 ; convert digit into ascii value
 push dx ; save ascii value on stack
 inc cx ; increment count of values
 cmp ax, 0 ; is the quotient zero
 jnz nextdigit ; if no divide it again
 mov di, 3864 ; point di to 70th column
nextpos:
 pop dx ; remove a digit from the stack
 mov dh, 0x07 ; use normal attribute
 mov [es:di], dx ; print char on screen
 add di, 2 ; move to next screen location
 loop nextpos ; repeat for all digits on stack
 pop di
 pop dx
 pop cx
 pop bx
 pop ax
 pop es
 pop bp
 ret 2
 
printstr:
 push bp
 mov bp, sp
 push es
 push ax
 push cx
 push si
 push di
 mov ax, 0xb800
 mov es, ax ; point es to video base
 mov al, 80 ; load al with columns per row
 mul byte [bp+10] ; multiply with y position
 add ax, [bp+12] ; add x position
 shl ax, 1 ; turn into byte offset
 mov di,ax ; point di to required location
 mov si, [bp+6] ; point si to string(address)
 mov cx, [bp+4] ; load length of string in cx
 mov ah, [bp+8] ; load attribute in ah
nextchar:
 mov al, [si] ; load next char of string
 mov [es:di], ax ; show this char on screen
 add di, 2 ; move to next screen location
 add si, 1 ; move to next char in string
 loop nextchar ; repeat the operation cx times
 pop di
 pop si
 pop cx
 pop ax
 pop es
 pop bp
 ret 10


read_file:
    mov ah, 3fh        ; read from file
    mov dx, buffer
    mov cx, 1600        ; read up to 1600 bytes at a time
    mov bx, [fhandle]
    int 21h

    mov cx,1598
    mov si,0
    l1:
    cmp byte [buffer+si],0
    je error_incomplete
    add si,1
    loop l1
ret

    error_incomplete:
    call if_error_incomplete
	jmp end

	error_fnf:
	call if_error_file_not_found
	jmp end

if_error_file_not_found:
            mov ax, 0
 			push ax ; push x position
 			mov ax, 2
 			push ax ; push y position
 			mov ax, 7 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, errormsg1
 			push ax ; push address of message
 			push word 14 ; push message length
 			call printstr 

			mov bh,0
			mov dh,3
			mov dl,0
			mov ah,02h
			int 10h
			ret
if_error_incomplete:
            mov ax, 0
 			push ax ; push x position
 			mov ax, 2
 			push ax ; push y position
 			mov ax, 7 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, errormsg2
 			push ax ; push address of message
 			push word 15 ; push message length
 			call printstr 
			

			mov bh,0
			mov dh,3
			mov dl,0
			mov ah,02h
			int 10h
			ret


close_file:
        mov ah, 3eh    ; close file
        mov bx, [fhandle]
        int 21h
		ret

open_file:

	cmplvl2:
	cmp byte[lvl],2
	jne cmplvl3
	mov ah, 3dh        ; open file
    mov dx, lvl2
    mov al, 2
    int 21h
	clc
	jmp op_f
	cmplvl3:
	cmp byte[lvl],3
	jne cnt
	mov ah, 3dh        ; open file
    mov dx, lvl3
    mov al, 2
    int 21h
	clc
	jmp op_f
	cnt:
	push si
	mov si, 4
	cmp byte[fname + si], '2'
	jne cm3
	mov byte[lvl],2
	jmp nomatch
	cm3:
	cmp byte[fname + si], '3'
	jne nomatch 
	mov byte [lvl],3
	nomatch:
	pop si
	mov ah, 3dh        ; open file
    mov dx, fname
    mov al, 2
    int 21h
    op_f:
	jc error_fnf
    mov [fhandle], ax
	
ret

add_scr:
add word[score],1
call dis_score
ret

mvr:
cmp word bx, 0x06db
je retr
cmp bx, 0x0509
je retr
cmp word bx, 0x0a7f
jne nxtr
mov byte[won], 1
jmp mvrr
nxtr:
cmp word bx, 0x0304
jne mvrr
call add_scr
mvrr:
mov word[es:di], 0x0720
add di,2
mov word[es:di], 0x0f02
retr:
mov [loc], di
ret

mvl:
cmp word bx, 0x06db
je retl
cmp bx, 0x0509
je retl
cmp word bx, 0x0a7f
jne nxtl
mov byte[won], 1
nxtl:
cmp word bx, 0x0304
jne mvrl
call add_scr
mvrl
mov word[es:di], 0x0720
sub di,2
mov word[es:di], 0x0f02
retl:
mov [loc], di
ret

mvu:
cmp word bx, 0x06db
je retu
cmp bx, 0x0509
je retu
cmp word bx, 0x0a7f
jne nxtu
mov byte[won], 1
nxtu:
cmp word bx, 0x0304
jne mvru
call add_scr
mvru
mov word[es:di], 0x0720
sub di,80
sub di,80
mov word[es:di], 0x0f02
retu:
mov [loc], di
ret

mvd:
cmp word bx, 0x06db
je retd
cmp bx, 0x0509
je retd
cmp word bx, 0x0a7f
jne nxtd
mov byte[won], 1
nxtd:
cmp word bx, 0x0304
jne mvrd
call add_scr
mvrd
mov word[es:di], 0x0720
add di,160
mov word[es:di], 0x0f02
retd:
mov [loc], di
ret

g_won:
mov byte[won], 1
call game_won
jmp end


l_won:
push ax
push bx
mov bx,2
mov ax, 2
sub bx, ax
pop bx
pop ax
add byte[lvl], 1
cmp byte[lvl], 3
ja g_won
call lvl_won
mov byte[won], 0
jmp strt_gm

g_lost:
call game_lost
jmp end

g_quit:
call game_quit
jmp end2

kbisr: 
mov ax, 0xb800
mov es, ax

inkb:
cmp byte[won],1
je l_won
cmp byte[lost],1
je g_lost

mov di, [loc]
mov bx, [es:di-160]
cmp bx, 0x0509
jne user_inp
mov byte[lost], 1
jmp inkb
user_inp:
mov ah, 0
int 16h
cmp ah, 1
je g_quit
mvmnt:
cmp ah,0x4D
je right
cmp ah, 0x4B
je left
cmp ah, 0x48
je up
cmp ah, 0x50
je down
jne inkb
right:
mov bx, [es:di+2]
call mvr
jmp inkb
left:
mov bx, [es:di-2]
call mvl
jmp inkb
up:
mov bx, [es:di-160]
call mvu
jmp inkb
down:
mov bx, [es:di+160]
call mvd
jmp inkb
ret

start:
	
	call clrscreen
	call input_from_user
	strt_gm:
    call open_file
    call read_file
    call close_file
	call clrscreen
	call dis
	call display_wall1	
	call dis_game
	call dis_score
	call find_player
	call kbisr

end:
mov ah, 0
int 16h
cmp ah, 1
jne end

end2:
mov ax,0x4c00
int 21h

fname: db 'cave1.txt', 0
fhandle: dw 0
buffer: times 1600 db 0    ; declare buffer of 1600 bytes
errormsg2: db 'file incomplete'
errormsg1: db 'file not found'
score: dw 0
str1: db 'Score: '
loc: dw 0
won: db 0
lost: db 0
lvl: db 1
lvl1: db 'cave1.txt', 0
lvl2: db 'cave2.txt', 0
lvl3: db 'cave3.txt', 0


input_from_user:
     ; Print the first message
    mov ax, 40 - (28 / 2) ; calculate x position to center the message (28 is the length of f1)
    push ax ; push x position
    mov ax, 5 ; y position for the first message
    push ax ; push y position
    mov ax, 15 ; white on black attribute
    push ax ; push attribute
    mov ax, f1
    push ax ; push address of message
    push word 36 ; push message length
    call printstr

    ; Print the second message
    mov ax, 40 - (34 / 2) ; calculate x position to center the message (34 is the length of f2)
    push ax ; push x position
    mov ax, 7 ; y position for the second message
    push ax ; push y position
    mov ax, 15 ; white on black attribute
    push ax ; push attribute
    mov ax, f2
    push ax ; push address of message
    push word 34 ; push message length
    call printstr

    ; Print the third message
    mov ax, 40 - (28 / 2) ; calculate x position to center the message (28 is the length of f3)
    push ax ; push x position
    mov ax, 9 ; y position for the third message
    push ax ; push y position
    mov ax, 15 ; white on black attribute
    push ax ; push attribute
    mov ax, f3
    push ax ; push address of message
    push word 28 ; push message length
    call printstr

    ; Print the fourth message
    mov ax, 40 - (25 / 2) ; calculate x position to center the message (25 is the length of f4)
    push ax ; push x position
    mov ax, 11 ; y position for the fourth message
    push ax ; push y position
    mov ax, 15 ; white on black attribute
    push ax ; push attribute
    mov ax, f4
    push ax ; push address of message
    push word 25 ; push message length
    call printstr

    ; Print the fifth message
    mov ax, 40 - (47 / 2) ; calculate x position to center the message (47 is the length of f5)
    push ax ; push x position
    mov ax, 13 ; y position for the fifth message
    push ax ; push y position
    mov ax, 15 ; white on black attribute
    push ax ; push attribute
    mov ax, f5
    push ax ; push address of message
    push word 56 ; push message length
    call printstr

    ; Print the sixth message
    mov ax, 40 - (22 / 2) ; calculate x position to center the message (22 is the length of f6)
    push ax ; push x position
    mov ax, 15 ; y position for the sixth message
    push ax ; push y position
    mov ax, 15 ; white on black attribute
    push ax ; push attribute
    mov ax, f6
    push ax ; push address of message
    push word 23 ; push message length
    call printstr
	mov bh,0
	mov dh,1
	mov dl,11
	mov ah,02h
	int 10h
			
	MOV AH, 0Ah  ; read file name from user
	MOV DX, name  ; set DX to the address of file_name buffer
	MOV CX, 10  ; set CX to the maximum buffer length
	INT 21h

	cmp byte [name+2],0x0D
	je return

change_fname:
mov si,2
mov di,0
	
l1L:
	mov al,[name+si]
	cmp al,0x0D
	je return2
	mov [fname+di],al
	add si,1
	add di,1
	jmp l1L

return:
ret	


return2:
cmp di,10
je return
mov byte [fname+di],'0'
add di,1
jmp return2

mov ax,0x4c00
int 21h

name: times 10 db '0'
f1:db '::::Welcome to Boulder Dash Game::::', 0
f2:db 'Instructor: Lecturer Waqar Hussain', 0
f3:db 'Group member1: Fizza Shoaib', 0
f4:db 'Group member2: Zarnab Gul', 0
f5:db 'Course title: Computer Organization & Assembly Language', 0
f6:db 'Press Enter to Continue'

dis:
            mov ax, 26
 			push ax ; push x position
 			mov ax, 0
 			push ax ; push y position
 			mov ax, 15 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, line1
 			push ax ; push address of message
 			push word 27 ; push message length
 			call printstr

             mov ax, 0
 			push ax ; push x position
 			mov ax, 1
 			push ax ; push y position
 			mov ax, 15 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, line2
 			push ax ; push address of message
 			push word 15 ; push message length
 			call printstr

  			mov ax,69 
 			push ax ; push x position
 			mov ax, 1
 			push ax ; push y position
 			mov ax, 15 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, line3
 			push ax ; push address of message
 			push word 11 ; push message length
 			call printstr

			cmp byte[lvl], 1
			jne prlvl2
  			mov ax,71 
 			push ax ; push x position
 			mov ax, 24
 			push ax ; push y position
 			mov ax, 15 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, line5
 			push ax ; push address of message
 			push word 8 ; push message length
 			call printstr
			jmp ret_dis
			
			prlvl2:
			cmp byte[lvl], 2
			jne prlvl3
			mov ax,71 
 			push ax ; push x position
 			mov ax, 24
 			push ax ; push y position
 			mov ax, 15 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, line9
 			push ax ; push address of message
 			push word 8 ; push message length
 			call printstr
			jmp ret_dis
			
			prlvl3:
			cmp byte[lvl], 3
			jne ret_dis
			mov ax,71 
 			push ax ; push x position
 			mov ax, 24
 			push ax ; push y position
 			mov ax, 15 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, line10
 			push ax ; push address of message
 			push word 8 ; push message length
 			call printstr
			
			ret_dis:
ret


display_wall1:
			mov si,0
			mov cx,80
			lop1:
            mov ax, si
 			push ax ; push x position
 			mov ax, 2
 			push ax ; push y position
 			mov ax, 6 ; orange on black attribute
 			push ax ; push attribute
 			mov ax, walll
 			push ax ; push address of message
 			push word 1 ; push message length
 			call printstr		
			add si,1
			loop lop1
	
	mov si,0
	mov cx,80
		lop2:
             mov ax, si
 			push ax ; push x position
 			mov ax, 23
 			push ax ; push y position
 			mov ax, 6 ; orange on black attribute
 			push ax ; push attribute
 			mov ax, walll
 			push ax ; push address of message
 			push word 1 ; push message length
 			call printstr		
			add si,1
			loop lop2

	mov cx,21
	mov si,3
	lop3:
             mov ax,0 
 			push ax ; push x position
 			mov ax, si
 			push ax ; push y position
 			mov ax, 6 ; orange on black attribute
 			push ax ; push attribute
 			mov ax, walll
 			push ax ; push address of message
 			push word 1 ; push message length
 			call printstr		
			add si,1
			loop lop3
	
	mov cx,21
	mov si,3
	lop4:
            mov ax,79 
 			push ax ; push x position
 			mov ax, si
 			push ax ; push y position
 			mov ax, 6 ; orange on black attribute
 			push ax ; push attribute
 			mov ax, walll
 			push ax ; push address of message
 			push word 1 ; push message length
 			call printstr		
			add si,1
			loop lop4
returning:
ret


return3:

			mov bh,0
			mov dh,24
			mov dl,0
			mov ah,02h
			int 10h
			ret

dis_game:
	mov ax,0xb800
	mov es,ax
	mov di,482
	mov si,0

l2:
	cmp si,1600
	je return3
	mov al,[buffer+si]
	cmp al,'x'
	je pr_x
	cmp al,'W'
	je pr_W
	cmp al,'B'
	je pr_B
	cmp al,'D'
	je pr_D
	cmp al,'R'
	je pr_R
	cmp al,'T'
	je pr_T
	add si,1
	add di,2
	jmp l2

pr_x:
mov word [es:di],0x08b1
add di,2
add si,1
jmp l2

pr_W:
mov word [es:di],0x06db
add di,2
add si,1
jmp l2

pr_B:
mov word [es:di],0x0509
add di,2
add si,1
jmp l2

pr_D:
mov word [es:di],0x0304
add di,2
add si,1
jmp l2

pr_R:
mov word [es:di],0x0f02
add di,2
add si,1
jmp l2

pr_T:
mov word [es:di],0x0a7f
add di,2
add si,1
jmp l2

game_quit:
	
			mov ax, 26
 			push ax ; push x position
 			mov ax, 1
 			push ax ; push y position
 			mov ax, 15 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, line8
 			push ax ; push address of message
 			push word 10 ; push message length
 			call printstr
			ret

	
game_lost:
	
			mov ax, 26
 			push ax ; push x position
 			mov ax, 1
 			push ax ; push y position
 			mov ax, 15 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, line6
 			push ax ; push address of message
 			push word 10 ; push message length
 			call printstr

			call find_player
			mov word [es:di],0x8c02
			sub di,160
			mov word [es:di],0x8c09

			ret
game_won:
			mov ax, 26
 			push ax ; push x position
 			mov ax, 1
 			push ax ; push y position
 			mov ax, 15 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, line11
 			push ax ; push address of message
 			push word 9 ; push message length
 			call printstr
			
			call find_player
			mov word [es:di],0x8A02
			ret

lvl_won:
			mov ax, 26
 			push ax ; push x position
 			mov ax, 1
 			push ax ; push y position
 			mov ax, 15 ; blue on black attribute
 			push ax ; push attribute
 			mov ax, line7
 			push ax ; push address of message
 			push word 16 ; push message length
 			call printstr
			ret

walll: db 0xDB 
line1:db '::Welcome to Boulder Dash::'
line2:db 'Arrow key: Move'
line3:db 'Esc to quit'
line4:db 'Score: '
line5:db 'Level: 1'
line9:db 'Level: 2'
line10:db 'Level: 3'
line6:db 'Game Lost!'
line7:db 'Level completed!'
line8:db 'Game Quit!'
line11:db 'Game Won!'
; subroutine to clear the screen
clrscreen:
	push es
 	push ax
 	push cx
 	push di
 	
	mov ax, 0xb800
 	mov es, ax ; point es to video base
 	xor di, di ; point di to top left column
 	mov ax, 0x0720 ; space char in normal attribute
 	mov cx, 2000 ; number of screen locations
 	cld ; auto increment mode
 	rep stosw ; clear the whole screen
 	
	pop di 
	pop cx
 	pop ax
 	pop es
	ret
	mov ax,0x4c00
	int 21h