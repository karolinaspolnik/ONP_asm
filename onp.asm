org 100h
	
	mov ah,9
    mov dx, kom1 ; wyswietla komunikat 
    int 21h

	call ent

	mov ah,10
	mov dx,zmienna ; pobiera znaki z klawiatury
	int 21h

	call ent
	call zlyznak ; sprawdzam czy wprowadzone znaki sa prawidlowe
	call onp

	mov ah,9
    mov dx, kom2 ; wyswietla komunikat 
    int 21h

	call ent

	mov ah,9
    mov dx, kopia ; wyswietlam przeksztalcone dzialanie w ONP
    int 21h
	
	call kalk

	mov ah,9
    mov dx, kom3
    int 21h

	call wyswietl


koniec:
	pop cx
	mov	ax, 4C00h
	int	21h

zmienna	db	26
		db	0
		times 27 db "$"
		
kopia times 60 db 36

zmienpr db 0
pom dw 0
czyzer dw 0
a dw 0
b dw 0

kom1   db  10, 13, "Wprowadz max 25 znakow w postaci konwencjonalnej: $"
kom2   db  "Dzialanie w postaci ONP: $"
kom3   db  10, 13, "Wynik dzialania: $"
kom4   db  10, 13, "Nie dzielimy przez 0! Wprowadz prawidlowe dane $"
kom5   db  "Wprowadzono nieprawidlowe dane!$"
kom6   db  10, 13, "Program nie obsluguje liczb ujemnych!$"



kalk:
pusha
pushf
	finit
	xor ax,ax
	xor bx,bx
	xor cx,cx
	xor dx,dx
	mov si,kopia + 2
	mov bp, sp 
	inc cx  

komp:
mov dl, byte[kopia + bx]

	cmp dx,36 ;sprawdzam czy wszystkie znaki zostaly juz przyjete ($)
	je Owyj

	inc bx

	;sprawdzam czy to spacja, jesli tak, sciagam ze stosu
	cmp dx, 32
	je Wzrzuc

	;sprawdzam czy znak to liczba
	cmp dx, 48
	jb Oplus
	cmp dx, 57
	ja Oplus

	;kiedy znak jest liczba:
	sub dx,48
	push dx
	jmp komp

	Wzrzuc: ;zrzucam liczby ze stosu
	cmp bp,sp
	je Wext
	pop ax 
	mul cx
	add [pom], ax ;mamy juz w liczbie

	xor ax,ax
	mov ax,10
	mul cx ;wynik w ax
	xor cx,cx
	mov cx,ax
	xor ax, ax
	jmp Wzrzuc

Wext:
	xor cx,cx
	inc cx
	fild word [pom] ; wkladam na stos koprocesora
	
	xor ax,ax
	mov [pom],word 0
	
	jmp komp

	Oplus: ;kiedy znak nie jest liczba
	cmp dx, 43 ; sprawdzam czy "+"
	jne Omin
	faddp ; dodaje st1 i st0 oraz sciagam gorny element, na stosie zostaje wynik
	jmp poOp

	Omin:
	cmp dx, 45 ; sprawdzam czy "-"
	jne Omn

	;sprawdzam czy a > b
	fistp word [b]
	fist word [a]
	mov ax, [b]
	mov cx, [a]
	cmp ax,cx
	ja Okur

	fild word [b]
	fsubp ; odejmuje 
	jmp poOp

	Omn:
	cmp dx, 42 ; sprawdzam czy "*"
	jne Odziel
	fmulp ; mnoze 
	jmp poOp; komp

	Odziel:
	cmp dx, 47 ; sprawdzam czy "/"
	jne poOp;Owyj

	; sprawdzam czy dzielnik nie jest zerem
	fist word [czyzer]
	cmp [czyzer],byte 0
	je Ozero
	jmp Odalej

	; jesli dzielnik jest 0
	Ozero: ; nie mozna dzielic przez 0, wyswietlam komunikat
	mov ah,9
    mov dx, kom4
    int 21h
	jmp koniec ; koncze dzialanie programu

	Okur: ; jesli b>a
	mov ah,9
    mov dx, kom6
    int 21h
	jmp koniec ; koncze dzialanie programu

	; jesli dzielnik nie jest 0
	Odalej:
	fdivp ; dziele 
	jmp poOp

poOp:
	mov dl, byte[kopia + bx]
	cmp dx,36 ;sprawdzam czy wszystkie znaki zostaly juz przyjete ($)
	je Owyj
	inc bx

	;sprawdzam czy to spacja, jesli tak, sciagam ze stosu
	cmp dx, 32
	je Wzrzuc2

Wzrzuc2:
	cmp bp,sp
	je Wext2

Wext2:
	xor cx,cx
	inc cx
	xor ax,ax
	
	jmp komp


	Owyj: ;kiedy wszystkie znaki zostaly obsluzone zapisuje wynik do zmiennej i sciagam ze stosu
	fistp word [pom]
	naura:
popf
popa
ret




onp:
pusha
pushf
	xor ax,ax
	xor bx,bx
	xor cx,cx
	xor dx,dx
	mov bp,sp ; zeby sprawdzic czy wszystko zostalo zdjete ze stosu
    mov si, zmienna + 2
    mov di, kopia

	liczby:
	cmp bl, byte[zmienna + 1] ; sprawdzam czy petla wykonala sie dla wszystkich znakow
	je wypistos 

	inc bx
	mov al, byte[zmienna + 1 + bx] ;przenosze zawartosc jednego bajta do al

	cmp ax, 48
	jb nieliczb ; w ascii 48 == 0, jesli znak ma wartosc ponizej 48 nie jest liczba

	cmp ax, 57
	ja nieliczb ;jesli znak ma wartosc powyzej 57 rowniez nie jest liczba

	;kiedy znak jest liczba:
	mov [si],al ; zapisuje ja do ciagu
	cld  
	movsb
	jmp liczby


		nieliczb:
			cmp ax, 40 ; sprawdzam czy znak to "("
			jne nawzam ; jesli nie, ide dalej
			push ax ; jesli tak, klade nawias na stos
			jmp liczby

		nawzam:
			cmp ax, 41 ; sprawdzam czy znak to ")"
			jne operator
	
		wypisz:
			pop dx 
			cmp dx, 40 ; wypisuje operatory ze stosu dopoki nie trafie na nawias otwierajacy
			je liczby

			mov [si], byte 32 ; wstawiam spacje przy kazdym sciaganiu ze stosu zeby znaki byly oddzielone seperatorem
			cld
			movsb
			dec si

			mov [si],dl ; dopisuje znak do ciagu
			cld
			movsb
			jmp wypisz

		operator:
			mov [si], byte 32 ; wstawiam spacje przy kazdym sciaganiu ze stosu zeby znaki byly oddzielone seperatorem
			cld
			movsb
			dec si ; zmniejszam si, bo po movsb inkrementuje sie si i di

			push ax ; wkladam aktualnie obslugiwany operator na stos
			call prio ; sprawdzam jego priorytet
			pop ax ; sciagam go ze stosu
			mov cx, word [zmienpr] ; zapisuje wartosc priorytetu do cx

			sprstos: 
			cmp bp,sp ; sprawdzam czy stos jest pusty, jesli tak, wychodze z petli
			jne stos1

			push ax
			jmp liczby

			stos1: ; porownuje priorytety, jesli aktualnie obslugiwany znak ma wiekszy, wrzucam go na stos
			call prio
			cmp cx, word [zmienpr] 
			jbe stos2

			push ax
			jmp liczby

			stos2:
			pop dx
			push ax

			mov [si], dl ; dopisuje znak
			cld 
			movsb

			mov [si], byte 32 ; spacja
			cld
			movsb
			dec si

			pop ax
			jmp sprstos

		wypistos:
		cmp bp,sp ; sprawdzam czy cos zostalo na stosie
		je kon

		mov [si], byte 32 ; spacja
		cld
		movsb
		dec si

		pop cx
		mov [si], cl
		cld
		movsb
		jmp wypistos
kon:
popf
popa
ret



prio:
pusha
pushf
	mov bp,sp
	mov ax, word[bp + 20] ; "cofam się" do mojego operatora

	plus:
		cmp ax, 43 ; sprawdzam czy "+"
		jne minus

		mov [zmienpr], byte 1
		jmp wyjdz
	minus:
		cmp ax, 45 ; sprawdzam czy "-"
		jne mnoz

		mov [zmienpr], byte 1
		jmp wyjdz
	mnoz:
		cmp ax, 42 ; sprawdzam czy "*"
		jne dziel

		mov [zmienpr], byte 2
		jmp wyjdz
	dziel:
		cmp ax, 47 ; sprawdzam czy "/"
		jne zerpr

		mov [zmienpr], byte 2
		jmp wyjdz
	zerpr:
		mov [zmienpr], byte 0
wyjdz:
popf
popa
ret

zlyznak: ; sprawdzam poprawnosc wprowadzonych znakow
pusha
pushf
xor ax,ax
xor bx,bx
xor cx,cx
xor dx,dx
Sob:
	cmp bl, byte[zmienna + 1] ; sprawdzam czy petla wykonala sie dla wszystkich znakow
	je wyn ; jesli tak, koncze

	inc bx
	mov al, byte[zmienna + 1 + bx] ;przenosze zawartosc jednego bajta do al

	cmp ax, 48
	jb Snaw1
	cmp ax, 57 ; sprawdzam czy znak jest liczba
	ja Swyjdz

	;jesli jest liczba
	jmp Sob

	Snaw1:
	cmp ax, 40 ; sprawdzam czy "("
		jne Snaw2
		jmp Sob
	Snaw2:
	cmp ax, 41 ; sprawdzam czy ")"
		jne Splus
		jmp Sob
	Splus:
	cmp ax, 43 ; sprawdzam czy "+"
		jne Sminus
		jmp Sob
	Sminus:
		cmp ax, 45 ; sprawdzam czy "-"
		jne Smnoz
		jmp Sob
	Smnoz:
		cmp ax, 42 ; sprawdzam czy "*"
		jne Sdziel
		jmp Sob
	Sdziel:
		cmp ax, 47 ; sprawdzam czy "/"
		jne Swyjdz
		jmp Sob

	Swyjdz:
	mov ah,9
    mov dx, kom5
    int 21h
	jmp koniec
wyn:
popf
popa
ret

ent:
pusha
pushf
	mov ah,2
	mov dl,10
	int 21h
		
	mov dl,13
	int 21h
popf
popa
ret

wyswietl: ;wyswietlanie dziesietne
pushf
pusha

	xor ax,ax
	xor bx,bx
	xor cx,cx
	xor dx,dx ;dla pewnosci zeruje wszystkie rejestry
	mov ax,[pom] ;przenosze wynik do ax
	mov bx,10 ;do bx przenosze 10 zeby przez nie dzielic
	nastos:
	div bx ;dzielenie
	push dx ;wkładamy na stos reszty z dzielenia przez 10
	inc cx ; inkrementuję cx żeby wiedzieć ile cyfr muszę zdjąć
	xor dx,dx
	cmp ax,0 ;jesli wynik jest rowny zero koncze dzialanie
	jne nastos
	
	zdejmij:
	mov ah,2
	pop dx ; sciagam ze stosu cyfre
	add dx,48 ;odjemuje 48 zeby wyswietlic cyfre w sys dziesietnym
	int 21h ;wyswietlam
	xor dx,dx
	dec cx ;zmniejszam wartosc licznika za kazdym razem kiedy wypisuje liczbe
	cmp cx,0 ;po wypisaniu wszystkich liczb wartosc licznika jest rowna 0 i koncze dzialanie programu
	jne zdejmij
popa
popf
ret




