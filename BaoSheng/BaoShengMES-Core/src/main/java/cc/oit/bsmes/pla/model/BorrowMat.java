package cc.oit.bsmes.pla.model;

import javax.persistence.Table;

import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import cc.oit.bsmes.common.constants.MaterialStatus;
import cc.oit.bsmes.common.model.Base;

@Data
@EqualsAndHashCode(callSuper = false)
@ToString(callSuper = true)
@Table(name = "T_INV_BORROW_MAT")
public class BorrowMat extends Base{
	
	private static final long serialVersionUID = 5648927173623455245L;
	private String workOrderNo;
	private String equipCode;
	private String userCode;
	private String matCode;
	private String planAmount;
//	private String materialName;//物料名称
	private Double yaoLiaoQuantity;
	private Double jiTaiQuantity;
	private Double faLiaoQuantity;
//	private Double buLiaoQuantity;
	private MaterialStatus status;
}
