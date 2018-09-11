include mylib.inc

CallDos equ <int 21h>


MyData segment
	;-------------键盘输入相关的格式  输入字符串
    g_dbSize    db 30h                 ;第一个字节为缓冲区的大小(缓冲区的最大长度)    如果超出范围,DOS不让输入,并发出声音
    g_dbLength  db 0                   ;第二个字节为实际的长度 (键盘输入后,自动填写)
    g_strBuffer db 30h dup (0)         ;从第三个字节开始,为Buffer
    
	;回车 换行 
    g_strEnter  db 0dh, 0ah, '$'
	
	g_strTip db 'please input hex string:$'
    
    g_strError db 'Error input$'

    
MyData ends

MyStack segment stack                     ;stack 声明此处是堆栈段,老的编译器有时候需要此声明
    db 80h dup (0cch)                    ;在g_InitStack前面给同样大小的区域,防止堆栈溢出
    g_InitStack db 80h dup (0cch)        ;定义80h个字节,即十进制100个字节,作为我们的栈空间,以 cc 进行填充. 汇编中的数值,只要是 a到f开头的,前缀必须给0,否则编译器分不清是变量名还是数值.
MyStack ends

MyCode segment

START:
    
    ;数据段给类型 或者说是 声明数据段
    assume ds : MyData
	
	;---------设置数据段
	mov ax, MyData
    mov ds, ax
	
	;---------设置堆栈段
    mov ax, MyStack
    mov ss, ax
	;offset 表示取 g_InitStack标号的首地址
	;栈顶设置在栈的中间位置,防止堆栈溢出
    mov sp, offset g_InitStack
	
	;在屏幕上输出
    mov dx, offset g_strTip
    mov ah, 09h
    int 21h
	
	;-------------等待用户选择对应的菜单选项
	;DS:DX=缓冲区首地址
	;(DS:DX+1)=实际输入的字符数
	;(DS:DX)=缓冲区最大字符数
    mov dx, offset g_dbSize
    mov ah, 0ah  ;0ah 表示键盘输入到缓冲区
    int 21h
	
	;下面要给输入完成的字符串添加结束符$,下面的 bl 存放的是用户实际输入的字符串长度,而加$时,用的是bx,为了将bh置0,这里直接将bx置0.
	xor bx,bx
	;到这一步时,用户已经输入完成,g_dbLength里面已经存入了我们输入的字符串实际长度
	mov bl,g_dbLength           ;默认访问的是 ds 段,所以在上面要声明 ds 在哪一个段 -> assume ds : MyData,这里才可以使用
	;给我们输入的字符串在末尾添加结束符$
	mov si,offset g_strBuffer
	mov byte ptr [si+bx],'$'
    
	;回车 换行 
    mov dx, offset g_strEnter
    mov ah, 09h
    CallDos
    
    xor cx, cx
    mov si, offset g_strBuffer
WHILE_BEGIN:
    cmp cx, bx       ;当前正在处理的十六进制位置 跟 我们输入的十六进制字符串总长度 进行比较
    jae WHILE_END    ;当cx 大于 bx 时,说明已经转换到了最后一个字符,跳转到 WHILE_END
        mov bp, cx
        xor ax, ax
        mov al, ds:[si + bp]
        
		;----写法一:
        ;push ax
		;如果 ShowBin 函数内部调用的是 C 约定(外平栈) ,那么,要在 call ShowBin 的下一行再添加上 add sp,2 (堆栈地址是从高到低分配的)
		;如果 showBin 函数内部调用的是 stdcall 约定(内平栈),那么,"不需要"在 call ShowBin 的下一行添加 add sp,2
        ;call ShowBin  ;调用 ShowBin 函数  , 这里为内平栈,即在 ShowBin 函数里 ret 2
		
		;----写法二:
		;invoke是一个宏指令(编译器的内置宏),参数一是我们要调用的函数,参数二是我们要提交的参数,编译器会自动生成平栈的代码.
		invoke ShowBin,ax
        
        cmp ax, 0    ;此时的 ax 为 ShowBin 的返回标识, 1:表示当前处理的为正常的十六进制字符  0:表示当前处理的不为十六进制字符
        jnz NEXT
		
		;当前处理的字符如果不为十六进制字符,在屏幕上输出 Error input 并跳转到EXIT_PROC标识,结束程序
        mov dx, offset g_strError
        mov ah, 9
        int 21h
        jmp EXIT_PROC
NEXT:
        inc cx
    jmp WHILE_BEGIN
	
WHILE_END:
EXIT_PROC:
    mov ax, 4c00h
    int 21h


MyCode ends

end START