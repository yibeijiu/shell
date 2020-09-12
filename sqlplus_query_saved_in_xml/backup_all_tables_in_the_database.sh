#!/bin/bash
query=`sqlplus -s username/password@userdb<<EOF
set pagesize 0
select t.TABLE_NAME from user_tables t;
quit
EOF`
tables=($(echo "$query"|sed '$d'))
cd ${HOME}/backup_dir
for i in ${tables[@]}
do
xml_file_name=${1}.xml
sqlplus -s username/password@userdb<<EOF
set serveroutput on size unlimited
set long 8000
set pagesize 0
set linesize 2000
set heading off
set trimout on
set feedback off
set trimspool on
set echo off
set verify off
spool ${xml_file_name};
define dump_table=$i
DECLARE
  xmlhdl dbms_xmlgen.ctxtype;  -- select的查询结果
  xmltext clob;         -- xml存储的clob
  lines varchar2(5000);  -- DBMS_OUTPUT每次输出的字符串，我使用的oracle版本是12c，DBMS_coutput输出的最大字符串长度为32767
  row_number int := 50; -- DBMS_OUTPUT每50行的xml内容输出
  xml_pos int := 0;     -- xml_pos+1为SUBSTR的在xmltext的起始位置
  xml_epos int;         -- SUBSTR的在xmltext的结束位置
BEGIN
  xmlhdl := dbms_xmlgen.newcontext('select * from &dump_table');
  DBMS_XMLGEN.setNullHandling(xmlhdl,2);  -- 设置表中空值的xml字段，如</A>
  xmltext := DBMS_XMLGEN.getXML(xmlhdl);
  xml_epos := instr(xmltext,chr(10),xml_pos+1,row_number);
  WHILE xml_epos >0 LOOP  --xml文件大于50行的，每50行进行输出
    lines := SUBSTR(xmltext,xml_pos+1,xml_epos-xml_pos-1);
  	DNMS_OUTPUT.put_line(lines);
  	xml_pos := xml_epos;
  	xml_epos := instr(xmltext,chr(10),xml_pos+1,row_number);
  END LOOP;
  DBMS_OUTPUT.put_line(SUBSTR(xmltext,xml_pos+1)); --输出xml不足50行的部分
  dbms_xmlgen.closecontext(xmlhdl);
END;
/
spool off;
quit
EOF
done