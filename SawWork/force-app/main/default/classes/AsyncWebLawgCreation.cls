public without sharing class AsyncWebLawgCreation implements Queueable
{
    
    private string receivedJsonString;
    public AsyncWebLawgCreation(string receivedJsonString){
        this.receivedJsonString = receivedJsonString;
    }
    
    public void execute(QueueableContext context)
    {
        try 
        {
            WebhookLawg__c webLawg = new WebhookLawg__c();
            webLawg.JSON_Response__c = receivedJsonString;

            insert webLawg;
        } 
        catch(Exception e)
        {
            Sawyer.saw(e);
        }
    }
}