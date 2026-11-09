	;----Player Data     ;-не менять!!!
l_DATA

l_Pr_Q	DEFB 0	;К-во единиц продукции
l_Pr_N	DEFB 0	;N пр-ва
l_Pr_Z	DEFB 0	;К-во зерб
l_Pr_PRC	DEFW 0	;Cтоимость пр-ва
l_Pr_HWR	DEFW 0	;К-во часов на изготовление
l_Pr_H_	DEFW 0	;К-во прошедших часов
l_Pr_DAY	DEFW 0	;К-во дней на изгот. партии

l_PERIOD	DEFB 0	;период войны (0..5)
l_T_INTR	DEFB 255	;=====255;Тип истр.(0,1,2,255-НЕТ)
l_INTR	DEFB 95,19	;Коорд. истр.
l_INTR_T	DEFB 95,19	;Целевые коорд. истр
l_UFO	DEFB 255,255	;Коорд. НЛО
l_UFO_T	DEFB 255,255	;врем.цель НЛО
l_UFOV	DEFB 0	; НЛО видим/нет (0/1)
l_RNAgen	DEFW 1997	;  --""-- RNA
l_RNBgen	DEFB 7	; нач.уст RNB для генер целей
l_TARoff	DEFB 0	; время (ч) до генерации цели
l_TARon	DEFB 0	;время жизни цели
l_TARlst	DEFB 7	;последняя цель
l_T_TYPE	DEFB 255	;тип цели (0-7,255-база)
l_T_UFO	DEFB 255	;Цели: Tип НЛО(0..2,255)
l_T_SHP	DEFB 255	;судно
l_T_TWN	DEFB 255	;порт
l_T_ISL	DEFB 255	;остров
l_T_BAS	DEFB 255	;наша база
l_T_COL	DEFB 255	;колония
l_T_UBS	DEFB 255	;их база
l_Tleth	DEFB 255	;Тлеф(0/255)
l_RSN	DEFB 10	;к-во учёных
l_ENG	DEFB 10	;к-во инженеров
l_AQU	DEFB 0	;К-во акванавтов
l_REYTIN	DEFB 0	;рейтинг 0,1,2->RIP

l_TIM	DEFB 0,4,14,4,4,14,4,4	;Время
l_DAT	DEFB 1,5	;День
	DEFB 37,21,18,33,16,28,47,15	;Месяц
	DEFB 2,0,1,7	;Год
	DEFB 1	; (N месяца 0-11)
l_e255	EQU 255
l_e254	EQU 254
l_RS	;Исследов. (255-нет,0-есть,N-к-во дней)
	DEFB 0,0,l_e255,l_e255,0
	DS 6,l_e255
	DEFB l_e254,l_e255,l_e254,l_e254
	DS 3,l_e255
	DEFB 0
	DS 40,l_e255
	DEFB 0
	DS 20,l_e255
l_nDAT	DEFW 1	;Номер дня
l_DUMMY2	DEFB 2
l_DOLG	DEFW 0,0	;долг
l_BASE	DEFB 0,0,0,0,0,0,0,0	;Базы (% повреждений, >=100-уничтожена)
l_MONEY	DEFW 33920,30
l_eq	EQU 0	;1
l_S_GUN	DS 12*2,l_eq	;хранится: оружие
l_S_EQU	DS 3*2,l_eq	;оборуд
l_S_ARM	DS 3*2,l_eq	;защита
l_S___	DEFW 0	;Для нет
l_S_UFO	DS 6*2,l_eq	;типы НЛО
l_S_ART	DS 10*2,l_eq	;артефакты(от ион.уск+корп.НЛО+тела)
l_S_PROF	DS 20*2,l_eq	;проф.инопл
l_S_LIV	DS 7*2,l_eq	;живые инопл
l_S_TMP	DEFW 0	;если 5 пси-контр.
	DEFW 0	;если хакер
	DEFW 0

l_DUMMY3	DEFB #FF
l_R_TM	DEFB 0	;Время иссл.
l_R_NUM	DEFB 5-#1F	;Число заверш иссл-#1F []
l_N_AQU	DEFB 1	;Имя нанимаемого акв.(1-192)
l_DUMMY1	DEFB 1
l_AQNAVT	DEFB 0	;ИМЯ(0-нет)
	DEFB 1	;ранг(0-7)
	DEFB 2	;защита(0-нет,1,2,3)
	DEFB 3	;Time Units
	DEFB 4	;Energy
	DEFB 5	;Health
	DEFB 6	;Wound
	DEFB 7	;Moral Level
	DEFB 8	;Precision
	DEFB 9	;Gun 1 (255-no)
	DEFB 10	;Gun 2
	DEFB 11	;Gun 3
	DEFB 12	;Gun 4
	DEFB 13	;Дни до след. звания
	DEFB 0	;--
	DEFB 0	;--
	DS 9*16,0

l_DATLEN	EQU $-l_DATA	;длина игровых данных <480
l_NEWDAT	EQU #C000+13500	;копия нач данных (480)
l_ALLDAT	EQU l_NEWDAT+480	;5 игр сост x480

l_U_GUN	DS 12,0	;хранится: оружие
	DS 3,0	;оборуд
l_U_ART	DS 10,0	;артефакты(от ион.уск+корп.НЛО+тела)
l_U_LIV	DS 7,0	;живые инопл
l_U_len	EQU $-l_U_GUN
