/*=====================================================================================================+
    Trigger name        :   SC_Billing_Configuration_bi_bu 
    Author              :   Vamsee Surya
    Created             :   01-Dec-16
    Purpose             :   CR #3564721 : Trigger to validate the data on Billing Case Resource Configuration record creation and updation
+=====================================================================================================*/

trigger SC_Billing_Configuration_bi_bu on Billing_Case_Resource_Configuration__c (before insert, before update) {
    	Billing_Case_Resource_Configuration__c[] billingConfigList = [SELECT Id,Assignment_Order__c,User__c,User_Profile__c FROM  Billing_Case_Resource_Configuration__c];
        map<integer,Billing_Case_Resource_Configuration__c> assignmentOrderMap = new map<integer,Billing_Case_Resource_Configuration__c>();
        map<Id,Billing_Case_Resource_Configuration__c> userIdMap = new map<Id,Billing_Case_Resource_Configuration__c>();
        for(Billing_Case_Resource_Configuration__c bc: billingConfigList){
            if(!(Trigger.isUpdate && Trigger.newMap.containsKey(bc.Id))){
                assignmentOrderMap.put((integer)bc.Assignment_Order__c, bc);
            	userIdMap.put(bc.User__c, bc);
            }
        }
    	for(Billing_Case_Resource_Configuration__c bcNew : Trigger.New){
            if(bcNew.Assignment_Order__c < 1){
                    bcNew.addError('Assignment order should be a positive number greater than zero.');
                }
            else if(bcNew.User_Profile__c != 'Support - Billing Support Agent' && bcNew.User_Profile__c != 'Support - Billing Support Manager'){
                    bcNew.addError('User should be part of the Billing Support Team');
                }
            else if(assignmentOrderMap.containsKey((integer)bcNew.Assignment_Order__c)){
                    bcNew.addError('Multiple entries with the same Assignment Order. Please make sure the Assignment Order is unique');
                }
           	else if(userIdMap.containsKey(bcNew.User__c)){
                    bcNew.addError('Multiple entries with the same User. Please make sure the User entries are unique.');
                }
            else{
                	assignmentOrderMap.put((integer)bcNew.Assignment_Order__c, bcNew);
            		userIdMap.put(bcNew.User__c, bcNew);
            }  
     	}
}