public class DmlResults { 
    /*
       The bulk of this class has been borrowed from this recipe - 
       http://developer.force.com/cookbook/recipe/batch-pattern-for-handling-email-notifications-of-any-dml-exceptions
    */

    private boolean includeSuccess = false; 
    private boolean storeObjectState = false;
   // private Boolean saveErrorLog = false;
    private String className;
    private String htmlLog;
    private String textLog;
    public  Integer dmlsAttempted {get;private set;}
   // {}
    public  Integer failureCount {get; private set;}
    public  LIST<DMLResults.Result> results {get; private set;} 
    //{ results = new LIST<DMLResults.Result>(); } 
    

    private String defaultToAddress= GsmUtilClass.getGSMSettingValue('BatchClassStatusMailFallback');
    private String jobName;

    public void setStatusMailToAddress(String toAddr)
    {
        this.defaultToAddress= toAddr;
    }

    public DmlResults(Boolean storeObjectStateParam)
    {
        dmlsAttempted=0;
        failureCount=0;
        results = new LIST<DMLResults.Result>();
        this.storeObjectState = storeObjectStateParam;
    }

    public void storeObjectState()
    {
        System.Debug(LoggingLevel.error, 'AGH_D storeObjectState called');
        this.storeObjectState=true;
    }

    public void includeSuccess()
    {
        this.includeSuccess=true;
    }


    

    


    public void clear()
    {
        this.results.clear();
        htmlLog='';
        textLog='';
        dmlsAttempted =0;
        failureCount=0;
    }

    /**
     * constructor
     * @param lst a LIST of [Saveresult | Upsertresult |Deleteresult | Undeleteresult]
     * @param records the LIST of sobjects that were included in the dml statement.
     */
    public DMLResults() {
        dmlsAttempted=0;
        failureCount=0;
        results = new LIST<DMLResults.Result>();
    } 
    public DMLResults(Boolean storeObjectStateParam, Boolean includeSuccessParam) 
    {
        dmlsAttempted=0;
        failureCount=0;
        results = new LIST<DMLResults.Result>();
        this.includeSuccess=includeSuccessParam;
        this.storeObjectState=storeObjectStateParam;
    }


    public DMLResults(LIST<object> lst) { 
        dmlsAttempted=0;
        failureCount=0;
        results = new LIST<DMLResults.Result>();
        add(lst,null);
    } 

    /*
    public DMLResults(LIST<object> lst, Boolean storeObjSt) { 
        this(lst,null,storeObjSt);
    } 
    */


    public void add(LIST<object> lst,  LIST<sobject> records, Boolean storeObjectState) { 
        integer cnt=0; 
        dmlsAttempted += lst.size();
        System.Debug(LoggingLevel.Error, 'AGH_D cons A'+lst.size()+' and fail'+failureCount+'and dmls '+dmlsAttempted);
        for (Object o : lst) { 
            try { 
                Result  r; 
                SObject sObjectRecord = (records!=null) ? records[cnt] : null;
                System.Debug(LoggingLevel.Error, 'AGH_D instantiating result now');
                //Type t = Type.forName(o);
                //System.Debug(LoggingLevel.error, 'AGH_D type is'+t.getName());
                if (o instanceof Database.Saveresult )         
                {
                    r= new Result((Database.Saveresult) o, sObjectRecord, storeObjectState); 
                }
                else if (o instanceof Database.Upsertresult )  
                {
                    r= new Result((Database.Upsertresult) o, sObjectRecord, storeObjectState); 
                }
                else if (o instanceof Database.Deleteresult)   
                {
                    r= new Result((Database.Deleteresult) o, sObjectRecord, storeObjectState); 
                }
                else if (o instanceof Database.Undeleteresult) 
                {
                    r= new Result((Database.Undeleteresult) o, sObjectRecord, storeObjectState); 
                }
                else 
                {
                    System.Debug(LoggingLevel.Error, 'AGH_D instantiating result upsert');
                    throw new InvalidResultException('Invalid DML Result.');
                }

                if (includeSuccess || (!r.success) ) { 
                    System.Debug(LoggingLevel.Error, 'AGH_D adding now'+r);
                    this.add(r);
                } 
            }catch(exception ex) { 
                System.Debug(LoggingLevel.Error, 'AGH_D exception in adding'+ex.getStackTraceString());
            }     
            cnt++;     
        }     
        System.Debug(LoggingLevel.Error, 'AGH_D cons a final '+dmlsAttempted);

    } 

    /**
     * add additional exceptions
     * @param lst a LIST of [Database.Saveresult | Database.Upsertresult | Database.Deleteresult | Database.Undeleteresult]
     * @param records the LIST of sobjects that were included in the dml statement.
     */

    public void add(LIST<object> lst) { 
        System.Debug(LoggingLevel.Error, 'AGH_D cons Y '+lst.size()+' and fail'+failureCount);
        add(lst,null, storeObjectState); 
    } 

    public void add(LIST<object> lst,  LIST<sobject> records) { 
        System.Debug(LoggingLevel.Error, 'AGH_D cons Z '+lst.size()+' and fail'+failureCount);
        add(lst,records,storeObjectState); 
    } 

    public void add(DMLResults.Result r) { 
        System.Debug(LoggingLevel.Error, 'AGH_D cons B '+dmlsAttempted+' and fail'+failureCount);
        if(!r.success){
            failureCount++;
        }
        results.add(r); 
    }     

    public void add(DMLResults dmlr) { 
        System.Debug(LoggingLevel.Error, 'AGH_D cons C '+dmlr.results+' and dmls'+dmlsAttempted+' and out'+dmlr.dmlsAttempted);
        dmlsAttempted += dmlr.dmlsAttempted;
        for(DMLResults.Result dr : dmlr.results)
        {
            if(!dr.success){
                failureCount++;
            }

        }
        results.addAll(dmlr.results); 
    } 

    public void add(LIST<DMLResults.Result> lst) { 
        System.Debug(LoggingLevel.Error, 'AGH_D cons D '+lst.size()+' and fail'+failureCount);

        this.dmlsAttempted += lst.size();
        for(DMLResults.Result dr : lst)
        {
            if(!dr.success){
                failureCount++;
            }

        }
        results.addAll(lst); 
    } 

    public DmlResults withClassName(String className)
    {
        this.className = className;
        return this;
    }

    public Map<Id, List<String>> fetchErrorLogs()
    {
        Map<Id, List<String>> idToErrors = new Map<Id, List<String>>();

        for(DMLResults.Result r : results) 
        {
            if(r.Id!=null && !r.success)
            {
                idToErrors.put(r.Id, r.errors);
            }
        }

        return idToErrors;
    }

    public void insertRecordsInErrorLog()
    {
        if(failureCount>0)
            Sawyer.saw(results, className);
            /*
        Boolean errorExists=(failureCount>0);
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        if(errorExists)
        {
            for(DMLResults.Result r : results) 
            {
                Error_Log__c el = new Error_Log__c(Name=className, Class__c=className, Error_Message__c=String.join(r.errors, '\n') , RecordId__c=r.Id,Object_State__c=r.getRecordStateJson());
                errorLogs.add(el);
            }
        }

        if(errorLogs.size()>0)
            Database.insert(errorLogs, false);
            */

    }

    public string resultsToString() { 
        if(!String.isBlank(textLog))
            return textLog;

        string textResult; 
        textResult='Total records that were attempted to modify : '+dmlsAttempted+'\n'; 
        textResult+='Total records failed : '+failureCount+'\n\n\n';
        Boolean errorExists=(failureCount>0);

        for(DMLResults.Result r : results) { 

            if(errorExists || includeSuccess){
                textResult += String.join(r.errors, '\n')+'\n';

            } 
            textResult += '\n';
        }
        textLog = textResult;
        return textLog;     
    } 

    public string resultsToHtml() { 

        if(!String.isBlank(htmlLog))
            return htmlLog;

        string htmlResult; 
        htmlResult='Total records that were attempted to modify : '+dmlsAttempted+'<br/>'; 
        htmlResult+='Total records failed : '+failureCount+'<br/><br/><br/>';
        Boolean errorExists=(failureCount>0);

        if(errorExists){
            htmlResult += '<table border="1" style="border-collapse:collapse;"cellpadding="10" cellspacing ="5"><tr><th>Record Link</th><th>Status</th><th>Log</th><th>Record State</th></tr>';
            for(DMLResults.Result r : results) { 

                if(errorExists || includeSuccess){
                    htmlResult+='<tr><td>'+r.recordURL()+'</td><td>'+((r.success)?'Succeeded':'Failed')+'</td><td>'+String.join(r.errors, '<br/>')+'</td><td>'+r.getRecordStateJson()+'</td></tr>';

                } 
            }
            htmlResult += '</table>';
        }
        htmlLog = htmlResult;
        return htmlResult;     
    }     


    public void stampCronRunLog() 
    {
        if(String.isBlank(this.jobName))
            return;

        Cron_Batch_Run__c cronRun = [select id, CreatedDate, Result__c from Cron_Batch_Run__c  where Batch_Job_Type__c = :jobName and Result__c!=null order by CreatedDate DESC limit 1][0];

        String resultString = resultsToString();
        if (results.size()>0) 
        {
            resultString = resultsToString();
        }
        else
        {
            resultString = 'No records to update or insert';
        }
        if(resultString.length() >= 32000)
            resultString = resultString.substring(0, 31999);

            cronRun.Results__c = resultString;
            update cronRun;
    } 

    public DMLResults withJobName(String jName){
        this.jobName = jName;
        return this;
    }

    public DMLResults toAddress(String emailAddresses){
        this.defaultToAddress = emailAddresses;
        return this;
    }


    public void sendLogMail() {
        boolean html = true; 
        // Send an email to the Apex job's submitter (or emailOverride) notifying of job completion. 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        String[] toAddresses=defaultToAddress.split(',');

        mail.setToAddresses(toAddresses); 
        mail.setSubject('Apex Job '+jobName+' completed'); 

        string s = 'Your Apex Job '+jobName+' completed.<br/><br/>';


        //show error table
        if(html) { 
            s+=resultsToHtml(); 
            System.Debug(LoggingLevel.Error, 'AGH_D'+s);
            mail.setHtmlBody(s); 
        }else { 
            s+=resultsToString(); 
            mail.setPlainTextBody(s); 
        } 
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
    } 

    public void dmlInsert(LIST<sObject> records) { 
        dmlInsert(records, false); 
    }

    public void dmlInsert(LIST<sObject> records,Boolean opt_allOrNone) {
        this.add(Database.insert(records, opt_allOrNone),records);
    }

    //one day I hope an upsert wont require a strongly typed object
    //public static DmlResults dmlUpsert(LIST<sObject> records, Schema.Sobjectfield External_ID_Field, Boolean opt_allOrNone) {
    //return new DmlResults(Database.upsert(records, (Schema.Sobjectfield) External_ID_Field, opt_allOrNone),records);
    //}

    public void dmlUpdate(LIST<sObject> records)  { 
        dmlUpdate(records, false); 
    }

    public void dmlUpdate(LIST<sObject> records,Boolean opt_allOrNone) {
        this.add(Database.update(records,opt_allOrNone),records);
    }

    public void dmlDelete(LIST<sObject> records)  { 
        dmlDelete(records, false); 
    }

    public void dmlDelete(LIST<sObject>records,Boolean opt_allOrNone) {
        this.add(Database.delete(records,opt_allOrNone),records);
    }


    public class Result {
        public Id id 				{get;set;}
        public String name          {get;set;}
        //Maybe add AKAM Id support?
        //Database.Error[] errors = new Database.Error[]{};
        public List<string> errors 		{get;private set;}
        public boolean success 		{get;set;}
        public string statusCode	{get;set;}

        public Map<String,Object> recordState=new Map<String, Object>();

        public Map<String, Object> getRecordState(){
            return this.recordState;
        }

        public String getRecordStateJson(){
            return JSON.serialize(this.recordState);
        }


        public String recordURL(){
            return '<a href="'+ URL.getSalesforceBaseUrl().toExternalForm()+'/'+this.id+'">' +this.name + '</a>';           
        }


        public Result(Database.Saveresult r) { 
            this(r,null); 
        }

        public Result(Database.Saveresult r, sobject sObj) {
            this(r,sObj,false);
        }

        public Result(Database.Saveresult r, sobject sObj, Boolean storeObjectState) {
            if (r.getId()!=null) 
                id=r.getId(); 
            else if (sObj!=null && sObj.id!=null) 
                id=sObj.Id; 
            System.Debug(LoggingLevel.Error, 'AGH_D sobj' + sobj);
            if(sObj!=null && sObj.getPopulatedFieldsAsMap().containsKey('Name'))
                name=(String)sObj.get('Name');
            statusCode = (!r.getErrors().isEmpty()) ? string.valueOf(r.getErrors()[0].getStatusCode()) : null;
            success=r.isSuccess();
            if(!success){
                errors = new List<String>();
                for(Database.Error err : r.getErrors()) 
                {                  
                    if(err.getFields().size()>0)
                    {
                        errors.add(err.getFields() +': ' + err.getMessage());
                    }
                    else
                    {
                        errors.add(err.getMessage());
                    }

                }
            }

            if(storeObjectState)
                recordState =sObj.getPopulatedFieldsAsMap();
        }

        public Result(database.Deleteresult r) { 
            this(r,null); 
        }

        public Result(Database.DeleteResult r, sobject sObj) {
            this(r,sObj,false);
        }

        public Result(database.Deleteresult r,sobject sObj, Boolean storeObjectState) {
            if (r.getId()!=null) 
                id=r.getId(); 
            else if (sObj!=null && sObj.id!=null) 
                id=sObj.Id; 
            if(sObj!=null && sObj.getPopulatedFieldsAsMap().containsKey('Name'))
                name=(String)sObj.get('Name');
            statusCode = (!r.getErrors().isEmpty()) ? string.valueOf(r.getErrors()[0].getStatusCode()) : null;
            success=r.isSuccess();
            if(!success){
                errors = new List<String>();
                for(Database.Error err : r.getErrors()) 
                {                  
                    if(err.getFields().size()>0)
                    {
                        errors.add(err.getFields() +': ' + err.getMessage());
                    }
                    else
                    {
                        errors.add(err.getMessage());
                    }

                }
            }
            if(storeObjectState)
                recordState =sObj.getPopulatedFieldsAsMap();
        }

        public Result(database.Upsertresult r) { 
            this(r,null); 
        }

        public Result(database.Upsertresult r, sobject sObj) { 
            this(r,null, false); 
        }

        public Result(database.Upsertresult r,sobject sObj, Boolean storeObjectState) {
            if (r.getId()!=null) 
                id=r.getId(); 
            else if (sObj!=null && sObj.id!=null) 
                id=sObj.Id; 
            if(sObj!=null && sObj.getPopulatedFieldsAsMap().containsKey('Name'))
                name=(String)sObj.get('Name');
            statusCode = (!r.getErrors().isEmpty()) ? string.valueOf(r.getErrors()[0].getStatusCode()) : null;
            success=r.isSuccess();
            System.Debug(LoggingLevel.Error, 'AGH_D upsert success '+success);
            if(!success){
                errors = new List<String>();
                for(Database.Error err : r.getErrors()) 
                {                  
                    if(err.getFields().size()>0)
                    {
                        errors.add(err.getFields() +': ' + err.getMessage());
                    }
                    else
                    {
                        errors.add(err.getMessage());
                    }
 
                }
            }
            System.Debug(LoggingLevel.Error, 'AGH_D upsert success '+errors);

            if(storeObjectState)
                recordState =sObj.getPopulatedFieldsAsMap();
        }

        public Result(Database.Undeleteresult r) { 
            this(r,null); 
        } 

        public Result(Database.Undeleteresult r,sobject sObj) { 
            this(r,sObj,false);
        }

        public Result(Database.Undeleteresult r,sobject sObj, Boolean storeObjectState) { 
            if (r.getId()!=null) 
                id=r.getId(); 
            else if (sObj!=null && sObj.id!=null) 
                id=sObj.Id; 
            if(sObj!=null && sObj.getPopulatedFieldsAsMap().containsKey('Name'))
                name=(String)sObj.get('Name');
            //SFDC-1572
            //statusCode = (!r.getErrors().isEmpty()) ? string.valueOf(r.getErrors()[0].getStatusCode()) : null; 
            success=r.isSuccess(); 
            if(!success){
                errors = new List<String>();
                for(Database.Error err : r.getErrors()) 
                {                  
                    if(err.getFields().size()>0)
                    {
                        errors.add(err.getFields() +': ' + err.getMessage());
                    }
                    else
                    {
                        errors.add(err.getMessage());
                    }

                }
            }
            if(storeObjectState)
                recordState =sObj.getPopulatedFieldsAsMap();
        } 
    }

    public class InvalidResultException extends Exception {} 



}