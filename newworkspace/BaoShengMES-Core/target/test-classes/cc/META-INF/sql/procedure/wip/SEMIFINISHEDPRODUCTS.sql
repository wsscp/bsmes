CREATE OR REPLACE PROCEDURE "SEMIFINISHEDPRODUCTS" AS
  CURSOR SEMIFINISHEDPRODUCTSINFO IS
    SELECT DISTINCT TPCOIPD.CONTRACT_NO,
                    TWR.WORK_ORDER_NO,
                    TIL.LOCATION_NAME,
                    TPCOIPD.PROCESS_NAME,
                    TPCOIPD.CUST_PRODUCT_TYPE,
                    TPCOIPD.PRODUCT_SPEC,
                    TPCOIPD.WIRE_COIL,
                    TPCOIPD.HALF_PRODUCT_CODE,
                    TWR.REPORT_LENGTH,
                    TWR.REPORT_TIME,
                    TWWO.WORK_ORDER_SECTION
      FROM T_WIP_REPORT                TWR,
           T_INV_LOCATION              TIL,
           T_PLA_CU_ORDER_ITEM_PRO_DEC TPCOIPD,
           T_WIP_WORK_ORDER            TWWO
     WHERE EXISTS (SELECT 1
              FROM T_WIP_REPORT_TASK TWRT, T_INV_INVENTORY TII
             WHERE TWRT.REPORT_ID = TWR.ID
               AND TWR.SERIAL_NUM = TII.BAR_CODE
               AND TII.LOCATION_ID = TIL.ID
               AND TWR.WORK_ORDER_NO = TPCOIPD.WORK_ORDER_NO
               AND TWR.WORK_ORDER_NO = TWWO.WORK_ORDER_NO
               AND TWWO.MAT_IS_USED = '0')  
     ORDER BY TPCOIPD.CONTRACT_NO;
  SHIFTNAME        VARCHAR(50);
  QUERYDATE        VARCHAR2(50);
  SHIFTSTARTTIME   TIMESTAMP(6);
  SHIFTENDTIME     TIMESTAMP(6);
  PEOPLE           VARCHAR(50) := 'BZZ';
  SECTIONCODE      VARCHAR(50);
  WEEKNO           NUMBER;
  STATUSCOUNT      NUMBER;
  WORKORDERSECTION VARCHAR(50);
  MATCODE          VARCHAR(50);
  FINSTATUS        VARCHAR(50) := 'FINISHED';
  ISFINISH         VARCHAR(50);
  CONTRACTNO       VARCHAR(100);
  BZZEMPLOYEE      VARCHAR(400) := 'SELECT 
TBE.NAME 
FROM 
T_BAS_EMPLOYEE TBE 
WHERE 
EXISTS 
( 
SELECT             
1        
FROM            
T_BAS_ROLE TBR,            
T_BAS_USER TBU,            
T_BAS_USER_ROLE TBUR        
WHERE            
TBE.CERTIFICATE = :people        
AND TBR.CODE = :sectionCode        
AND TBR.ID = TBUR.ROLE_ID        
AND TBU.ID = TBUR.USER_ID        
AND TBU.USER_CODE = TBE.USER_CODE )';
  WEEKNOSTR        VARCHAR(200) := 'SELECT DECODE(WEEK_NO,0,7,WEEK_NO) FROM (SELECT TO_NUMBER(TO_CHAR(TO_DATE(:queryDate, ''yyyy-mm-dd''), ''D'')) - 1 AS WEEK_NO FROM DUAL)';
  STATUSCOUNTSTR   VARCHAR(400) := 'SELECT COUNT(TPM.ID) FROM T_PLA_MRP TPM,T_WIP_WORK_ORDER TWWO,T_PLA_ORDER_TASK TPOT WHERE TPM.MAT_CODE = :matCode AND TPM.STATUS = :finStatus AND TPM.WORK_ORDER_ID = TWWO.ID AND TWWO.WORK_ORDER_NO = TPOT.WORK_ORDER_NO AND TPOT.CONTRACT_NO = :contractNo';
  JUDGEFINISH      VARCHAR(200) := 'SELECT MAT_TYPE FROM T_INV_MAT WHERE MAT_CODE = :matCode';
  DELETESTR    VARCHAR(200) :=' TRUNCATE TABLE T_WIP_CHECK';
  CURSOR DAYSHIFTCURSOR(WEEKNOTMP NUMBER) IS
    SELECT WS.ID,
           WC.WEEK_NO,
           WCS.WORK_SHIFT_ID,
           WS.SHIFT_NAME,
           WS.SHIFT_START_TIME,
           WS.SHIFT_END_TIME
      FROM T_BAS_WEEK_CALENDAR_SHIFT WCS,
           T_BAS_WEEK_CALENDAR       WC,
           T_BAS_WORK_SHIFT          WS
     WHERE WCS.WEEK_CALENDAR_ID = WC.ID
       AND WCS.WORK_SHIFT_ID = WS.ID
       AND WCS.ORG_CODE = 'bstl01'
       AND WC.ORG_CODE = 'bstl01'
       AND WC.WEEK_NO = WEEKNOTMP
       AND WCS.STATUS = '1'
       AND WS.STATUS = '1';
BEGIN
EXECUTE IMMEDIATE DELETESTR;
  FOR SEMIFINISHEDPRODUCTSITEM IN SEMIFINISHEDPRODUCTSINFO LOOP
    MATCODE    := SEMIFINISHEDPRODUCTSITEM.HALF_PRODUCT_CODE;
    CONTRACTNO := SEMIFINISHEDPRODUCTSITEM.CONTRACT_NO;
    EXECUTE IMMEDIATE STATUSCOUNTSTR
      INTO STATUSCOUNT
      USING MATCODE, FINSTATUS, CONTRACTNO;
    EXECUTE IMMEDIATE JUDGEFINISH
      INTO ISFINISH
      USING MATCODE;
    IF ISFINISH != 'FINISHED_PRODUCT' THEN
      IF STATUSCOUNT = 0 THEN
       QUERYDATE:=TO_CHAR( SEMIFINISHEDPRODUCTSITEM.REPORT_TIME, 'yyyy-mm-dd');
    EXECUTE IMMEDIATE WEEKNOSTR
    INTO WEEKNO
    USING QUERYDATE;
    SHIFTNAME := '';
    FOR DAYSHIFT IN DAYSHIFTCURSOR(WEEKNO) LOOP
      SHIFTSTARTTIME := TO_DATE(QUERYDATE, 'yyyy-mm-dd') +
                        1 / 24 / 60 / 60 *
                        (SUBSTR(DAYSHIFT.SHIFT_START_TIME, 0, 2) * 3600 +
                         SUBSTR(DAYSHIFT.SHIFT_START_TIME, 3, 2) * 60);
      SHIFTENDTIME   := TO_DATE(QUERYDATE, 'yyyy-mm-dd') +
                        1 / 24 / 60 / 60 *
                        (SUBSTR(DAYSHIFT.SHIFT_END_TIME, 0, 2) * 3600 +
                         SUBSTR(DAYSHIFT.SHIFT_END_TIME, 3, 2) * 60);
      IF SHIFTSTARTTIME > SHIFTENDTIME THEN
        SHIFTSTARTTIME := SHIFTSTARTTIME - 1;
      END IF;
      IF ((SEMIFINISHEDPRODUCTSITEM.REPORT_TIME >= SHIFTSTARTTIME) AND
         (SEMIFINISHEDPRODUCTSITEM.REPORT_TIME <= SHIFTENDTIME)) THEN
        SHIFTNAME := DAYSHIFT.SHIFT_NAME;
      END IF;
    END LOOP;
    IF SEMIFINISHEDPRODUCTSITEM.WORK_ORDER_SECTION = 1 THEN
      SECTIONCODE := 'JY';
    END IF;
    IF SEMIFINISHEDPRODUCTSITEM.WORK_ORDER_SECTION = 2 THEN
      SECTIONCODE := 'CL';
    END IF;
    IF SEMIFINISHEDPRODUCTSITEM.WORK_ORDER_SECTION = 3 THEN
      SECTIONCODE := 'HT';
    END IF;
    EXECUTE IMMEDIATE BZZEMPLOYEE
      INTO WORKORDERSECTION
      USING PEOPLE, SECTIONCODE;
        INSERT INTO T_WIP_CHECK
          (ID,
           CHECK_USER_NAME,
           CONTRACT_NO,
           PROCESS_FINISH_DATE,
           CHECK_DATE,
           CHECK_TYPE,
           CHECK_SPEC,
           SHIFT,
           CHECK_LENGTH,
           WIRE_COIL,
           PROCESS_NAME,
           LOCATION_NAME,
           CREATE_TIME)
        VALUES
          (GET_UUID(),
           WORKORDERSECTION,
           SEMIFINISHEDPRODUCTSITEM.CONTRACT_NO,
           SEMIFINISHEDPRODUCTSITEM.REPORT_TIME,
           SEMIFINISHEDPRODUCTSITEM.REPORT_TIME,
           SEMIFINISHEDPRODUCTSITEM.CUST_PRODUCT_TYPE,
           SEMIFINISHEDPRODUCTSITEM.PRODUCT_SPEC,
           SHIFTNAME,
           SEMIFINISHEDPRODUCTSITEM.REPORT_LENGTH,
           SEMIFINISHEDPRODUCTSITEM.WIRE_COIL,
           SEMIFINISHEDPRODUCTSITEM.PROCESS_NAME,
           SEMIFINISHEDPRODUCTSITEM.LOCATION_NAME,
           SYSDATE);
      END IF;
    END IF;
  END LOOP;
  COMMIT;
END SEMIFINISHEDPRODUCTS;