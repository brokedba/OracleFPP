set feed off
COLUMN NETWORK_NAME FORMAT A30
COLUMN PDB FORMAT A15
COLUMN CON_ID FORMAT 999
SELECT PDB, NETWORK_NAME, CON_ID FROM CDB_SERVICES
  WHERE PDB IS NOT NULL AND
        CON_ID > 2
  ORDER BY PDB;
  
COLUMN DB_NAME FORMAT A10
COLUMN CON_ID FORMAT 999
COLUMN PDB_NAME FORMAT A15
COLUMN OPERATION FORMAT A16
COLUMN OP_TIMESTAMP FORMAT A10
COLUMN CLONED_FROM_PDB_NAME FORMAT A15
 
SELECT DB_NAME, CON_ID, PDB_NAME, OPERATION, OP_TIMESTAMP, CLONED_FROM_PDB_NAME
  FROM CDB_PDB_HISTORY
  WHERE CON_ID > 2
  ORDER BY CON_ID;  

SELECT PDB_ID, PDB_NAME, STATUS FROM DBA_PDBS ORDER BY PDB_ID;

 SELECT NAME, OPEN_MODE, RESTRICTED,PDB_COUNT,LOCAL_UNDO,round(TOTAL_SIZE/1024/1024,2) total_MB,BLOCK_SIZE FROM V$PDBS;
   
COLUMN CON_ID FORMAT 999
COLUMN FILE_ID FORMAT 9999
COLUMN TABLESPACE_NAME FORMAT A15
COLUMN FILE_NAME FORMAT A70

SELECT CON_ID, FILE_ID, TABLESPACE_NAME, FILE_NAME
  FROM CDB_TEMP_FILES
  ORDER BY CON_ID;
prompt
prompt == SAVED STATE
select a.name,b.state "Saved_state" from v$pdbs a , dba_pdb_saved_states b where a.con_id = b.con_id ;
prompt    
/*  
COLUMN PDB_ID FORMAT 999
COLUMN PDB_NAME FORMAT A8
COLUMN FILE_ID FORMAT 9999
COLUMN TABLESPACE_NAME FORMAT A20
COLUMN FILE_NAME FORMAT A70

SELECT p.PDB_ID, p.PDB_NAME, d.FILE_ID, d.TABLESPACE_NAME, d.FILE_NAME
  FROM DBA_PDBS p, CDB_DATA_FILES d
  WHERE p.PDB_ID = d.CON_ID
  ORDER BY p.PDB_ID;
*/ 
  set feed on 