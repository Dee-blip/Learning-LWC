public without sharing class Sawyer {

	private static final String CLASSNAME = Sawyer.class.getName();
    //private static String trId=null;
    private static final Pattern STACK_LINE = Pattern.compile('^(?:Class\\.)?([^.]+)\\.?([^\\.\\:]+)?[\\.\\:]?([^\\.\\:]*): line (\\d+), column (\\d+)$');
    /*
       Class.OpportunityUtils.findBestCustForPid: line 357, column 9
       Class.OpportunityUtils.determineCustomerPid: line 189, column 17
       Class.OpportunityUtils.determineCustomer: line 70, column 14
       Class.DetermineCustomerController.doDetermine: line 38, column 12

	public static void debug(String message) {
		debug(message,  null);
	}



	public static void debug(Id contextId) {
		debug('', contextId);
	}


	public static void debug(String message, Id contextId) 
    {
		System.debug(LoggingLevel.Error, message);

	}

	public static void saw(String message) {
		saw(message,  null);
	}



	public static void saw(Id contextId) {
		saw('', contextId);
	}





	public static void saw(String message, Id contextId) 
    {
        Lawg__e currentEvent = new Lawg__e();
        currentEvent.User_ID__c = UserInfo.getUserId();
        currentEvent.Message_Text__c = message!=null ? message.left(2000) : '';
        currentEvent.Record_Id__c=contextId;
        populateLocation(currentEvent);

        EventBus.publish(currentEvent);
    }


	public static void saw(List<Metrics_Lawg__e> lgs) 
    {
        List<Metrics_Log__c> mls = new List<Metrics_Log__c>();
        for(Metrics_Lawg__e l : lgs)
        {

            mls.add(new Metrics_Log__c(
                        CPU_Time__c=l.CPU_Time__c,
                        Email_Invocations__c=l.Email_Invocations__c,
                        Heap_Size__c=l.Heap_Size__c,
                        Callout_Count__c=l.Callout_Count__c,
                        Object_Type__c=l.Object_Type__c,
                        Queueable_Job_Count__c=l.Queueable_Job_Count__c,
                        Transaction_ID__c=l.Transaction_ID__c,
                        Record_Id__c=l.Record_Id__c,
                        Request_URL__c=l.Request_URL__c,
                        SOQL_Count__c=l.SOQL_Count__c,
                        TStamp__c=l.TStamp__c,
                        Transaction_Stage__c=l.Transaction_Stage__c,
                        User_ID__c=l.User_ID__c,
                        User_Profile_Id__c=l.User_Profile_Id__c,
                        User_Type__c=l.User_Type__c
                        ));
        }
        
        
        if(mls.size()>0)
            insert mls;
    }

    public static string getTransactionID(Id rId, 
            Integer bulkRecordCount, Id uId, Long timeT)
    {
        if(trId==null)
            trId = 
                String.format(
                        '{0}-{1}-{2}-{3}',
                        new List<String>{
                            String.valueOf(rId),
                            String.valueOf(bulkRecordCount),
                            String.valueOf(uId),
                            String.valueOf(timeT)
                }
                        );

        return trId;
    }

    public static void logMetrics(String trId, 
            Id rId, String objType, String trStage)
    {
        Metrics_Lawg__e lg = new Metrics_Lawg__e();
        lg.User_ID__c = UserInfo.getUserId();
        lg.User_Type__c=UserInfo.getUserType();
        lg.User_Profile_Id__c=UserInfo.getProfileId();
        lg.TStamp__c=(Long)System.now().getTime();
        lg.Callout_Count__c=Limits.getCallouts();
        lg.Transaction_ID__c=trId;
        lg.CPU_Time__c=Limits.getCpuTime();
        lg.Email_Invocations__c=Limits.getEmailInvocations();
        lg.Heap_Size__c=Limits.getHeapSize();
        lg.SOQL_Count__c=Limits.getQueries();
        String rUrl = System.URL.getCurrentRequestUrl().toExternalForm();
        lg.Request_URL__c = String.isBlank(rUrl)?'':rUrl.left(255);
        lg.Record_Id__c=rId;
        lg.Queueable_Job_Count__c=Limits.getQueueableJobs();
        lg.Transaction_Stage__c=trStage;
        lg.Object_Type__c = objType;

        EventBus.publish(lg);
    }
    public static void clearMetrics()
    {
        List<Metrics_Log__c> logs=[select id
                from Metrics_Log__c 
                limit 10000];

        if (logs!=null)
            delete logs;
    }

    public static void computeTimeTaken()
    {
        List<Metrics_Log__c> logsToUpdate = new List<Metrics_Log__c>();
        Map<String, Double> trIdToLatestTimestamp = new Map<String, Double>();
        Map<String, Double> trIdToLatestCPUTime = new Map<String, Double>();

        for(Metrics_Log__c ml:[select id,
            Transaction_ID__c,
            TStamp__c,
            CPU_Time__c,
            MS_Spent_CPU__c,
            MS_Spent_DB__c
                from Metrics_Log__c 
                where MS_Spent_CPU__c=null
                order by TStamp__c asc
                limit 10000])
        {
            String trId = ml.Transaction_ID__c;

            ml.MS_Spent_CPU__c=trIdToLatestCPUTime.containsKey(trId)? ml.CPU_Time__c-trIdToLatestCPUTime.get(trId):0;
            trIdToLatestCPUTime.put(trId, ml.CPU_Time__c);
            ml.MS_Spent_DB__c=trIdToLatestTimestamp.containsKey(trId)?(ml.TStamp__c-trIdToLatestTimestamp.get(trId)-ml.MS_Spent_CPU__c):0;
            trIdToLatestTimestamp.put(trId, ml.TStamp__c);
            logsToUpdate.add(ml);
        }

        if (logsToUpdate.size()>0)
            update logsToUpdate;
    }

*/

    public static void saw(List<Database.DeleteResult> drList, String clsName, String jobName)
    {
        Integer count = 0;
        List<Lawg__e> lgs = new List<Lawg__e>();
        for(Database.DeleteResult dr : drList)
        {
            if(!dr.isSuccess())
            {
                String errMessage = '';
                for(Database.Error err : dr.getErrors())
                {
                    if(err.getFields().size()>0)
                    {
                        errMessage += String.join(err.getFields(), ' AND ') +': ' + err.getMessage() + '\n';
                    }
                    else
                    {
                        errMessage += err.getMessage() + '\n';
                    }
                }

                Lawg__e lg = new Lawg__e();
                lg.User_ID__c = UserInfo.getUserId();
                lg.Message_Text__c = String.isBlank(errMessage) ?'': errMessage.left(2000);
                lg.Class__c=clsName.left(60);
                lg.Method__c=jobName.left(80);
                lg.Record_Id__c = dr.getId();

                lgs.add(lg);

            }
            count += 1;
        }

        if(lgs.size()>0)
            EventBus.publish(lgs);
    }

    public static void saw(List<Database.SaveResult> saveres,
            List<Sobject> recordsToBeUpdated, String clsName, String jobName)
    {
        Integer count = 0;
        List<Lawg__e> lgs = new List<Lawg__e>();
        for(Database.SaveResult result : saveres)
        {
            if(!result.isSuccess())
            {
                String errMessage = '';
                for(Database.Error err : result.getErrors())
                {
                    if(err.getFields().size()>0)
                    {
                        errMessage += String.join(err.getFields(), ' AND ') +': ' + err.getMessage() + '\n';
                    }
                    else
                    {
                        errMessage += err.getMessage() + '\n';
                    }
                }

                Map<String, Object> fieldsToValue = recordsToBeUpdated[count].getPopulatedFieldsAsMap();
                String objectState = JSON.serialize(fieldsToValue);
                Lawg__e lg = new Lawg__e();
                lg.User_ID__c = UserInfo.getUserId();
                lg.Message_Text__c = String.isBlank(errMessage) ?'': errMessage.left(2000);
                //lg.Is_Debug__c=false;
                lg.Record_Id__c=result.getId();
                lg.Object_State__c=String.isBlank(objectState) ? '': objectState.left(2000);
                lg.Class__c=clsName.left(60);
                lg.Method__c=jobName.left(80);

                lgs.add(lg);

            }
            count += 1;
        }

        if(lgs.size()>0)
            EventBus.publish(lgs);
    }

    public static void saw(List<Error_Log__c> els, String clsName, String jobName)
    {
        if(els==null || els.size()==0) return;

        List<Lawg__e> lgs = new List<Lawg__e>();

        for(Error_Log__c el : els)
        {
            Lawg__e lg = new Lawg__e();
            lg.User_ID__c = UserInfo.getUserId();
            lg.Message_Text__c = String.isBlank(el.Error_Message__c) ?'': el.Error_Message__c.left(2000);
            lg.Object_State__c=String.isBlank(el.Object_State__c) ? '': el.Object_State__c.left(2000);
            lg.Record_Id__c=String.isBlank(el.RecordId__c) ? '': el.RecordId__c.left(18);
            lg.Method__c=String.isBlank(jobName) ? '': jobName.left(80);
            lg.Class__c=String.isBlank(clsName) ? '': clsName.left(60);
            lgs.add(lg);
        }


        if(lgs.size()>0)
            EventBus.publish(lgs);

    }

	private static SawedLawg__c sawLawg(Lawg__e l) 
    {
        SawedLawg__c sl = new SawedLawg__c();
        sl.Class__c=l.Class__c;
        sl.Line_Number__c = l.Line_Number__c;
        sl.Method__c = l.Method__c;
        sl.Stack_Trace_Text__c =l.Stack_Trace_Text__c;
        sl.User_ID_Text__c = l.User_ID__c;
        sl.Record_Id__c=l.Record_Id__c;
        sl.Object_State__c=l.Object_State__c;
        sl.Message_Text__c = l.Message_Text__c;
        return sl;
	}

    public static void saw(List<Lawg__e> lawgs)
    {
        List<SawedLawg__c> sawedLogs = new List<SawedLawg__c>();

        for(Lawg__e l : lawgs)
        {
            sawedLogs.add(sawLawg(l));
        }
        
        System.Debug(LoggingLevel.error, 'AGH_D inside saw');
        try
        {
            System.Debug(LoggingLevel.error, 'AGH_D inside fingerptin');
            sawedLogs = (List<SawedLawg__c>)fingerprint(sawedLogs);
        }
        catch(Exception exx)
        {
            System.Debug(LoggingLevel.error, 'AGH_D error while fingerprinting'+exx.getMessage()+'RCA:'+exx.getStackTraceString());
        }
        
        if(sawedLogs.size()>0)
            insert sawedLogs;
    }

    public static void saw(List<DMLResults.Result> res, String clsName)
    {
        if(res==null || res.size()==0) return;

        List<Lawg__e> lgs = new List<Lawg__e>();


        for(DMLResults.Result r : res)
        {
            Lawg__e lg = new Lawg__e();
            lg.User_ID__c = UserInfo.getUserId();
            lg.Message_Text__c = (r.errors!=null && r.errors.size()>0) ? String.join(r.errors, '\n').left(2000) : '';
            lg.Object_State__c=r.recordState.size()>0 ? r.getRecordStateJson().left(2000): '';
            lg.Record_Id__c = r.Id;
            lg.Class__c=clsName;
            lgs.add(lg);
        }


        EventBus.publish(lgs);
    }

    private static List<BeepRule> getBeepRules(String sobjectType)
    {
        List<BeepRule> bRules = new List<BeepRule>();
        for(Beep_Rule__c br: [select id ,
                C1_Field__c,
                C1_Operator__c,
                C1_Match__c,
                C2_Field__c,
                C2_Operator__c,
                C2_Match__c,
                C3_Field__c,
                C3_Operator__c,
                C3_Match__c,
                Is_Object_Default__c,
            Beep_Title__c,
            Fingerprint__c,
            Merge_Fields_in_Fingerprint__c,
            Hash_Fingerprint__c,
            SObjectType__c,
            Merge_Fields_in_Title__c
                from Beep_Rule__c 
                where SObjectType__c=:sobjectType 
                and IsDeleted=false
                and Is_Active__c=true
        order by Is_Object_Default__c ASC, Order__c DESC])
        {
            bRules.add(new BeepRule(br));
        }
        System.Debug(LoggingLevel.error, 'AGH_D beerules:'+bRules);

        return bRules;
    }


    public static List<SObject> fingerprint(List<SObject> logs)
    {
        // get all the beep rules for this sobjecttype
        List<Id> slIds = new List<id>();
        String sObjectType;

        for(SObject sl: logs)
        {
            if(String.isBlank(sObjectType))
            {
                sObjectType = sl.getSObjectType().getDescribe().getName();
            }
            if(sl.Id!=null)
            {
                slIds.add(sl.Id);
            }
        }

        System.Debug(LoggingLevel.Error, 'AGH_D fingerprinting object of type:'+sObjectType);

        Boolean fingerprintingAlreadyExistingLawg = (slIds.size()>0);

        Set<String> fprints = new Set<String>();

        List<BeepRule> bRules = getBeepRules(sObjectType);

        if(bRules.size()==0)
            return logs;
        System.Debug(LoggingLevel.Error, 'AGH_D bRules:'+bRules);

        Map<String, BeepRule> beepRulesMap = new Map<String, BeepRule>();

        for(SObject sl : logs)
        {
            for(BeepRule br : bRules)
            {
                if(br.conditionsMatched(sl))
                {
                    System.Debug(LoggingLevel.Error, 'AGH_D conditioins matched for:'+br);
                    String fp = br.generateFingerprint(sl);

                    sl.put('Fingerprint__c', fp);
                    sl.put('Beep_Rule__c', br.ruleId);
                    fprints.add(fp);
                    beepRulesMap.put(fp, br);
                    break;
                }
            }
        }

        List<Beep__c> existingBeeps = new List<Beep__c>();

        existingBeeps = searchFingerprints(fprints);
        Set<String> mutedFPs = new Set<String>();
        Map<String, Id> fpToBeepId = new Map<String, Id>();

        for(Beep__c bp: existingBeeps)
        {
            fpToBeepId.put(bp.Fingerprint__c, bp.Id);

            if(bp.Status__c=='MUTED')
                mutedFPs.add(bp.fingerprint__c);
        }

        List<Beep__c> beepsToBeInserted = new List<Beep__c>();
        Integer numOfLogs = logs.size();
        for ( Integer i = numOfLogs-1; i >= 0; i-- )
        {
            String fp = (String)logs[i].get('Fingerprint__c');

            if(logs[i].Id==null && mutedFPs.contains(fp))
            {
                logs.remove(i);
            }
            else
            {
                if(!String.isBlank(fp) && !fpToBeepId.containsKey(fp))
                {
                    //create beep
                    BeepRule myBr = beepRulesMap.get(fp);
                    Beep__c newBeep = new Beep__c(  Fingerprint__c=fp, 
                            Title__c=myBr.generateTitle(logs[i]), Log_Object_Type__c=myBr.objectType);
                    beepsToBeInserted.add(newBeep);
                    fpToBeepId.put(newBeep.Fingerprint__c, newBeep.Id);
                }
            }
        }

        if(beepsToBeInserted.size()>0)
        {
            insert beepsToBeInserted;
        }

        for(Beep__c bp : beepsToBeInserted)
        {
            fpToBeepId.put(bp.Fingerprint__c, bp.Id);
        }


        for(SObject sl : logs)
        {
            String fp = (String)sl.get('Fingerprint__c');
                    BeepRule myBr = beepRulesMap.get(fp);
            sl.put('Beep__c', fpToBeepId.get(fp));
            sl.put('Beep_Rule__c', myBr.ruleId);
        }

        if(fingerprintingAlreadyExistingLawg)
            update logs;

        return logs;

    }


    private static List<Beep__c> searchFingerprints(Set<String> fingerprintsToSearch)
    {
        List<Beep__c> bps = new List<Beep__c>();
        if(fingerprintsToSearch!=null && fingerprintsToSearch.size()>0)
        {
            for(Beep__c bp : [select Fingerprint__c ,
                    Status__c,
                    Id
                    from Beep__c 
                    where Fingerprint__c in :fingerprintsToSearch])
            {
                bps.add(bp);
            }
        }
        return bps;
    }

	public static void saw(Exception exx) 
    {
        Lawg__e lg = new Lawg__e();
        lg.User_ID__c = UserInfo.getUserId();
        lg.Message_Text__c = exx.getMessage()!=null ? exx.getMessage().left(2000): '';

        if(exx.getTypeName()=='DMLException')
        {
            lg.Record_Id__c = ((DMLException)exx).getDmlId(0);
        }

        lg.Stack_Trace_Text__c = exx.getStackTraceString()!=null ? exx.getStackTraceString().left(2000): '';
        lg=populateLocation(lg);

        EventBus.publish(lg);
    }


    // Begin SFDC-8568 - Harsh Pandey
    // Introduce Record Id when error logging to point out the exact record on which the error was logged.
    public static void saw(Exception exx, Id recId, String objState) 
    {
        Lawg__e lg = new Lawg__e();
        lg.User_ID__c = UserInfo.getUserId();
        lg.Message_Text__c = exx.getMessage()!=null ? exx.getMessage().left(2000): '';

        if(exx.getTypeName()=='DMLException')
        {
            lg.Record_Id__c = ((DMLException)exx).getDmlId(0);
        }
        else 
        {
            lg.Record_Id__c = recId;           
        }        
        if(String.isNotBlank(objState))
        {
            lg.Object_State__c = objState;
        }
        lg.Stack_Trace_Text__c = exx.getStackTraceString()!=null ? exx.getStackTraceString().left(2000): '';
        lg=populateLocation(lg);

        EventBus.publish(lg);
    }
    //End SFDC-8568 - Harsh Pandey


	// PRIVATE



	private static Lawg__e populateLocation(Lawg__e logEvent) 
    {
		// Note: Idea taken from https://salesforce.stackexchange.com/questions/153835
		List<String> stacktrace = new DmlException().getStackTraceString().split('\n');

        Integer stackDepth=1;
		for(String line : stacktrace) 
        {
			Matcher matcher = STACK_LINE.matcher(line);

            // find a class not equal to Sawyer, else keep Sawyer
            if(matcher.find() && !line.startsWith('Class.' + CLASSNAME + '.') || stackDepth==stacktrace.size()) 
            {
                logEvent.Class__c = matcher.group(1);
                logEvent.Method__c = prettyMethod(matcher.group(2));
                logEvent.Line_Number__c = Integer.valueOf(matcher.group(4));
                break;
            }
            stackDepth++;
		}
        return logEvent;
	}


	private static String prettyMethod(String method) 
    {
		String result = (method == null) ? 'anonymous' : method;
		return (result.contains('init')) ? 'constructor' : result;
	}

    public static void deleteLawgsForBeep(Id beepId)
    {
        List<SawedLawg__c> lawgs = [select id 
            from SawedLawg__c 
            where Beep__c=:beepId 
            limit 10000];

        if(lawgs!=null)
        {
            delete lawgs;
        }
    }

    public static void refingerprintChildren(Id beepId)
    {
        String sotype = getBeepObjectType(beepId);
        String query = new al.SoqlBuilder()
            .selectx(new List<String>(GSMSettings.getSetOfStrings('SawyerFields_'+sotype.replace('__c',''))))
            .fromx(sotype)
            .wherex(new al.AndCondition()
                    .add(new al.FieldCondition('IsDeleted').equals(false))
                    .add(new al.FieldCondition('Beep__c').equals(beepId)))
                    .orderByx(new al.OrderBy('CreatedDate').descending())
                    .limitx(5000)
                    .toSoql();

        List<SObject> lgs = Database.query(query);
        fingerprint(lgs);

    }

    public static String getBeepObjectType(Id beepId)
    {
        Beep__c thisBeep = [select Log_Object_Type__c 
            from Beep__c where id=:beepId];
        return (thisBeep.Log_Object_Type__c!=null)?thisBeep.Log_Object_Type__c:'SawedLawg__c';
    }
    public static void eraseFingerprints(Id beepId)
    {
        String sotype = getBeepObjectType(beepId);
        String query = new al.SoqlBuilder()
            .selectx(new List<String>{'Fingerprint__c', 'Beep__c', 'Beep_Rule__c'})
            .fromx(sotype)
            .wherex(new al.AndCondition()
                    .add(new al.FieldCondition('IsDeleted').equals(false))
                    .add(new al.FieldCondition('Beep__c').equals(beepId)))
                    .orderByx(new al.OrderBy('CreatedDate').descending())
                    .limitx(5000)
                    .toSoql();

        List<SObject> lgs = Database.query(query);
        for(SObject sl:lgs)
        {
            sl.put('Fingerprint__c', '');
            sl.put('Beep__c', null);
            sl.put('Beep_Rule__c', null);
        }

        if(lgs.size()>0)
            update lgs;
    }

    public static void summarizeBeeps(List<Beep__c> bps)
    {
        Set<Id> bpIds = new Set<id>();

        for(Beep__c bp: bps)
            bpIds.add(bp.Id);

        summarizeBeeps(bpIds);
    }

    public static void summarizeBeeps(Set<Id> beepIds)
    {
        List<Beep__c> bpsToUpdate = new List<Beep__c>();
        Map<Id, Integer> bpIdToCount = new Map<Id, Integer>();
        Map<Id, DateTime> bpIdToFirstOccurrence = new Map<Id, DateTime>();
        Map<Id, DateTime> bpIdToLatestOccurrence = new Map<Id, DateTime>();

        for(Id ithId : beepIds)
        {
            bpIdToCount.put(ithId, 0);
            bpIdToFirstOccurrence.put(ithId, null);
            bpIdToLatestOccurrence.put(ithId, null);
        }


        for(AggregateResult ar: [select beep__c, 
                count(id) cnt,
                max(createddate) latest,
                min(createddate) earliest 
                from sawedlawg__c 
                where Beep__c in :beepIds 
                and isdeleted=false group by beep__c])
        {
            Id bpId= (Id)ar.get('Beep__c');
            bpIdToCount.put(bpId, (Integer)ar.get('cnt'));
            bpIdToFirstOccurrence.put(bpId, (DateTime)ar.get('earliest'));
            bpIdToLatestOccurrence.put(bpId, (DateTime)ar.get('latest'));
        }


        for(AggregateResult ar: [select beep__c, 
                count(id) cnt,
                max(createddate) latest,
                min(createddate) earliest 
                from Callout_Log__c 
                where Beep__c in :beepIds 
                and isdeleted=false group by beep__c])
        {
            Id bpId= (Id)ar.get('Beep__c');
            bpIdToCount.put(bpId, (Integer)ar.get('cnt'));
            bpIdToFirstOccurrence.put(bpId, (DateTime)ar.get('earliest'));
            bpIdToLatestOccurrence.put(bpId, (DateTime)ar.get('latest'));
        }

        for(AggregateResult ar: [select beep__c, 
                count(id) cnt,
                max(LastModifiedDate) latest,
                min(LastModifiedDate) earliest 
                from Mulesoft_Polling__c
                where Beep__c in :beepIds 
                and isdeleted=false group by beep__c])
        {
            Id bpId= (Id)ar.get('Beep__c');
            bpIdToCount.put(bpId, (Integer)ar.get('cnt'));
            bpIdToFirstOccurrence.put(bpId, (DateTime)ar.get('earliest'));
            bpIdToLatestOccurrence.put(bpId, (DateTime)ar.get('latest'));
        }

        for(Id ithId : beepIds)
        {
            bpsToUpdate.add(
            new Beep__c(id=ithId, 
                Count__c=bpIdToCount.get(ithId), 
                First_Occurrence__c=bpIdToFirstOccurrence.get(ithId), 
                Latest_Occurrence__c=bpIdToLatestOccurrence.get(ithId)));
        }


        if(bpsToUpdate.size()>0)
            update bpsToUpdate;
    }

    public PageReference initButtons()
    {
        String fromButton   = ApexPages.currentPage().getParameters().get('fromButton');
        String recordId   = ApexPages.currentPage().getParameters().get('recordId');
        String sotype   = ApexPages.currentPage().getParameters().get('sotype');
        String objectPrefix;
        if(sotype=='Callout_Log__c')
            objectPrefix = Callout_Log__c.sObjectType.getdescribe().getKeyPrefix();
        else if(sotype=='SawedLawg__c')
            objectPrefix=SawedLawg__c.sObjectType.getdescribe().getKeyPrefix();
        else if(sotype=='Mulesoft_Polling__c')
            objectPrefix=Mulesoft_Polling__c.sObjectType.getdescribe().getKeyPrefix();

        try
        {
            switch  on fromButton
            {
                when 'FingerprintNew'
                {
                    String query = new al.SoqlBuilder()
                        .selectx(new List<String>(GSMSettings.getSetOfStrings('SawyerFields_'+sotype.replace('__c',''))))
                        .fromx(sotype)
                        .wherex(new al.AndCondition()
                                .add(new al.FieldCondition('IsDeleted').equals(false))
                                .add(new al.OrCondition()
                                    .add(new al.FieldCondition('Fingerprint__c').equals(null))
                                    .add(new al.FieldCondition('Beep__c').equals(null))))
                        .orderByx(new al.OrderBy('CreatedDate').descending())
                        .limitx(2000)
                        .toSoql();

                    List<sobject> recs = Database.query(query);
                    Sawyer.fingerprint(recs);
                    return new PageReference('/'+objectPrefix);
                }
                when 'FingerprintAll'
                {
                    String query = new al.SoqlBuilder()
                        .selectx(new List<String>(GSMSettings.getSetOfStrings('SawyerFields_'+sotype.replace('__c',''))))
                        .fromx(sotype)
                        .wherex(new al.FieldCondition('IsDeleted').equals(false))
                        .orderByx(new al.OrderBy('CreatedDate').descending())
                        .limitx(2000)
                        .toSoql();

                    List<sobject> recs = Database.query(query);
                    Sawyer.fingerprint(recs);
                    return new PageReference('/'+objectPrefix);
                }
                when 'ClearLawgs'
                {
                    deleteLawgsForBeep(recordId);
                    return new PageReference('/'+recordId);
                }
                when 'Fingerprint'
                {
                    String sObjectType = ((Id)recordId).getSObjectType().getDescribe().getName();
                    String query = new al.SoqlBuilder()
                .selectx(new List<String>(GSMSettings.getSetOfStrings('SawyerFields_'+sObjectType.replace('__c',''))))
                        .fromx(sObjectType)
                        .wherex(new al.FieldCondition('Id').equals(recordId))
                        .toSoql();

                    List<sObject> sobjs = Database.query(query);

                    if(sobjs.size()>0)
                        fingerprint(sobjs);

                    return new PageReference('/'+recordId);
                }
                when 'EraseFingerprints'
                {
                    eraseFingerprints(recordId);
                    return new PageReference('/'+recordId);
                }
                when 'SummarizeBeep'
                {
                    summarizeBeeps(new Set<Id>{recordId});
                    return new PageReference('/'+recordId);
                }
                when 'Refingerprint'
                {
                    refingerprintChildren(recordId);
                    return new PageReference('/'+recordId);
                }
                when else
                {
                    throw new CustomException('You cannot come to this page without being redirected to it from a button');
                }

            }
        }
        catch(Exception exx)
        {
            ApexPages.addMessage(
            new ApexPages.Message(ApexPages.Severity.ERROR, 
            'Something went wrong:'+exx.getMessage()+' with Trace: '+exx.getStackTraceString()));    
            Sawyer.saw(exx);
        }

        return null;
    }

    public class BeepCondition 
    {
        public String fld {get;set;}
        public String op 	{get;set;}
        public Set<String> matchesToCompare {get;set;}

        public BeepCondition(String fldAPIName, String operatorStr, String commaSeparatedMatches)
        {
            this.fld=fldAPIName;
            this.op=operatorStr;
            this.matchesToCompare=new set<String>();

            if(commaSeparatedMatches!=null)
            {
                for(String s1 : commaSeparatedMatches.split(','))
                {
                    matchesToCompare.add(s1.trim());
                }
            }

        }

        public boolean conditionsMatched(Sobject rec)
        {
            System.Debug(LoggingLevel.Error, 'AGH_D conditionsMatched'+fld+ ' for'+rec);
            Object fldValue = rec.get(fld);
            System.Debug(LoggingLevel.Error, 'AGH_D getting field value'+fldValue);

            if(fldValue==null)
                return false;

            switch on op
            {
                when 'BooleanTrue'
                {
                    return Boolean.valueOf(fldValue);
                }
                when 'BooleanFalse'
                {
                    return !Boolean.valueOf(fldValue);
                }
                when 'IsNull'
                {
                    return String.isBlank(String.valueOf(fldValue));
                }
                when 'IsNotNull'
                {
                    return !String.isBlank(String.valueOf(fldValue));

                }
                when 'TextEquals', 'TextContains', 'TextStartsWith'
                {
                    Boolean matched=false;
                    String fldValueString = String.valueOf(fldValue);
                    System.Debug(LoggingLevel.Error, 'AGH_D TextEquals'+fldValueString+' with'+matchesToCompare);
                    for(String s : matchesToCompare)
                    {
                        if((op=='TextEquals' && fldValueString.equals(s)) 
                        || (op=='TextContains' && fldValueString.contains(s)) 
                        || (op=='TextStartsWith' && fldValueString.startsWith(s)))
                        {
                            matched=true;
                            break;
                        }
                    }
                    return matched;
                }
                when 'DateTimeGreaterThan', 'DateTimeLesserThan'
                {
                    Datetime fldDateTime = Datetime.valueOf(fldValue);
                    DateTime toCompare = DateTime.valueOf(matchesToCompare.iterator().next());
                    System.Debug(LoggingLevel.Error, 'AGH_D Dateimte'+fldDateTime+' with'+toCompare);
                    return (op=='DateTimeLesserThan')?(fldDateTime < toCompare):(fldDateTime > toCompare);
                }
                when 'DateTimeGreaterThanLastNHours', 'DateTimeLessThanLastNHours'
                {
                    Datetime fldDateTime = Datetime.valueOf(fldValue);
                    Integer hoursToBeSubtracted = Integer.valueOf(matchesToCompare.iterator().next());
                    DateTime toCompare = DateTime.now().addHours(-1*hoursToBeSubtracted);
                    System.Debug(LoggingLevel.Error, 'AGH_D comparing DateTimeGreaterThanLastNHours'+toCompare+' and'+fldDateTime);
                    return op=='DateTimeGreaterThanLastNHours'?(toCompare <= fldDateTime):(toCompare > fldDateTime);
                }
                when else
                {
                    return false;
                }
            }
        }

    }

    public class BeepRule
    {
        private String ruleId {get;set;}
        private List<BeepCondition> conditions {get;set;}
        private string fingerprint {get;set;}
        private string beepTitle {get;set;}
        private string mergeFieldsInTitle {get;set;}
        private string mergeFieldsInFingerprint {get;set;}
        private boolean isObjectDefaultRule{get;set;}
        private boolean hashFingerprint {get;set;}
        private string objectType {get;set;}

        public BeepRule(Beep_Rule__c br)
        {
            this.ruleId = br.id;
            this.fingerprint = br.Fingerprint__c;
            this.objectType=br.SObjectType__c;
            this.hashFingerprint = br.Hash_Fingerprint__c;
            this.beepTitle = br.Beep_Title__c;
            this.isObjectDefaultRule = br.Is_Object_Default__c;
            if(!this.isObjectDefaultRule)
            {
                this.conditions = new List<BeepCondition>();

                if(br.C1_Operator__c!=null)
                    this.conditions.add(new BeepCondition(br.C1_Field__c, br.C1_Operator__c, br.C1_Match__c));

                if(br.C2_Operator__c!=null)
                    this.conditions.add(new BeepCondition(br.C2_Field__c, br.C2_Operator__c, br.C2_Match__c));

                if(br.C3_Operator__c!=null)
                    this.conditions.add(new BeepCondition(br.C3_Field__c, br.C3_Operator__c, br.C3_Match__c));

            }


            this.mergeFieldsInFingerprint = br.Merge_Fields_in_Fingerprint__c;
            this.mergeFieldsInTitle=br.Merge_Fields_in_Title__c;
        }


        public boolean conditionsMatched(SObject rec)
        {
            if(this.isObjectDefaultRule)
                return true;

            for(BeepCondition bc : conditions)
            {
                if(!bc.conditionsMatched(rec))
                {
                    return false;
                }
            }
            return true;
        }

        public string generateFingerprint(Sobject rec)
        {
            String fprintToHash = (this.mergeFieldsInFingerprint!=null) ?
                replaceMergeFields(this.fingerprint, this.mergeFieldsInFingerprint, rec)
                :this.fingerprint;

            if(this.hashFingerprint)
                return sha1(fprintToHash);
            else
                return fprintToHash.left(80);
        }

        private string sha1(String ss)
        {
            return EncodingUtil.convertToHex(Crypto.generateDigest('SHA1',Blob.valueOf(ss)));
        }


        private string replaceMergeFields(string strToReplace, String mFields, Sobject rec)
        {
            List<String> mFieldsList = mFields.split(',');
            for(String mField: mFieldsList)
            {
                String fldVlue = (String)rec.get(mField);
                if(fldVlue!=null)
                {
                    strToReplace= strToReplace.replaceAll(mField, (String)rec.get(mField));
                }
            }
            return strToReplace;
        }

        private string generateTitle(Sobject rec)
        {
            if(this.mergeFieldsInTitle!=null)
                return replaceMergeFields(this.beeptitle, this.mergeFieldsInTitle, rec).left(80);
            else
                return this.beeptitle.left(80);

        }

    }


}