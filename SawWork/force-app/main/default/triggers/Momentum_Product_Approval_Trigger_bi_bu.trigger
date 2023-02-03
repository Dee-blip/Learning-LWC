trigger Momentum_Product_Approval_Trigger_bi_bu on Momentum_Order_Product_Approval__c (before insert, before update) {
    if(Trigger.IsInsert){
    
        // interim solution - start ---
        /*
        for (Momentum_Order_Product_Approval__c mopa : Trigger.new) {
            String tmp = mopa.Name;
            System.debug('nametmp=' + tmp);
            List<String> strSplit = new List<String>();
            strSplit = tmp.split('#');
            System.debug(strSplit);
            if (strSplit.size()!=6)
                continue;
            
            String workflow_id = strSplit[0];
            String opportunity_id = strSplit[1];
            String momentum_order_id = strSplit[2];
            String created_by_alias = strSplit[3];
            String Order_Type = strSplit[4];
            String akam_momentum_product_approval_id = strSplit[5];
            // appId needs to be of String type since initiateApprovalWithOrderInfo returns a String value.
            //        possible return values:
            //        -1 cannot find opportunity
            //        -2 cannot find workflow
            //        -3 Other Salesforce error
            //        -4 Cannot find Order Approval.
            //        -5 cannot find user
            //
            try {
                String appId = ProductApprovalHandler.initiateApprovalWithOrderInfo(workflow_id, opportunity_id, momentum_order_id, created_by_alias, Order_Type);

                mopa.workflow_id__c = workflow_id;
                mopa.opportunity_id__c = opportunity_id;
                mopa.momentum_order_id__c = momentum_order_id;
                mopa.created_by_alias__c = created_by_alias;
                mopa.Order_Type__c = Order_Type;
                mopa.akam_momentum_product_approval_id__c = akam_momentum_product_approval_id;
                mopa.Product_Approval__c = appId;
                Boolean isMatch = Pattern.matches('-(\\d+)', appId); //Ali, is the regex correct to match '-5'? or shld it be '\\-(\\d+)'
                if(isMatch == true){
                    mopa.ErrorLog__c = appId;
                }
            //mopa.Name = mopa.momentum_order_id__c + '-' + mopa.workflow_id__c;
            //if (mopa.Name.length() > 79)
                //mopa.Name = mopa.Name.substring(0,79);
                
            } catch (Exception ex)
            {
                mopa.Product_Approval__c = '-10';
                mopa.ErrorLog__c = ex.getMessage(); // + '\nLineNumber=' + ex.getLineNumber() + '\n ExceptionType=' + ex.getTypeName() + '\n' + ex.getStackTraceString();                    
            }
        }*/
        // end ---
        
        Map<String, Approval_Workflow__c> approvalMap = new Map<String,Approval_Workflow__c>();
        for(Approval_Workflow__c aw : [select AKAM_Workflow_ID__c, isDraftable__c, isLockable__c from Approval_Workflow__c]){
            approvalMap.put(aw.AKAM_Workflow_ID__c, aw);
        }
        
        for(Momentum_Order_Product_Approval__c momProdApp : Trigger.new) {
            try {
                
                String appId = ProductApprovalHandler.initiateApprovalWithOrderInfo(momProdApp.workflow_id__c, momProdApp.opportunity_id__c, momProdApp.momentum_order_id__c, momProdApp.created_by_alias__c, momProdApp.Order_Type__c);
                momProdApp.Product_Approval__c = appId;
                if(approvalMap.get(momProdApp.workflow_id__c) != null){
                    momProdApp.approval_is_draftable__c = approvalMap.get(momProdApp.workflow_id__c).isDraftable__c;
                    momProdApp.approval_is_lockable__c = approvalMap.get(momProdApp.workflow_id__c).isLockable__c;
                }
                //Pattern pattern = Pattern.compile('-(\\d+)');
                Boolean isMatch = Pattern.matches('-(\\d+)', appId);
                if(isMatch == true){
                    momProdApp.ErrorLog__c = appId;
                }
            } catch (Exception ex)
            {
                momProdApp.Product_Approval__c = '-10';
                momProdApp.ErrorLog__c = ex.getMessage(); // + '\nLineNumber=' + ex.getLineNumber() + '\n ExceptionType=' + ex.getTypeName() + '\n' + ex.getStackTraceString();                    
            }
        }
    }
    
    if(Trigger.IsUpdate){
        Map<Id,Momentum_Order_Product_Approval__c> oldVals = Trigger.oldMap;
        
        for (Momentum_Order_Product_Approval__c momProdApp : Trigger.new) {
            Momentum_Order_Product_Approval__c oldVal = oldVals.get(momProdApp.Id);
            if(oldVal != null && (momProdApp.ErrorLog__c == null && momProdApp.ErrorLog__c != oldVal.ErrorLog__c)){
              try{
                String appId = ProductApprovalHandler.initiateApprovalWithOrderInfo(momProdApp.workflow_id__c, momProdApp.opportunity_id__c, momProdApp.momentum_order_id__c, momProdApp.created_by_alias__c, momProdApp.Order_Type__c);
                momProdApp.Product_Approval__c = appId;
                Boolean isMatch = Pattern.matches('-(\\d+)', appId);
                if(isMatch == true){
                    momProdApp.ErrorLog__c = appId;
                }
                
              }catch (Exception ex)
              {
                momProdApp.Product_Approval__c = '-10';
                momProdApp.ErrorLog__c = ex.getMessage(); // + '\nLineNumber=' + ex.getLineNumber() + '\n ExceptionType=' + ex.getTypeName() + '\n' + ex.getStackTraceString();                    
              }

            }
        }
        
    }
}