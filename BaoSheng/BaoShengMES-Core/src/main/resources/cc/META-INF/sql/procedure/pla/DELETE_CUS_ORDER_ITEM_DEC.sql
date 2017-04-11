CREATE OR REPLACE
PROCEDURE "DELETE_CUS_ORDER_ITEM_DEC" (ITEM_DEC_ID IN VARCHAR2,UPDATOR IN VARCHAR2,isDelItemDec VARCHAR)
AS

  useStock     T_PLA_CUSTOMER_ORDER_ITEM_DEC.USE_STOCK%TYPE;
  proDecId     T_PLA_CU_ORDER_ITEM_PRO_DEC.ID%TYPE;
  CURSOR mycursor is
    SELECT ID FROM T_PLA_CU_ORDER_ITEM_PRO_DEC WHERE ORDER_ITEM_DEC_ID = ITEM_DEC_ID;
  BEGIN
    SELECT USE_STOCK INTO useStock FROM T_PLA_CUSTOMER_ORDER_ITEM_DEC WHERE ID = ITEM_DEC_ID;

-- 删除物料需求清单
    DELETE FROM T_PLA_MRP m WHERE EXISTS (
        SELECT 1 FROM T_PLA_CU_ORDER_ITEM_PRO_DEC p, T_PLA_ORDER_TASK t, T_WIP_WORK_ORDER w
        WHERE w.WORK_ORDER_NO = t.WORK_ORDER_NO AND t.ORDER_ITEM_PRO_DEC_ID = p."ID" AND m.WORK_ORDER_ID = w."ID"
              AND p.ORDER_ITEM_DEC_ID = ITEM_DEC_ID
    );
-- 删除工装夹具需求清单
    DELETE FROM T_PLA_TOOLES_RP r WHERE EXISTS (
        SELECT 1 FROM T_PLA_CU_ORDER_ITEM_PRO_DEC p, T_PLA_ORDER_TASK t, T_WIP_WORK_ORDER w
        WHERE w.WORK_ORDER_NO = t.WORK_ORDER_NO AND t.ORDER_ITEM_PRO_DEC_ID = p."ID" AND r.WORK_ORDER_ID = w."ID"
              AND p.ORDER_ITEM_DEC_ID = ITEM_DEC_ID
    );
-- 删除生产单
    DELETE FROM T_WIP_WORK_ORDER w WHERE EXISTS (
        SELECT w."ID" FROM T_PLA_CU_ORDER_ITEM_PRO_DEC p, T_PLA_ORDER_TASK t
        WHERE w.WORK_ORDER_NO = t.WORK_ORDER_NO AND t.ORDER_ITEM_PRO_DEC_ID = p."ID"
              AND p.ORDER_ITEM_DEC_ID = ITEM_DEC_ID
    );

--删除OrderTask
    DELETE FROM T_PLA_ORDER_TASK t WHERE EXISTS (
        SELECT p."ID" FROM T_PLA_CU_ORDER_ITEM_PRO_DEC p
        WHERE t.ORDER_ITEM_PRO_DEC_ID = p."ID" AND P.ORDER_ITEM_DEC_ID = ITEM_DEC_ID
    );

--判断该卷线是否冲抵若冲抵直接根据库存信息
    IF useStock = '1' THEN
      UPDATE_INV_OA_USE_LOG(ITEM_DEC_ID,UPDATOR);
    END IF;

--遍历工序用时分解
    OPEN mycursor;
    LOOP
      FETCH mycursor INTO proDecId;
      EXIT WHEN mycursor%NOTFOUND;
      UPDATE_INV_OA_USE_LOG(proDecId,UPDATOR);
      DELETE FROM T_PLA_CU_ORDER_ITEM_PRO_DEC WHERE ID = proDecId;
    END LOOP;
    CLOSE mycursor;

  IF isDelItemDec = '1' THEN
--删除CustomerOrderItemDec
    DELETE FROM T_PLA_CUSTOMER_ORDER_ITEM_DEC WHERE ID =  ITEM_DEC_ID;
  END IF;

  END;