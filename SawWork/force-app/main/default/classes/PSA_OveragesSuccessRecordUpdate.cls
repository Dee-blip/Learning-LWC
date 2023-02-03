public class PSA_OveragesSuccessRecordUpdate implements Queueable {

	public List<PS_Overage_Hours__c> updatedOveragesList;    
    public PSA_OveragesSuccessRecordUpdate(List<PS_Overage_Hours__c> updatedOverages){
        updatedOveragesList = updatedOverages;
    }
    
    public void execute(QueueableContext context) {
        System.debug('***updatedOveragesList: '+updatedOveragesList);
        Database.SaveResult[] saveResults = Database.update(updatedOveragesList,false);
        for(Integer i = 0; saveResults != null && i < saveResults.size(); i++)
        {
            System.debug('*** new sr:'+saveResults.get(i));
        }    
    }
}