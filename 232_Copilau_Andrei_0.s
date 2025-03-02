.data
	tablou: .space 4096
	index_tablou: .space 4
	contor_operatii: .space 4
	operatie: .space 4
	formatScanf: .asciz "%d"
	formatPrintf: .asciz "%d\n"
	formatEroare: .asciz "%d: (0, 0)\n"
	index: .space 4
	formatAfisare: .asciz "%d: (%d, %d)\n"
	
	formatAfisareGet: .asciz "(%d, %d)\n"
	formatEroareGet: .asciz "(0, 0)\n"
	
	formatAfisareTablou: .asciz "%d "
	
	index_add: .space 4
	fisiere_add: .space 4
	blocuri_libere: .space 4
	spatiu_total: .long 1024
	start: .space 4
	end: .space 4 
	nr_blocuri: .space 4
	
	descriptor: .space 4
	dimensiune: .space 4
	spatiu_fisier: .space 4
	cat: .space 4
	rest: .space 4
	
	index_defrag: .space 4

.text
.global main

main:
//citire nr operatii
	pushl $contor_operatii 
	pushl $formatScanf
	call scanf
	popl %ebx
	popl %ebx

	movl $0, index
for_operatii:
	movl index, %ecx
	cmp %ecx, contor_operatii
	je et_exit
	
	pushl $operatie
	pushl $formatScanf
	call scanf
	popl %ebx
	popl %ebx
	
	movl operatie, %eax
	cmp $1, %eax
	je op_add
	
	cmp $2, %eax
	je op_get
	
	cmp $3, %eax
	je op_delete
	
	cmp $4, %eax
	je op_defragmentation
	
//ADD
op_add: 
//nr fisiere de adaugat
	pushl $fisiere_add
	pushl $formatScanf
	call scanf
	popl %ebx
	popl %ebx
	
	movl $0, index_add
	for_add:
		movl index_add, %ecx
		cmp %ecx, fisiere_add
		jle et_incrementare
		
		//citire descriptor si dimensiune
		pushl $descriptor
		pushl $formatScanf
		call scanf
		popl %ebx
		popl %ebx
		
		pushl $dimensiune
		pushl $formatScanf
		call scanf
		popl %ebx
		popl %ebx
		
		//verificare dimensiune valida
		movl dimensiune, %eax
		cmp $8, %eax
		jle eroare_dimensiune
		
		//calculez nr de blocuri de ocupat 
		movl dimensiune, %eax
		movl $0, %edx
		movl $8, %ebx
		divl %ebx
		movl %eax, cat
		movl %edx, rest
		
		movl rest, %eax
		cmp $0, %eax
		je dim_fixa

		movl cat, %eax
		incl %eax
		movl %eax, spatiu_fisier
		jmp parcurgere_tablou

	dim_fixa:
		movl cat, %eax
		movl %eax, spatiu_fisier
		jmp parcurgere_tablou

	//parcurgam tabloul si vedem daca avem spatiu pt a adauga fisierul
	parcurgere_tablou:
		movl $0, index_tablou
		movl spatiu_fisier, %ebx
		movl $0, blocuri_libere
		for_tablou:
			movl index_tablou, %ecx
			cmp %ecx, spatiu_total
			jle final_parcurgere
			
			//verificam daca e liber blocul curent
			lea tablou, %edi
			movl (%edi, %ecx, 4), %eax
			cmp $0, %eax
			jne bloc_inaccesibil
			
			incl blocuri_libere
			cmp blocuri_libere, %ebx
			je adauga_fisier
			
			incl index_tablou
			jmp for_tablou
			
		bloc_inaccesibil:
			movl $0, blocuri_libere
			incl index_tablou
			jmp for_tablou	
			
		//adaugare fisier
		adauga_fisier:
			incl index_tablou
			movl index_tablou, %eax
			subl spatiu_fisier, %eax
			movl %eax, start
			
			movl index_tablou, %eax
			decl %eax
			movl %eax, end

			movl start, %ecx
			adauga_for:
				lea tablou, %edi
				movl descriptor, %ebx
				movl %ebx, (%edi, %ecx, 4)
				incl %ecx
				cmp %ecx, end
				jge adauga_for
				
				jmp et_interval

		//afisare interval
		et_interval:
			//afisare interval
			pushl end
			pushl start
			pushl descriptor
			pushl $formatAfisare
			call printf
			popl %ebx
			popl %ebx
			popl %ebx
			popl %ebx
			
			pushl $0
			call fflush
			popl %ebx
			
			jmp et_incrementare_add
	
	//daca ajung la final si am destule blocuri libere, adaug fisierul
	final_parcurgere:
		movl blocuri_libere, %eax
		cmp dimensiune, %eax
		jne eroare_dimensiune
		
		jmp adauga_fisier
		
	eroare_dimensiune:
		pushl descriptor
		pushl $formatEroare
		call printf
		popl %ebx
		popl %ebx
			
		pushl $0
		call fflush
		popl %ebx
			
		jmp et_incrementare_add
	
et_incrementare_add:
	incl index_add
	jmp for_add

/*
//afisarea la final a tabloului intreg
afisare_memorie_add:
	movl $0, index_tablou
	for_afisare_tablou_add:
		movl index_tablou, %ecx
		cmp %ecx, spatiu_total
		jle et_incrementare_add
		
		lea tablou, %edi
		movl (%edi, %ecx, 4), %edx
		pushl %edx
		pushl $formatAfisareTablou
		call printf
		popl %ebx
		popl %ebx
		
		pushl $0
		call fflush
		popl %ebx
		
		incl index_tablou
		jmp for_afisare_tablou_add
*/

//GET
op_get:
	//citire descriptor
	pushl $descriptor
	pushl $formatScanf
	call scanf
	popl %ebx
	popl %ebx
	
	movl $-1, start
	movl $0, end
	movl $0, index_tablou
	tablou_get:
		movl index_tablou, %ecx
		cmp %ecx, spatiu_total
		jle final_get
		
		lea tablou, %edi
		movl descriptor, %eax
		
		cmp %eax, (%edi, %ecx, 4)
		je verificare_start
	
		cmp %eax, (%edi, %ecx, 4)
		jne verificare_interval

	verificare_start:
		movl start, %edx
		//if(start==-1)
		cmp $-1, %edx
		je initializare_start
		
		//if(start!=-1)
		cmp $-1, %edx
		jne initializare_end

		initializare_start:
			movl %ecx, start
			movl %ecx, end
			
			incl index_tablou
			jmp tablou_get

		initializare_end:
			movl %ecx, end
			
			incl index_tablou
			jmp tablou_get

	verificare_interval:
		movl start, %eax
		//if(start==-1)
		cmp $-1, %eax
		je continuare_get
		
		//afisare interval
		pushl end
		pushl start
		pushl $formatAfisareGet
		call printf
		popl %ebx
		popl %ebx
		popl %ebx
			
		pushl $0
		call fflush
		popl %ebx
		
		jmp et_incrementare
	
	continuare_get:
		incl index_tablou
		jmp tablou_get
		
	final_get:
		//if(start!=-1) afisare else incrementare
		movl start, %eax
		cmp $-1, %eax
		je eroare_get
		
		//afisare interval
		pushl end
		pushl start
		pushl $formatAfisareGet
		call printf
		popl %ebx
		popl %ebx
		popl %ebx
			
		pushl $0
		call fflush
		popl %ebx
		
		jmp et_incrementare
	
	eroare_get:
		pushl $formatEroareGet
		call printf
		popl %ebx
			
		pushl $0
		call fflush
		popl %ebx
	
		jmp et_incrementare
	

//DELETE
op_delete:
	//citire descriptor
	pushl $descriptor
	pushl $formatScanf
	call scanf
	popl %ebx
	popl %ebx
	
	movl $0, index_tablou
	tablou_delete:
		movl index_tablou, %ecx
		cmp %ecx, spatiu_total
		jle afisare_memorie
		
		movl descriptor, %eax
		lea tablou, %edi
		cmp %eax, (%edi, %ecx, 4)
		jne continuare_delete
		
		movl $0, (%edi, %ecx, 4)
		
	continuare_delete:
		incl index_tablou
		jmp tablou_delete
			
//Afisare tablou in functie de parcurgerea de la get
afisare_memorie:
	movl $-1, start
	movl $-1, end
	movl $-1, descriptor
	movl $0, index_tablou
	for_afisare_tablou:
		movl index_tablou, %ecx
		cmp %ecx, spatiu_total
		jle final_afisare
		
		lea tablou, %edi
		movl (%edi, %ecx, 4), %eax
		
		cmp $0, %eax
		je verific_start

		cmp $0, %eax
		jne verific_interval

	//if(v[i]==0)
	verific_start:
		movl start, %edx
		//if(start==-1)
		cmp $-1, %edx
		je continuare_afisare
		
		//if(start!=-1)
		cmp $-1, %edx
		jne afisare_interval
		

	//if(v[i]!=0)
	verific_interval:
		cmp descriptor, %eax
		jne schimbare_descriptor
		
		movl index_tablou, %ebx
		movl %ebx, end
		jmp continuare_afisare
		
	schimbare_descriptor:
		movl start, %edx
		cmp $-1, %edx
		jne afisare_interval
		
		movl %ecx, start
		movl %ecx, end
		movl (%edi, %ecx, 4), %eax
		movl %eax, descriptor
		
		incl index_tablou
		jmp for_afisare_tablou
		
	initializare_descriptor:
		movl %eax, descriptor
		movl index_tablou, %ebx
		movl %ebx, end
		movl %ebx, start
		
		jmp continuare_afisare
				
	continuare_afisare:
		incl index_tablou
		jmp for_afisare_tablou
		
	afisare_interval:
		movl end, %ecx
		movl (%edi, %ecx, 4), %eax
		movl %eax, descriptor
		//afisare interval
		pushl end
		pushl start
		pushl descriptor
		pushl $formatAfisare
		call printf
		popl %ebx
		popl %ebx
		popl %ebx
		popl %ebx
			
		pushl $0
		call fflush
		popl %ebx
		
		//initializez valorile pentru urmatorul interval
		movl $-1, start
		movl $-1, end
		movl $-1, descriptor
			
		jmp for_afisare_tablou
		
	final_afisare:
		//if(start!=-1) afisare else incrementare
		movl start, %edx
		cmp $-1, %edx
		je et_incrementare
		
		movl end, %ecx
		movl (%edi, %ecx, 4), %eax
		movl %eax, descriptor
		//afisare interval
		pushl end
		pushl start
		pushl descriptor
		pushl $formatAfisare
		call printf
		popl %ebx
		popl %ebx
		popl %ebx
		popl %ebx
			
		pushl $0
		call fflush
		popl %ebx
		
		jmp et_incrementare


//Afisarea memoriei tabloului
/*
afisare_memorie:
	movl $0, index_tablou
	for_afisare_tablou:
		movl index_tablou, %ecx
		cmp %ecx, spatiu_total
		jle incrementare_delete
		
		lea tablou, %edi
		movl (%edi, %ecx, 4), %edx
		pushl %edx
		pushl $formatAfisareTablou
		call printf
		popl %ebx
		popl %ebx
		
		pushl $0
		call fflush
		popl %ebx
		
		incl index_tablou
		jmp for_afisare_tablou
	
incrementare_delete:
	jmp et_incrementare
*/

	
//DEFRAGMENTATION
op_defragmentation:
	movl $0, index_defrag
	movl $0, index_tablou
	for_defrag:
		movl index_tablou, %ecx
		cmp %ecx, spatiu_total
		jle finalizare_defrag
		
		//parcurg tabloul si daca intalnesc 0 merg mai departe
		lea tablou, %edi
		movl (%edi, %ecx, 4), %eax
		cmp $0, %eax
		je continuare_defrag
		
		//daca am valoare nenula stochez valoarea in tablou pe pozitia unde aveam 0 anterior(in functie de index_defrag)
		movl index_defrag, %ecx
		movl %eax, (%edi, %ecx, 4)
		incl index_defrag
		
	continuare_defrag:
		incl index_tablou
		jmp for_defrag
		
	//stochez restul valorilor de 0 in tablou de la valoarea indexului_defrag pana la finalul tabloului
	finalizare_defrag:
		movl index_defrag, %ecx
		blocuri_zero_umplere:
			cmp %ecx, spatiu_total
			jle afisare_memorie
		
			lea tablou, %edi
			movl $0, (%edi, %ecx, 4)
		
			incl %ecx
			jmp blocuri_zero_umplere
		

//afisarea memoriei dupa defrag 
/*
afisare_memorie_defrag:
	movl $0, index_tablou
	for_afisare_defrag:
		movl index_tablou, %ecx
		cmp %ecx, spatiu_total
		jle incrementare_defrag
		
		lea tablou, %edi
		movl (%edi, %ecx, 4), %edx
		pushl %edx
		pushl $formatAfisareTablou
		call printf
		popl %ebx
		popl %ebx
		
		pushl $0
		call fflush
		popl %ebx
		
		incl index_tablou
		jmp for_afisare_defrag
	
incrementare_defrag:
	jmp et_incrementare
*/
	
et_incrementare:
	incl index
	jmp for_operatii
	
et_exit:
	movl $1, %eax
	movl $0, %ebx
	int $0x80
