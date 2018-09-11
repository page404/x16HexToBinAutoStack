include mylib.inc

MyData segment
    g_strHex2Bin    db '0000$'
                    db '0001$'
                    db '0010$'
                    db '0011$'
                    db '0100$'
                    db '0101$'
                    db '0110$'
                    db '0111$'
                    db '1000$'
                    db '1001$' ; 0x9
                    db 'xxxx$'
                    db 'xxxx$'
                    db 'xxxx$'
                    db 'xxxx$'
                    db 'xxxx$'
                    db 'xxxx$'
                    db 'xxxx$'
                    db '1010$' ; 0xa   如果是字母,不管大小写,都补我们转成了大写,所以,以处理16进制A为例: 'A' - '0' = 17  具体代码在 NEXT: 代码块里
                    db '1011$' ; 0xb
                    db '1100$'
                    db '1101$'
                    db '1110$'
                    db '1111$'


MyData ends


MyCode2 segment

;ShowBin proc far ;near
ShowBin proc far stdcall uses ds dx di bx si argHexAsc:word    ; mylib.inc 文件里面的函数声明格式也要更改 , uses:告诉编译器用到了哪些寄存器(编译器会自动对这些寄存器进行压栈及出栈操作)
    ;进堆栈的顺序依次是  参数ax->后面几个是系统自己保存到堆栈里面的->cs->ip->bp->local->regs
    ;argHexAsc = word ptr 6       ;全局变量写法
    
	;@wRetVal = word ptr -2       ;局部变量写法
	local @wRetVal:word       ;局部变量写法
	
	;定义局部结构体变量,tagTest在mylib.inc里面定义
	local @tagTemp:tagTest
	
	;定义局部数组
	local @wAry[5]:dword
	
	;当使用了 stdcall 或者 C 约定,不需要我们手动的去保存栈操作,如果写上了,访问参数的位置反而不对.
    ;push bp       ;保存之前的bp,因为bp会被覆盖
    ;mov bp, sp    ;栈顶给栈底,保存栈
    
	;当使用了 local 关键字,就不需要手动移出2个字节的位置了,编译器会自动根据local关键字来抬升栈的位置.
	;sub sp, 2     ;sp = sp -2 栈顶往后移2个字节,用来存放返回值
    
	;保存环境  --- 在函数头部使用了 uses ds dx di bx si ,所以,不需要我们手动的再去压栈或平栈
    ;push ds
    ;push dx
    ;push di
    ;push bx
    
    ;---------设置数据段
    mov ax, MyData
    mov ds, ax
	
	;给自定义结构体的赋值
	mov @tagTemp.m_dw,5    ;@tagTemp.m_dw 前面不需要加 word ptr ,编译器会自动加.
	
	;用si作为结构体的指针,访问其成员dw
	assume si:ptr tagTest
	mov [si].m_dw,5
	
	;mov si,offset @tagTemp  ;ffset 在编译时,得到地址,它只能用来修改全局变量或静态变量,(函数如果发生递归,局部变量地址不唯一),所以 @tagTemp "局部变量"是不能用 offset 来进行修饰的.
	lea si,@tagTemp ;lea 得到运行时的"局部变量"地址
	
	;求数组的各种长度
	mov ax,sizeof @wAry       ;sizeof:数组的总大小 5*4 = 20 个字节
	mov ax,lengthof @wAry     ;lengthof:元素的总个数,这里为 5 个
	mov ax,type @wAry         ;type:单位元素的大小,这里为 dword,即 4 个字节
	
	mov ax,offset g_strHex2Bin  ;取偏移地址
	mov ax,seg g_strHex2Bin     ;取段地址
	
    
	;如果 [bp+@wRetVal] 值最后为0:当前处理的16进制字符非法    如果 [bp+@wRetVal] 值最后为 1:当前处理的16进制字节合法
    ;mov [bp+@wRetVal], 0
	mov @wRetVal,0
    
    xor ax, ax     ;传入的16进制数只占1位,也就是说ah位不能有数据,如果有的话, 后面就不能直接用ax,而要用al,所以这里要将ah也置为0
    ;mov ax, [bp+argHexAsc]       ;[bp+argHexAsc] 得到的是传入的参数 即 要转换成2进制的16进制数
	mov ax, argHexAsc
    
	;------判断是否不为 0~9 的数值
    cmp al, '0'
    jb UNMAT1       ;小于
    cmp al, '9'
    ja UNMAT1       ;大于
        ;mov [bp+@wRetVal], 1    ;当前处理的16进制字节合法
		mov @wRetVal,1
        jmp NEXT

;------------判断是否在 A~F 区间
UNMAT1:
    cmp al, 'A'
    jb UNMAT2       ;小于    不在 A~F 区间,跳转到 UNMAT2 -> (判断是否在 a~f 区间)
    cmp al, 'F'
    ja UNMAT2       ;大于    不在 A~F 区间,跳转到 UNMAT2 -> (判断是否在 a~f 区间)
        ;mov [bp+@wRetVal], 1    ;当前处理的16进制字节合法
		mov @wRetVal,1
        jmp NEXT
        
;------------判断是否在 a~f 区间
UNMAT2:
    cmp al, 'a'
    jb UNMAT3       ;小于
    cmp al, 'f'
    ja UNMAT3       ;大于
        ;mov [bp+@wRetVal], 1    ;当前处理的16进制字节合法
		mov @wRetVal,1
        sub al, 'a' - 'A'       ;'a' - 'A' = 97-65 = 32  -> 最后结果: al = al - 32;  -> 将小写字母的al数值改成跟大写字母的al数值相同,这样就可以只处理大写的情况
        jmp NEXT
        
UNMAT3:
    jmp EXIT_PROC

NEXT:   ;执行完 NEXT 段,还是会继续往下执行 EXIT_PROC 段的
    
    sub ax, '0' ; ax = ax - '0'   转成了10进制   如果是字母,不管大小写,都补我们转成了大写,所以,以处理16进制A为例: 'A' - '0' = 17
    mov dl, 5
    mul dl      ; ax = ax*5      16进制的1位,2进制要输出4位,加上后面的结束符$ 如-> '0000$' ,总共是5个字节,所以偏移是5的位数
    mov bx, offset g_strHex2Bin
    mov di, ax
	
	;打印字符串到屏幕  , 这里没有循环,只处理参数传入的其中一个16进制字符 , 循环在函数调用处
    lea dx, [bx+di]
    mov ah, 9
    int 21h
    
EXIT_PROC: 
    ;mov ax, [bp+@wRetVal]    ;在函数返回的时候,ax存放着返回值 1:表示当前处理的16进制中的当前处理位合法  0:表示当前处理的16进制中的当前处理位非法
	mov ax,@wRetVal
    
	;--- 在函数头部使用了 uses ds dx di bx si ,所以,不需要我们手动的再去压栈或平栈
    ;pop bx
    ;pop di
    ;pop dx
    ;pop ds
    
	;当使用了 stdcall 或者 C 约定,不需要我们手动的去保存栈操作,如果写上了,访问参数的位置反而不对.
    ;mov sp, bp
    ;pop bp
    
    ;ret 2      ;在执行ret指令的基础上sp再加2. 用来平栈,因为调用该函数的地方有一个 push ax 操作.
	ret   ;因为是自动平栈,所以不管是 stdcall 还是 C ,这里都只需要固定写成 ret 即可.
ShowBin endp
    
MyCode2 ends

end