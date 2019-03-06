CREATE DEFINER=`areon_user`@`%` PROCEDURE `set_after_chat`( p_chat_id INT
  )
BEGIN


  DECLARE i  INT DEFAULT 0;
  DECLARE t_  INT DEFAULT 0;
  DECLARE o_ INT DEFAULT 0;
  DECLARE p1 INT DEFAULT 0;
  DECLARE p2 INT DEFAULT 0;
  DECLARE p3 INT DEFAULT 0;
  DECLARE p4 INT DEFAULT 0;
  DECLARE p5 INT DEFAULT 0;
  DECLARE p6 INT DEFAULT 0;
  DECLARE p7 INT DEFAULT 0; 				#ADD for EMMA
  DECLARE p8 INT DEFAULT 0; 				#ADD for EMMA
  DECLARE p9 INT DEFAULT 0; 				#ADD for EMMA
  DECLARE p10 INT DEFAULT 0; 				#ADD for EMMA
  DECLARE p11 varchar(55) DEFAULT '';		#ADD for EMMA
  DECLARE p12 INT DEFAULT 0; 				#ADD for EMMA  
  DECLARE koef_symb_exclamat INT DEFAULT 0; #ADD for EMMA
  DECLARE koef_symb_quest INT DEFAULT 0;	#ADD for EMMA
  DECLARE koef_symb_ne INT DEFAULT 0;		#ADD for EMMA
  
  DECLARE start_ DATETIME DEFAULT NULL;
  DECLARE start_chat DATETIME DEFAULT NULL;
  DECLARE a_record_date DATETIME DEFAULT NULL;
  DECLARE a_user_type CHAR(1) DEFAULT NULL;
  DECLARE a_cnt INT DEFAULT 0;
  DECLARE a_sum INT DEFAULT 0;
  DECLARE no_more_rows BOOLEAN DEFAULT FALSE;
  
  DECLARE cr CURSOR FOR SELECT record_date, user_type FROM TMP_chat_log_full WHERE chat_id=p_chat_id ORDER BY record_date;
  DECLARE cr2 CURSOR FOR SELECT id, message FROM TMP_chat_log ORDER BY id; 	#ADD for EMMA
  DECLARE CONTINUE HANDLER FOR NOT FOUND  SET no_more_rows = TRUE;  
 
-- update/insert таблицы не содерж в where ключ.
-- для возможности update надо проставить параметр
  SET SQL_SAFE_UPDATES=0;
 
 
#________________________________________________________________________________
#_______________$$$$$__$$___$$__$$___$$____$$$___________________________________
#_______________$$_____$$$_$$$__$$$_$$$___$$_$$__________________________________
#_______________$$$$___$$_$_$$__$$_$_$$___$$_$$__________________________________
#_______________$$_____$$___$$__$$___$$__$$$$$$$_________________________________
#_______________$$$$$__$$___$$__$$___$$__$$___$$_________________________________
#________________________________________________________________________________


#_________________________________________________________________________________ 
# EMMA = "EMotion MAchine"
# "The Emotion Machine" - book by scientist Marvin Minsky
# https://en.wikipedia.org/wiki/The_Emotion_Machine
#
#Bondyrev Victor(C)
#02/04/2018
#_________________________________________________________________________________ 


-- ------------------
-- ПОСТОЯННЫЕ ТАБЛИЦЫ

CREATE TABLE IF NOT EXISTS `emma_client_chat_history` (
  `row_id` INT NOT NULL auto_increment,
  `dat_insert` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `chat_id` int(11) DEFAULT NULL,
  `message_row_id` int(11) DEFAULT NULL,
  `word_id` int(11) DEFAULT NULL,
  `word` varchar(1000) DEFAULT NULL,
   PRIMARY KEY (row_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `emma_client_message_result_history` (
  `row_id` INT NOT NULL auto_increment,
  `dat_insert` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `chat_id` int(11) NOT NULL,
  `message_row_id` int(11) NOT NULL,
  `message_path` int(11) DEFAULT NULL,  /*первая часть сообщения или вторая 50 к 50*/
  `sum_exclamat` int(5) DEFAULT NULL,   /*сумма баллов за !*/
  `sum_quest` int(5) DEFAULT NULL,		/*сумма баллов за ?*/
  `sum_ne` int(5) DEFAULT NULL,			/*сумма баллов за част НЕ*/
  `sum_negative` int(5) DEFAULT NULL,   /*сумма баллов за негатив слова*/
  `sum_total` int(5) DEFAULT NULL,		/*сумма баллов ИТОГО*/
  PRIMARY KEY (row_id,chat_id,message_row_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ------------------
-- ВРЕМЕННЫЕ ТАБЛИЦЫ
   
drop temporary table if exists TMP_emma_cursor_chat_history;    
CREATE temporary TABLE `TMP_emma_cursor_chat_history` (
		`chat_id` int(11) DEFAULT NULL,
		`message_row_id` INT(11) DEFAULT NULL,
		`id` INT(11) DEFAULT NULL,
		`atom` VARCHAR(100) DEFAULT NULL
	)  ENGINE=INNODB DEFAULT CHARSET=UTF8;
        
drop temporary table if exists TMP_emma_cursor_message_result; 
CREATE temporary table `TMP_emma_cursor_message_result` (
  `chat_id` int(11) NOT NULL,
  `message_row_id` int(11) NOT NULL,
  `koef_message_exclamat` int(5) DEFAULT 0,
  `koef_message_quest` int(5) DEFAULT 0,
  `koef_message_ne` int(5) DEFAULT 0,
  `koef_message_negative` int(5) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

drop temporary table if exists TMP_emma_cursor_message_result_total; 
CREATE temporary table `TMP_emma_cursor_message_result_total` (
  `chat_id` int(11) NOT NULL,
  `message_row_id` int(11) NOT NULL,
  `count_exclamat` int(5) DEFAULT 0,
  `count_quest` int(5) DEFAULT 0,
  `count_ne` int(5) DEFAULT 0,
  `count_negative` int(5) DEFAULT 0,
  `count_total` int(5) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

#  table with koef for Negative words
drop temporary table if exists TMP_emma_dictionary_koef;    
CREATE temporary TABLE TMP_emma_dictionary_koef 
select word,koef from  emma_dictionary_koef where koef>0;

#_________________________________________________________________________________   
#_________________________________________________________________________________  

/* Временная chat_log - без очистки - ОБЩАЯ ДЛЯ ДВУХ КУРСОРОВ*/
drop temporary table if exists TMP_chat_log_full;
CREATE TEMPORARY TABLE TMP_chat_log_full
(id int, chat_id int,user_type char(1),record_date datetime,message_type char(1), message varchar(1000)) DEFAULT CHARSET=UTF8;

insert into TMP_chat_log_full
select id, chat_id, user_type, record_date,message_type, message
 from chat_log
 where  chat_id=p_chat_id;

#_________________________________________________________________________________   
#_________________________________________________________________________________  

/* Временная chat_log - предварительная очистка, для нормализации слов*/
drop temporary table if exists TMP_chat_log;
CREATE TEMPORARY TABLE TMP_chat_log
(id int, chat_id int, message varchar(1000)) 
select id,chat_id,  LTRIM(rtrim(message)) as message
 from TMP_chat_log_full
 where message not like 'Видео:<br>%'
 and message not like 'Фото: %'
 and message not like 'http%'
 and message not like 'Передан как файл: <br>%'
 
  and user_type = 'U'
 
   and  NOT message regexp '^[a-zA-Z0-9]+$'
   and ( NOT message REGEXP '^[ -~]+$' or  message REGEXP '^[?!]+$' );
 

#_________________________________________________________________________________   
#_________________________________________________________________________________  


/* Кол-во чатов для реализации 50/50 */
/*тут нужны все чаты для пользователя*/
drop temporary table if exists TMP_chat_log_count_avg;
CREATE TEMPORARY TABLE TMP_chat_log_count_avg
(chat_id int NOT NULL, avgs_ceil int NOT NULL) 
select chat_id, ceil((count(id))/2) as avgs_ceil
 from TMP_chat_log_full
  where  chat_id=p_chat_id 
    and user_type = 'U'
 group by chat_id;
  
  
/* Признак СТАРТ ЧАТА К ФИНИШУ 50/50  ДЛЯ ПОЛЯ message_path*/
-- RESULT
set @type = '';
set @num  = 1;

drop temporary table if exists TMP_chat_log_even;
CREATE TEMPORARY TABLE TMP_chat_log_even
(message_row_id  int(11) NOT NULL, row_number int(11) NOT NULL, message_path int(11) NOT NULL,chat_id  int(11) NOT NULL) 
SELECT     
		   t.id as message_row_id, 
		   @num := if(@type = t.chat_id, @num + 1, 1) as row_number,
		   if( (if(@type = t.chat_id, @num + 1, 1)) <= a.avgs_ceil+1,1,2) AS message_path,
           @type := t.chat_id as chat_id
 from TMP_chat_log_full t
	join TMP_chat_log_count_avg as  a on t.chat_id=a.chat_id   
  where  user_type = 'U'
ORDER BY t.chat_id,t.id;


#_________________________________________________________________________________  
#_________________________________________________________________________________  

-- ПЕРЕМЕННЫЕ

#RESET no_more_rows FOR HANDLER WORKS
SET no_more_rows = FALSE;   

#SET KOEF FOR ALL SYMBOLS (!,?,'NE')
SET koef_symb_exclamat  := (select koef from emma_chat_dir_koef where symb_id=1);
SET koef_symb_quest 	:= (select koef from emma_chat_dir_koef where symb_id=2);
SET koef_symb_ne		:= (select koef from emma_chat_dir_koef where symb_id=3);


#_________________________________________________________________________________   
#_________________________________________________________________________________  


  OPEN cr2;
  begin

	DECLARE a_message_row_id INT(11) DEFAULT NULL;
    DECLARE a_cnt_symb_exclamat INT(5) DEFAULT 0;
	DECLARE a_cnt_symb_quest INT(5) DEFAULT 0;
	DECLARE a_cnt_ne INT(5) DEFAULT 0;
	DECLARE a_cnt_negative INT(5) DEFAULT 0;  
	DECLARE a_summa_negative INT(5) DEFAULT 0;
	DECLARE a_message VARCHAR(1000) DEFAULT NULL; 
 
 	set @id=1;


  the_loop: LOOP
    FETCH cr2 INTO a_message_row_id, a_message;
    
    IF no_more_rows THEN LEAVE the_loop; END IF;

 
 # start fetch ROWS/MESSAGE  
 # count "!" - symb_exclamat
		IF a_message  like '%!%' 		
			THEN set a_cnt_symb_exclamat := (LENGTH(a_message)- LENGTH(REPLACE(a_message,'!','')))+ a_cnt_symb_exclamat;
			INSERT INTO TMP_emma_cursor_message_result (chat_id,message_row_id,koef_message_exclamat,koef_message_quest,koef_message_ne,koef_message_negative)
			SELECT p_chat_id,a_message_row_id,a_cnt_symb_exclamat,0,0,0; 
		end if;
        
  # count "?" - symb_exclamat
		IF a_message  like '%?%' 		
			THEN set a_cnt_symb_quest := (LENGTH(a_message)- LENGTH(REPLACE(a_message,'?','')))+ a_cnt_symb_quest;
			INSERT INTO TMP_emma_cursor_message_result (chat_id,message_row_id,koef_message_exclamat,koef_message_quest,koef_message_ne,koef_message_negative)
			SELECT p_chat_id,a_message_row_id,0,a_cnt_symb_quest,0,0;
		end if;       
        

#Reset COUNTERS "!" AND "?"		
set a_cnt_ne = 0;
set a_cnt_negative = 0;
set a_summa_negative = 0;
set a_cnt_symb_exclamat=0;
set a_cnt_symb_quest=0;
set a_message=REPLACE(REPLACE(a_message,'?',''),'!','');

 # start fetch WORDSS/MESSAGE 
		#set @id=1; #если вынести ид на уровень за loop - будет ид всех слов/атомов, а не только ИД в рамках  a_message
		WHILE a_message != '' DO
			set @word = LOWER(SUBSTRING_INDEX(a_message, ' ', 1));
			set a_message = SUBSTRING(a_message, CHAR_LENGTH(@word) + 2 );

	
			# count "NE"
            if @word = 'не' then
				set a_cnt_ne = 1 + a_cnt_ne;
			end if;        
 
			# count "NEGATIVE WORDS"  
			if @word in (select word from  TMP_emma_dictionary_koef) then
				-- set a_cnt_negative = 1 + a_cnt_negative; -- * (select k.koef from TMP_emma_dictionary_koef k where k.word= @word);
                 set a_cnt_negative = (select k.koef from TMP_emma_dictionary_koef k where k.word= @word);
				 set a_summa_negative = a_summa_negative + a_cnt_negative;
			 end if;   

            # RESULT OF fetchies			
            if CHAR_LENGTH(@word)>3 
				and @word not regexp '[a-zA-Z0-9]' 	AND not  @word  REGEXP '[ -~]+' and  hex(@word) REGEXP '^(D[0-4]..)+$'
		
				then
				 insert into TMP_emma_cursor_chat_history (chat_id,message_row_id,id,atom) VALUES (p_chat_id,a_message_row_id,@id,@word);  
				  end if; 
              
            set @id = @id + 1;
		END WHILE;				
# finish fetchING WORDS


	#SUM KOEF "NE"
	if a_cnt_ne != 0 then  
	INSERT INTO TMP_emma_cursor_message_result (chat_id,message_row_id,koef_message_exclamat,koef_message_quest,koef_message_ne,koef_message_negative)
				SELECT p_chat_id,a_message_row_id,0,0,a_cnt_ne,0;

	end if;

	#SUM NEGATIVE WORDS KOEF
	if a_cnt_negative != 0 then                
		INSERT INTO TMP_emma_cursor_message_result (chat_id, message_row_id, koef_message_exclamat, koef_message_quest, koef_message_ne, koef_message_negative)
		SELECT p_chat_id,a_message_row_id,0,0,0,a_cnt_negative;
	end if; 
 
 /*
 -- если надо записать все строки (и те что без эмоц. окраса)
 if a_cnt_negative = 0 and a_cnt_ne = 0 and  a_cnt_symb_exclamat=0 and a_cnt_symb_quest=0
	then     insert into TMP_emma_cursor_message_result (chat_id, message_row_id, koef_message_exclamat, koef_message_quest, koef_message_ne, koef_message_negative)
             SELECT p_chat_id,a_message_row_id,0,0,0,0;
              end if; 
-- И 389 СТРОКА ЗАКАМЕНТИТЬ having sum(t.count_total)>0;              
*/

  END LOOP the_loop;
	end;
  CLOSE cr2;

#_________________________________________________________________________________   
#_________________________________________________________________________________  

#  temp table with TOTAL koef for  MESSAGE
    INSERT INTO TMP_emma_cursor_message_result_total (chat_id,message_row_id,count_exclamat,count_quest,count_ne,count_negative,count_total)
	
    select p_chat_id,message_row_id, sum(koef_message_exclamat) as count_exclamat, sum(koef_message_quest) as count_quest, sum(koef_message_ne) as count_ne, sum(koef_message_negative) as count_negative,
    (sum(koef_message_exclamat) + sum(koef_message_quest) + sum(koef_message_ne) + sum(koef_message_negative))  as count_total
	from TMP_emma_cursor_message_result  group by p_chat_id,message_row_id;


#UPDATE CONDITIONS 
#Обнуляю разовые появления символов в строчке или их кобинацию согласно условий ниже:
update TMP_emma_cursor_message_result_total 
set count_exclamat = 0, /*символ !*/
	count_quest = 0,	/*символ ?*/
    count_ne = 0,		/*частица "НЕ"*/
    count_total = 0		/*НЕГАТИВНОЕ слово */
where (count_exclamat=1 AND  count_quest=0 AND count_ne=0 AND count_negative=0)
	or  (count_exclamat=0 AND  count_quest=1 AND count_ne=0 AND count_negative=0)
	or  (count_exclamat=0 AND  count_quest=0 AND count_ne=1 AND count_negative=0)
	or  (count_exclamat=2 AND  count_quest=0 AND count_ne=0 AND count_negative=0)
	or  (count_exclamat=0 AND  count_quest=2 AND count_ne=0 AND count_negative=0)
	or  (count_exclamat=1 AND  count_quest=1 AND count_ne=0 AND count_negative=0)
	or  (count_exclamat=0 AND  count_quest=1 AND count_ne=1 AND count_negative=0);


#_________________________________________________________________________________   
#_________________________________________________________________________________  


#RESULT INTO p7 - p11
SELECT sum(count_exclamat 		* 	koef_symb_exclamat) INTO p7 from TMP_emma_cursor_message_result_total;
SELECT sum(count_quest 	 		* 	koef_symb_quest) 	INTO p8 from TMP_emma_cursor_message_result_total;
SELECT sum(count_ne 		 	*	koef_symb_ne)		INTO p9 from TMP_emma_cursor_message_result_total;
SELECT sum(count_negative) INTO p10 from TMP_emma_cursor_message_result_total;

SELECT concat(convert(p7,char),'-',convert(p8,char),'-',convert(p9,char),'-',convert(p10,char)) INTO p11;

#RESULT TOTAL INTO p12
SELECT sum(count_total) INTO p12 from TMP_emma_cursor_message_result_total;
 
if COALESCE(p12, 0) = 0 then 
	set p7 = 0;
	set p8 = 0;
	set p9 = 0;
	set p10 = 0;
end if;

#_________________________________________________________________________________   
#_________________________________________________________________________________  

#TRANSFER TO SERVER TABLE WITH WORDS FOR NEXT ANALYSIS
   
# INSERT FOR HISTORY 
# СОХРАНЯЕМ ВСЮ ПЕРЕПИСКУ ДЛЯ ПОПОЛНЕНИЯ СЛОВАРЯ НОРМАЛИЗИРОВАННЫХ СЛОВ

INSERT INTO emma_client_chat_history (chat_id,message_row_id,word_id,word)  
select a.chat_id,a.message_row_id,a.id as word_id,a.atom as word 
from TMP_emma_cursor_chat_history a;

# СОХРАНЯЕМ ЧАТЫ ТОЛЬКО С НЕГАТИВНЫМ ЭМОЦ. ОКРАСОМ И КОЭФ ПО НИМ
INSERT INTO emma_client_message_result_history (chat_id,message_row_id,message_path,sum_exclamat,sum_quest,sum_ne,sum_negative,sum_total)
select t.chat_id,t.message_row_id, 
		p.message_path, 			-- признак ЧАСТИ СОБЩЕНИЯ (1 или 2)
	   sum(t.count_exclamat 		* 	koef_symb_exclamat) as sum_exclamat,
       sum(t.count_quest 	 		* 	koef_symb_quest) as sum_quest,
       sum(t.count_ne 		 		*	koef_symb_ne) as sum_ne,
       sum(t.count_negative) as sum_negative,
       sum(t.count_total) as sum_total
from TMP_emma_cursor_message_result_total t
	left join TMP_chat_log_even p on t.chat_id=p.chat_id and t.message_row_id=p.message_row_id
group by t.chat_id,t.message_row_id, p.message_path
having sum(t.count_total)>0;

#_________________________________________________________________________________  
#_________________________________________________________________________________    

#________________________________ FINISH EMMA ____________________________________    

#_________________________________________________________________________________  
#_________________________________________________________________________________   


  OPEN cr;
  begin
  the_loop: LOOP
    FETCH cr INTO a_record_date, a_user_type;
    
    IF no_more_rows THEN LEAVE the_loop; END IF;

    IF i = 0 then SET start_ := a_record_date; SET i = 1; END IF; -- Время начала чата
    
    IF a_user_type='B' and t_ < 2 THEN
      SET p6 := TIMESTAMPDIFF(SECOND, start_, a_record_date);
      SET t_ := t_ + 1;
    END IF; -- Оператор принял чат в работу
        
    IF a_user_type = 'O' and o_ < 2 THEN
      SET p1 := TIMESTAMPDIFF(SECOND, start_, a_record_date);  SET o_ := o_ + 1;
    END IF; -- Первый пост оператора
    
    IF a_user_type = 'U' AND start_chat IS NULL THEN
      SET start_chat := a_record_date;
    END IF;
    
    IF a_user_type='O' AND start_chat IS NOT NULL THEN
      SET a_sum := a_sum + TIMESTAMPDIFF(SECOND, start_chat, a_record_date);
      SET a_cnt:= a_cnt + 1;
      SET start_chat := NULL;
    END IF;
    
    IF a_cnt > 0 THEN
      SET p2 := a_sum/a_cnt;
    END IF;
    
  END LOOP the_loop;
  end;
  CLOSE cr;
  
#_________________________________________________________________________________ 

 SELECT COUNT(*) INTO p3 FROM TMP_chat_log_full
    WHERE chat_id = p_chat_id AND user_type <> 'B';
    
  SELECT COUNT(*) INTO p4 FROM TMP_chat_log_full
    WHERE chat_id = p_chat_id AND user_type = 'O'
    AND IFNULL(message_type,'-') <> 't';
    
  SELECT AVG(CHAR_LENGTH(message)) INTO p5 FROM TMP_chat_log_full
    WHERE chat_id = p_chat_id AND user_type='O'
	AND IFNULL(message_type,'-') <> 't';
 
 #_________________________________________________________________________________ 
  
  UPDATE chat
    SET
        chat_duration           = TIMESTAMPDIFF(SECOND, chat_start, chat_end)
       ,oper_first_reply_time   = p1
       ,av_reply_time           = p2
       ,mess_count              = p3
       ,oper_mess_count         = p4
       ,av_oper_mess_char_count = p5
       ,oper_taken_work_time    = p6
       ,upd_date                = NOW()
       ,upd_name                = 'ITR_BOT'
	   ,koef_chat               = p12
       ,koef_chat_symb       	= p11
    WHERE chat_id = p_chat_id;
 
#_________________________________________________________________________________  
#_________________________________________________________________________________    

drop temporary table if exists TMP_emma_dictionary_koef;
drop temporary table if exists TMP_emma_cursor_message_result;
drop temporary table if exists TMP_emma_cursor_message_result_total;
drop temporary table if exists TMP_chat_log_count_avg;
drop temporary table if exists TMP_chat_log_even;
drop temporary table if exists TMP_chat_log;
drop temporary table if exists TMP_chat_log_full;

-- update/insert таблицы не содерж в where ключ.
-- включаю SAFE_UPDATES mode 
-- SET SQL_SAFE_UPDATES=1;

END