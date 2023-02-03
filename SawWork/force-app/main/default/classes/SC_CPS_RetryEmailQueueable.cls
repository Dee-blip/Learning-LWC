/*=====================================================================================================+
Class name          :   SC_CPS_RetryEmailQueueable 
Author              :   Aditya
Created             :   25-June-2019
Purpose             :  	To update CPS cases from batch SC_CPS_RetryEmailBatch to avoid future/batch to future call
Test Class			:	SC_CPS_RetryEmailBatch_Test
+=====================================================================================================*/
public class SC_CPS_RetryEmailQueueable implements Queueable{
    public List<Case> caseList;
    public String messageString = '';
    
    // Constructer for setting the Parameters
    Public SC_CPS_RetryEmailQueueable(list<Case> cpsCaseList){        
        this.caseList = cpsCaseList;
    }
    
    // Default Constructer 
    Public SC_CPS_RetryEmailQueueable(){}
    
    public void execute(QueueableContext context) {
        
        List<Database.saveresult> results = Database.update(caseList,false);
        for(Database.saveresult result :results)
        {
            if (!result.isSuccess()) 
            {
                for(Database.Error err : result.getErrors()) 
                {
                    messageString +=  ' '+ err.getMessage();
                }
                sendFailureEmail(messageString);
            }
            else
            {
                system.debug('--Success--');
            }  
        }
    }
    
    public void sendFailureEmail(string errorMsg){
        Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
        singleEmail.setSubject('Cases with CPS email failure:: SC_CPS_Queueable');
        singleEmail.setplainTextBody(errorMsg);
        singleEmail.setToAddresses(new String[] {'sc-dev@akamai.com'});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {singleEmail});
    }
}