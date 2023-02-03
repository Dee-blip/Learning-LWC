/*

   Author - Anand Hegde Dec 2016
   */


public class LeadConversionResult{
    public Map<Id, List<Result>> leadIdToResults;

    public LeadConversionResult()
    {
        leadIdToResults = new Map<Id, List<Result>>();
    }

    public void addAll(LeadConversionResult lcr)
    {
        for(Id eyeDee : lcr.leadIdToResults.keySet())
        {
            leadIdToResults.put(eyeDee, lcr.leadIdToResults.get(eyeDee));
        }
    }

    public String generateTextLog()
    {
        List<String> logLines = new List<String>();
        Integer failedConversions =0;
        Integer succesfulConversions =0;

        for(Id eyeDee : leadIdToResults.keySet())
        {
            String logLine = '';

            for(Result r : leadIdToResults.get(eyeDee))
            {
                if(r.success)
                {
                    logLine += r.objectType + ' ' + r.dmltype + ' succeeded: ' + r.id+'.';
                    if(r.objectType.equals('Opportunity'))
                    {
                        succesfulConversions += 1;
                    }
                }
                else
                {
                    System.Debug(LoggingLevel.Error, 'AGH_D' +r);
                    logLine += r.objectType + ' ' + r.dmltype + ' failed: ' + r.relatedId+ ' - '+String.join(r.errors, ';')+'.';
                    if(r.objectType.equals('Opportunity'))
                    {
                        failedConversions += 1;
                    }
                }
            }
            logLines.add(logLine);
        }
        String logHeader = 'Succesful lead conversions: '+succesfulConversions+'\n'+'Failed conversions: '+failedConversions+'\n\n';
        return logHeader + String.join(logLines, '\n');
    }



    public List<Error_Log__c> generateErrorLogRecords()
    {
        List<Error_Log__c> errLogs = new List<Error_Log__c>();


        for(Id eyeDee : leadIdToResults.keySet())
        {
            Boolean allSuccess = true;

            // if all dmls have succeeded, then skip
            for(Result r : leadIdToResults.get(eyeDee))
            {
                if(!r.success)
                {
                    allSuccess = false;
                    break;
                }
            }

            if(!allSuccess)
            {
                String logLine = '';
                for(Result r : leadIdToResults.get(eyeDee))
                {
                    logLine = r.success ? (logLine + r.objectType + ' ' + r.dmltype + ' succeeded: ' + r.id+'.\n') : (logLine + r.objectType + ' ' + r.dmltype + ' failed: ' + r.relatedId+ ' - '+String.join(r.errors, ';')+'.\n');
                }
                errLogs.add(new Error_Log__c(Class__c='LeadConversionResult', Error_Message__c=logLine, RecordId__c=eyeDee));
            }
        }
        return errLogs;
    }



    public void addResult(DMLResults.Result res, Id relatedId, String dmltype, String objectType)
    {
        Result r = new Result()
                       .setRelatedId(relatedId)
                       .setDmlType(dmltype)
                       .setObjectType(objectType);

        if(res.success)
        {
            r.setSuccessStatus(true)
             .setId(res.id);
        }
        else
        {
            r.setErrors(res.errors);
        }

        if(leadIdToResults.containsKey(r.relatedId))
        {
            leadIdToResults.get(r.relatedId).add(r);
        }
        else
        {
            leadIdToResults.put(r.relatedId, new List<Result>{r});
        }

    }

    public class Result{
        public Id id;
        public Id relatedId;
        public String dmltype;
        public String objectType;
        public Boolean success;
        public List<String> errors;

        public Result()
        {
            this.success=false;
        }

        public Result setId(Id id)
        {
            this.id=id;
            return this;
        }

        public Result setRelatedId(Id relatedId)
        {
            this.relatedId=relatedId;
            return this;
        }

        public Result setDmlType(String dmltype)
        {
            this.dmltype = dmltype;
            return this;
        }

        public Result setObjectType(String objectType)
        {
            this.objectType=objectType;
            return this;
        }

        public Result setSuccessStatus(boolean succ)
        {
            this.success=succ;
            return this;
        }

        public Result setErrors(list<string> errors)
        {
            this.errors = errors;
            return this;
        }

    }

}