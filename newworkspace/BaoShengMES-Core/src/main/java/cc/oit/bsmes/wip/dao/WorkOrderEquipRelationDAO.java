package cc.oit.bsmes.wip.dao;

import cc.oit.bsmes.common.dao.BaseDAO;
import cc.oit.bsmes.wip.model.WorkOrderEquipRelation;

public interface WorkOrderEquipRelationDAO extends BaseDAO<WorkOrderEquipRelation> {

	/**
	 * 删除生产单关联的设备关系
	 * 
	 * @author DingXintao
	 * @param workOrderNo 生产单编号
	 * @return int
	 * */
	public int deleteByWorkOrderNo(String workOrderNo);

	public void updateSeqByWorkOrderNoAndEquipCode(String v_oldWorkOrderNo, String v_newWorkOrderNo, String v_equipCode, String v_operator);

}
