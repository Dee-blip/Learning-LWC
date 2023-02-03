public class AccountMovesCallout implements Promise.Deferred {


    
    public AccountMovesCallout()
    {
    }

    public Object resolve(Object incomingObject)
    {
        System.Debug(LoggingLevel.Error, 'AGH_D incomingObject:'+incomingObject);
        Map<String,Set<Id>> stepNameToPIRMap = (Map<String,Set<Id>>)incomingObject;
        String msg;

        if(incomingObject!=null )
        {
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            
            for(String stepNames : stepNameToPIRMap.keySet())
             {
                 Set<Id> processRequestId = stepNameToPIRMap.get(stepNames);
                 String commentString = stepNames.subStringAfterLast('_');
                 String action = stepNames.subStringBefore('_');
                 for(Id piwi : processRequestId)
                 {
                    Approval.ProcessWorkItemRequest pwr = new Approval.ProcessWorkItemRequest();
                    pwr.setComments(commentString);
                    pwr.setAction(action);  
                    pwr.setNextApproverIds(new Id[] {});

                    pwr.setWorkItemId(piwi);
                     requests.add(pwr);
                 }
                 
                 system.debug('Processing these requests '+requests);
                 Approval.ProcessResult[] processResults = Approval.process(requests);
                 system.debug('Processed Results '+processResults);
                                      Set<Id> accReassIdSet = new Set<Id>();

                 for(Approval.ProcessResult pr:processResults)
                 {
                                              
                     if(!pr.isSuccess())
                     {
                         accReassIdSet.add(pr.getEntityId());
                     }
                     
                 }
                 String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
                 msg = 'Hi '+ UserInfo.getName() +',' +'\r\n' +'\r\n' + 'Below are the record links for Account Moves which failed to process:'+'\r\n'+'\r\n';
                 for(Id arId:accReassIdSet){
                         msg = msg +baseUrl+'/'+arId  + '\r\n' ;}
                    msg = msg + '\r\n' +'Thank you';

                
                 
                 if(accReassIdSet.size() > 0)
                 {
                     Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.toAddresses = new String[] { UserInfo.getUserEmail() };
                        message.optOutPolicy = 'FILTER';
                        message.subject = 'Account Moves Failure:Mass Approve/Reject Account Moves Failed Records';
                        message.plainTextBody = msg;
                        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

                    
                 }
                 
                 
                 
                 if(stepNameToPIRMap.size() > 1)
                        stepNameToPIRMap.remove(stepNames);
                 
                 break;
                 
                    
              }
          }
            
        
        
        system.debug('Object '+(Object)stepNameToPIRMap);
        
        return (Object)stepNameToPIRMap;
    }


}