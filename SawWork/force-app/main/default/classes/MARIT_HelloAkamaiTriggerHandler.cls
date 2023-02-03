public class MARIT_HelloAkamaiTriggerHandler extends ApexTriggerHandlerAbstractClass{
    public MARIT_HelloAkamaiTriggerHandler(){
    }
    public override void beforeInsertBeforeUpdateTrigger(){
    }
    public override void beforeDeleteBeforeUndeleteTrigger() {
    }
    public override void afterInsertAfterUpdateTrigger(){
        if(Trigger.isInsert) {
            try{
                Set<Id> contactIds = new Set<Id>();
                //Map<Id,Contact> updateContactMap = new Map<Id,Contact>();
                for(SObject so: newList) {
                    Hello_Akamai_Activity__c acRec =  (Hello_Akamai_Activity__c)so;
                    contactIds.add(acRec.Contact__c);
                }
                
                Map<Id,Contact> contactMap = new Map<Id,Contact>([Select Id,HelloAkamai_Weekly_Activation__c,
                                                                  HelloAkamai_Cumulative_Activation__c,HelloAkamai_Cumulative_Tarballs__c,
                                                                  HelloAkamai_Last_Login_Date__c,HelloAkamai_Weekly_Logins__c,HelloAkamai_Weekly_Tarballs__c     
                                                                  From Contact where Id In :contactIds]);
                
                System.debug(contactMap);                
                for(SObject so: newList) {
                    Hello_Akamai_Activity__c acRec =  (Hello_Akamai_Activity__c)so;
                    Contact c;
                    if(contactMap.containsKey(acRec.Contact__c)){
                        c= contactMap.get(acRec.Contact__c);
                        
                    }
                    System.debug(c);
                    if(acRec.Event__c=='Login'){
                        c.HelloAkamai_Last_Login_Date__c=DateTime.now();
                        if(c.HelloAkamai_Weekly_Logins__c==null){
                            c.HelloAkamai_Weekly_Logins__c=1;
                        }else{
                            c.HelloAkamai_Weekly_Logins__c=c.HelloAkamai_Weekly_Logins__c+1;
                        }
                    } else if(acRec.Event__c=='TarballDeployed'){
                        if(c.HelloAkamai_Weekly_Tarballs__c==null){
                            c.HelloAkamai_Weekly_Tarballs__c=1;
                        } else{
                            c.HelloAkamai_Weekly_Tarballs__c=c.HelloAkamai_Weekly_Tarballs__c+1;
                        }
                        if(c.HelloAkamai_Cumulative_Tarballs__c==null){
                            c.HelloAkamai_Cumulative_Tarballs__c=1;
                        } else{
                            c.HelloAkamai_Cumulative_Tarballs__c=c.HelloAkamai_Cumulative_Tarballs__c+1;
                        }
                    } else if(acRec.Event__c=='Activation'){
                        if(c.HelloAkamai_Weekly_Activation__c==null){
                            c.HelloAkamai_Weekly_Activation__c=1;
                        } else{
                            c.HelloAkamai_Weekly_Activation__c=c.HelloAkamai_Weekly_Activation__c+1;
                        }
                        
                        if(c.HelloAkamai_Cumulative_Activation__c==null){
                            c.HelloAkamai_Cumulative_Activation__c=1;
                        } else {
                            c.HelloAkamai_Cumulative_Activation__c=c.HelloAkamai_Cumulative_Activation__c+1;
                        }
                    }
                    contactMap.put(acRec.Contact__c,c);
                }
                Database.update(contactMap.values(),false);
            } catch (Exception e){
                System.debug(e);
                Error_Log__c updateError = new Error_Log__c(Name='Exception in after insert contact update', Class__c='MARIT_HelloAkamaiTriggerHandler.afterInsertAfterUpdateTrigger', Error_Message__c='Exception : ' +e);
                insert updateError;
            }
        }
    }
    public override void afterDeleteAfterUndeleteTrigger() {
    }
}