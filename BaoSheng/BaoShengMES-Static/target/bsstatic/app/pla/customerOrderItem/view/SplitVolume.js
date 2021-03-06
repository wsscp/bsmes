Ext.define('bsmes.view.SplitVolume',{
   extend:'Ext.panel.Panel',
   id:'splitVolumePanel',
   width:'100%',
   layout:'column',
   defaults:{
       width:350
   },
   initComponent:function(){
       var me = this;
       var record = me.record;
       var result = me.result;

       var fieldArray = new Array();
       var orderItemId = record.get("id");

       //查询出当前订单明细已分解的卷数
       Ext.Ajax.request({
           url:'customerOrderItem/findOrderItemDec/'+orderItemId,
           method:'GET',
           async: false,
           success:function(response){
               var itemDecs = Ext.decode(response.responseText);
               if(itemDecs.length == 0){
                   fieldArray.push(formfieldObject());
               }
               Ext.Array.each(itemDecs,function(data,i){
                   var disabled = ('TO_DO' != data.status);
                   fieldArray.push(formfieldObject(result,data.length,data.id,disabled));
               });
           }
       });
       me.items = fieldArray;
       me.callParent(arguments);
   }
});

