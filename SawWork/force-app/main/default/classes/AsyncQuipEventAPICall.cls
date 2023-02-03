public class AsyncQuipEventAPICall implements Queueable, Database.AllowsCallouts {
    public string nextCursor;
    public Integer linkNumber;
    public Integer responsePageLimit = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Quip_ResponsePageLimit'));
    
    public AsyncQuipEventAPICall(String cursor, Integer linkNumber) {
        this.linkNumber = linkNumber;
        this.nextCursor = cursor;
    }
    
    public AsyncQuipEventAPICall() {
        //get cursor
        QuipCalloutClass qc = new QuipCalloutClass();
        this.nextCursor = qc.getCursor();
        this.linkNumber=0;
    }
    
    public void execute(QueueableContext context) {
        //get event call until nextCursor is null
        if(nextCursor != null && linkNumber <= responsePageLimit)
        {
            QuipCalloutClass qc = new QuipCalloutClass();
            QuipEventJSONToField eventJsonToField;
            eventJsonToField = qc.getEvents(nextCursor);
            if(eventJsonToField != null && eventJsonToField.events != null)
            {
                List<Quip_Document_History__c> qList = eventJsonToField.getDocHistories();
                list<Error_log__c> errorList = new List<Error_log__c>();
                if(qList!=null && qList.size()>0)
                {
                    Database.SaveResult[] srList = database.insert(qList,false);
                    //iterate through each returned result
                    for (Database.SaveResult sr : srList) 
                    {
                        if (sr.isSuccess()){}
                        else {
                            String error = '';
                            for(Database.Error err : sr.getErrors()) 
                            {
                                error += err;
                            }
                            Error_log__c errorLog = new Error_log__c();
                            errorLog.Name = 'Sync Quip Event Log To SF';
                            errorLog.Class__c = 'AsyncQuipEventAPICall';
                            errorLog.Error_Message__c = error;
                            
                            if(errorLog.Error_Message__c!=null && errorLog.Error_Message__c.contains('Quip_Event_Id__c duplicates')){ /*skip duplicate errors*/ }
                            else{
                                errorList.add(errorLog);
                            }
                        }
                    }
                }
                
                //inserting failures into error logging table
                if(errorList.size()>0){
                    insert errorList;
                }
                
                //enqueuing AsyncQuipEventAPICall until next_cursor is null
                if(eventJsonToField.next_cursor!=null && eventJsonToField.more_to_read==true) {
                    System.enqueueJob(new AsyncQuipEventAPICall(eventJsonToField.next_cursor, linkNumber + 1));
                }
                //when there is no more events to read for the given time, calling QuipDocHistoryEnricherBatch to insert/update records in Account_Plan_Tracker__c
                else{
                    Integer enricherBatchSize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Quip_EnricherBatchSize'));
                    QuipDocHistoryEnricherBatch enricherBatch = new QuipDocHistoryEnricherBatch();
                    Database.executeBatch(enricherBatch,enricherBatchSize);
                }
            }
            else{
                Integer enricherBatchSize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Quip_EnricherBatchSize'));
                QuipDocHistoryEnricherBatch enricherBatch = new QuipDocHistoryEnricherBatch();
                Database.executeBatch(enricherBatch,enricherBatchSize);
            }
        } 
    }
}