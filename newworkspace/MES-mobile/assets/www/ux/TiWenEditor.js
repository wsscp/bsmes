Ext.define('Ext.ux.TiWenEditor', {
	extend : 'Ext.Panel',
	xtype : ['tiweneditor'],
	requires : ['Ext.form.Panel', 'Ext.form.FieldSet', 'Ext.field.Number',
			'Ext.field.DatePicker', 'Ext.ux.field.DateTimePicker'],
	config : {
		id : 'tiwenEditor',
		width : '100%',// 200,
		height : '100%',
		title : '编辑',
		items : [{
					xtype : 'formpanel',
					id : 'tiwenFormPanel',
					width : '100%',// 200,
					height : '100%',
					items : [{
								xtype : 'fieldset',
								title : '',
								instructions : '',
								items : [{
											xtype : 'datetimepickerfield',
											name : 'date',
											value : new Date(),
											//dateFormat: 'Y-m-d',
											dateTimeFormat : 'Y-m-d H:i',
											label : '日期',
						                    picker: {
						                    	useTitles: true,
						                        yearFrom: 1980,
						                        minuteInterval : 1,
						                        ampm : false,
						                        yearText: '年',
						                        monthText: '月',
						                        dayText: '日',
						                        hourText: '时',
						                        minuteText: '分',
						                        slotOrder: ['year', 'month', 'day', 'hour','minute']
						                    }
										}, {
											xtype : 'numberfield',
											name : 'volume',
											minValue : 0,
											maxValue : 1000,
											label : '温度'
										}, {
											xtype : 'textareafield',
											name : 'remark',
											label : '备注'
										}]
							}]
				}, {
					xtype : 'toolbar',
					title : '体温记录',
					dock : 'top',
					items : [{
								text : '返回',
								ui : 'back',
								handler : function() {
									Ext.getCmp('tiwenView').pop();
								}
							}, {
								xtype : 'spacer'
							}, {
								text : '删除',
								ui : 'action',
								handler : function() {
									Ext.Msg.confirm('删除记录', '是否真要删除当前记录?', function(res){
										if (res == 'yes') {
											var tiwenFormPanel = Ext .getCmp('tiwenFormPanel');
											var tiwenRecord = tiwenFormPanel.getRecord();
											if (tiwenRecord.data.itemhash != "") {
												del("weiyang", tiwenRecord.data.itemhash);
												tiwenStore.remove(tiwenRecord);
											}
											
											Ext.getCmp('tiwenView').pop();
										}
									}, this);
								}
							}, {
								text : '保存',
								ui : 'action',
								handler : function() {
									var tiwenFormPanel = Ext .getCmp('tiwenFormPanel');
									var tiwenRecord = tiwenFormPanel.getRecord();
									var newValues = tiwenFormPanel.getValues();

									tiwenRecord.set("date", Ext.Date.format(newValues.date, "Y-m-d H:i"));
									//tiwenRecord.set("time", Ext.Date.format(newValues.time, "H:i"));
									tiwenRecord.set("volume", newValues.volume);
									tiwenRecord.set("remark", newValues.remark);
									
									var now = new Date();
									var isNew = false;
									if (tiwenRecord.data.itemhash == "") {
										var noteId = (now.getTime()).toString() + (getRandomInt(0, 100)).toString();
										tiwenRecord.set("itemhash", noteId);
										isNew = true;
									}
									
									var sqlData = {};
									for(var i in tiwenRecord.data) {
										sqlData[i] = tiwenRecord.data[i]; 
									}
									delete sqlData.id;
									
									if(isNew) {
										insert("weiyang",sqlData);
										//Ext.getCmp('tiwenlist').loadDate();
										tiwenStore.add(tiwenRecord);
									} else {
										update("weiyang",sqlData);
									}
									tiwenStore.sync();
									
									Ext.getCmp('tiwenView').pop();
								}
							}]
				}]
	}
});