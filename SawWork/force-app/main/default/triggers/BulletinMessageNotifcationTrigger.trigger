trigger BulletinMessageNotifcationTrigger on SC_BulletinMsg__c (before insert,before update) {
    
    if (trigger.isBefore && trigger.isInsert){
         for(SC_BulletinMsg__c c:trigger.new){
             c.notification_queue__c = true;
         }
    }   
    
    if (trigger.isBefore && trigger.isUpdate){
        for(SC_BulletinMsg__c c:trigger.new){
        	SC_BulletinMsg__c oldRecord = trigger.oldmap.get(c.id);
            //workflow would have done update. workflow is only one who updates notification date
            if (oldRecord != null && oldRecord.Notification_Date_Time__c  != c.Notification_Date_Time__c){
                if(c.notification_queue__c) {
                	c.notification_queue__c = false;
                }    
            } 
        //if UI has done changes , let anything get changed . but 
            else if((oldRecord.Start_Date__c != c.Start_Date__c ||
                   oldRecord.End_Date__c != c.End_Date__c ||
                   oldRecord.Message_Text__c != c.Message_Text__c) && 
                  (oldRecord.Notification_Date_Time__c  == c.Notification_Date_Time__c)) {
                c.notification_queue__c = true;
            }
    	}
    }   
 }