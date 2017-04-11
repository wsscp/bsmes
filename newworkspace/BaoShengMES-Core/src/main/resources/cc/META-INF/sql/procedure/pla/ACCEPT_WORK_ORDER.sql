CREATE OR REPLACE
PROCEDURE "ACCEPT_WORK_ORDER" (WORKORDERNO IN VARCHAR2, UPDATOR IN VARCHAR2)
AS
BEGIN
    --更新生产单状态
    UPDATE T_WIP_WORK_ORDER SET STATUS = 'IN_PROGRESS',REAL_START_TIME=SYSDATE,MODIFY_TIME = SYSDATE,
      MODIFY_USER_CODE = UPDATOR WHERE WORK_ORDER_NO =WORKORDERNO;

    UPDATE T_WIP_WORK_ORDER T1 SET T1.MAT_IS_USED = '1' 
    WHERE T1.WORK_ORDER_NO = (SELECT T2.PROCESS_GROUP_RESPOOL FROM T_WIP_WORK_ORDER T2 WHERE T2.WORK_ORDER_NO = WORKORDERNO);
    --更新任务状态
    --UPDATE T_PLA_ORDER_TASK SET STATUS = 'IN_PROGRESS',MODIFY_TIME = SYSDATE,MODIFY_USER_CODE = UPDATOR WHERE WORK_ORDER_NO = WORKORDERNO;



    --更新明细分解状态
    --UPDATE T_PLA_CU_ORDER_ITEM_PRO_DEC A SET STATUS = 'IN_PROGRESS',MODIFY_TIME = SYSDATE,MODIFY_USER_CODE = UPDATOR WHERE EXISTS (
    --    SELECT
    --      B.ID
    --    FROM T_PLA_ORDER_TASK B
    --    WHERE B.WORK_ORDER_NO = WORKORDERNO
    --    AND B.ORDER_ITEM_PRO_DEC_ID =A.ID
    --);

    --更新明细状态
    UPDATE T_PLA_CUSTOMER_ORDER_ITEM_DEC A SET A.STATUS = 'IN_PROGRESS',MODIFY_TIME = SYSDATE,MODIFY_USER_CODE = UPDATOR
    WHERE EXISTS (
        SELECT
          B.ID
        FROM T_PLA_CU_ORDER_ITEM_PRO_DEC B LEFT JOIN T_PLA_ORDER_TASK C ON B.ID = C.ORDER_ITEM_PRO_DEC_ID
        WHERE C.WORK_ORDER_NO  = WORKORDERNO
        AND A.ID = B.ORDER_ITEM_DEC_ID
    );

    --更新item
    UPDATE T_PLA_CUSTOMER_ORDER_ITEM A SET STATUS = 'IN_PROGRESS',MODIFY_TIME = SYSDATE,MODIFY_USER_CODE = UPDATOR WHERE EXISTS (
        SELECT
            B.ID
        FROM T_PLA_CUSTOMER_ORDER_ITEM_DEC B
        LEFT JOIN T_PLA_CU_ORDER_ITEM_PRO_DEC C ON B.ID = C.ORDER_ITEM_DEC_ID
        LEFT JOIN T_PLA_ORDER_TASK D ON C.ID = D.ORDER_ITEM_PRO_DEC_ID
        WHERE D.WORK_ORDER_NO = WORKORDERNO
        AND A.ID = B.ORDER_ITEM_ID
    );

    --更新sales_order_item
    UPDATE T_ORD_SALES_ORDER_ITEM A SET STATUS = 'IN_PROGRESS',MODIFY_TIME = SYSDATE,MODIFY_USER_CODE = UPDATOR WHERE EXISTS (
        SELECT
            B.ID
        FROM T_PLA_CUSTOMER_ORDER_ITEM B
          LEFT JOIN T_PLA_CUSTOMER_ORDER_ITEM_DEC C ON B.ID = C.ORDER_ITEM_ID
          LEFT JOIN T_PLA_CU_ORDER_ITEM_PRO_DEC D ON C.ID = D.ORDER_ITEM_DEC_ID
          LEFT JOIN T_PLA_ORDER_TASK E ON D.ID = E.ORDER_ITEM_PRO_DEC_ID
        WHERE E.WORK_ORDER_NO = WORKORDERNO
              AND A.ID = B.SALES_ORDER_ITEM_ID
    );

    --更新order
    UPDATE T_PLA_CUSTOMER_ORDER A SET STATUS = 'IN_PROGRESS',MODIFY_TIME = SYSDATE,MODIFY_USER_CODE = UPDATOR WHERE EXISTS (
        SELECT
            B.ID
        FROM T_PLA_CUSTOMER_ORDER_ITEM B
          LEFT JOIN T_PLA_CUSTOMER_ORDER_ITEM_DEC C ON B.ID = C.ORDER_ITEM_ID
          LEFT JOIN T_PLA_CU_ORDER_ITEM_PRO_DEC D ON C.ID = D.ORDER_ITEM_DEC_ID
          LEFT JOIN T_PLA_ORDER_TASK E ON D.ID = E.ORDER_ITEM_PRO_DEC_ID
        WHERE E.WORK_ORDER_NO = WORKORDERNO
              AND A.ID = B.CUSTOMER_ORDER_ID
    );

    --更新sales_order
    UPDATE T_ORD_SALES_ORDER A SET STATUS = 'IN_PROGRESS',MODIFY_TIME = SYSDATE,MODIFY_USER_CODE = UPDATOR WHERE EXISTS (
        SELECT
            B.ID
        FROM T_PLA_CUSTOMER_ORDER B
          LEFT JOIN T_PLA_CUSTOMER_ORDER_ITEM C ON B.ID = C.CUSTOMER_ORDER_ID
          LEFT JOIN T_PLA_CUSTOMER_ORDER_ITEM_DEC D ON C.ID = D.ORDER_ITEM_ID
          LEFT JOIN T_PLA_CU_ORDER_ITEM_PRO_DEC E ON D.ID = E.ORDER_ITEM_DEC_ID
          LEFT JOIN T_PLA_ORDER_TASK F ON E.ID = F.ORDER_ITEM_PRO_DEC_ID
        WHERE F.WORK_ORDER_NO = WORKORDERNO
          AND A.ID = B.SALES_ORDER_ID
    );
END;