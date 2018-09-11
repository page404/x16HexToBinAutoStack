ifndef MY_LIB_INC
; define MY_LIB_INC 0
MY_LIB_INC equ 0

;声明结构体
tagTest struct
    m_db db ?
	m_dw dw ?
	m_ddAry dd 2 dup (?)
tagTest ends

;-----ShowBin proto far  手动平栈的写法
ShowBin proto far stdcall argHexAsc:word

endif