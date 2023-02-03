public without sharing class ApprovalsUtilClass
{
    public static Map<Id,List<String>> unlockRecord(List<Id> recordIds)
    {
        Approval.UnlockResult[] lrList = Approval.unlock(recordIds, false);
        Set<Id> succeededIds = new Set<Id>();

        // Iterate through each returned result
        Map<Id, List<String>> resultMap = new Map<Id, List<String>>();
        for(Approval.UnlockResult lr : lrList) 
        {
            if (!lr.isSuccess()) 
            {
                resultMap.put(lr.getId(), new List<String>());
                for(Database.Error err : lr.getErrors()) 
                {
                    resultMap.get(lr.getId()).add(lr.getId()+':'+err.getFields() + ': ' + err.getMessage());
                }
            }
            else
            {
                succeededIds.add(lr.getId());
            }
        }
        System.debug('Error maps :'+resultMap);
        System.debug('Success ids : '+succeededIds);

        List<Approval.ProcessWorkitemRequest> pwrList = new List<Approval.ProcessWorkitemRequest>();
        for(ProcessInstanceWorkitem workItem :[ SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId in :succeededIds
            AND ProcessInstance.Status in ('Pending') ])
        {
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
            pwr.setAction('Removed');
            pwr.setWorkItemId(workItem.id);
            pwrList.add(pwr);
        }

        List<Approval.ProcessResult> recallResults = Approval.process(pwrList,false);
        List<Id> recallsDeniedDueToInsufficientAccessList = new List<Id>();

        for(Approval.ProcessResult apr: recallResults)
        {
            if(!apr.isSuccess())
            {
                System.debug('apr :'+apr);
                System.debug('Process instance id :'+apr.getInstanceId() + '  ::::::  '+apr.getEntityId());
                List<String> recallRequestErrors=new List<String>();
                for(Database.Error err : apr.getErrors()) 
                {
                    System.debug('err here :'+err.getMessage());
                    recallRequestErrors.add(apr.getEntityId()+':'+err.getFields()+':'+err.getMessage());
                }
                if(!resultMap.containsKey(apr.getEntityId()))
                {
                    resultMap.put(apr.getEntityId(), new List<String>());
                }
                resultMap.get(apr.getEntityId()).addAll(recallRequestErrors);
            }
        }
        System.debug('resultMap :'+resultMap);
        return resultMap;
    }

    public static List<String> unlockRecord(Id recId)
    {
        List<String> returnList;
        Map<Id, List<String>> idToErrors = unlockRecord(new List<Id>{recId});
        System.debug('idToErrors :'+idToErrors);
        //check if the profile is partner
        if (!idToErrors.isEmpty() && idToErrors.values()[0] != null && idToErrors.values()[0][0].contains('insufficient access rights on cross-reference id')) {
            System.debug('Calling RecordApprovalRecallHandler');
            RecordApprovalRecallHandler.mApprovalRecallAction(recId);
        }

        if(!idToErrors.isEmpty()) //if(idToErrors.size()==0)
            returnList = idToErrors.get(recId); //return null; //SDFC 7223
        
        return returnList;
    }

    public static Map<Id, List<String>> submitForApproval(List<Id> recordIds)
    {
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest> ();

        for (Id recordId: recordIds)
        {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitting request for approval ');
            req.setObjectId(recordId);
            requests.add(req);
        }

        Approval.ProcessResult[] processResults = Approval.process(requests, false);
        Integer indx = 0;
        Map<Id, List<String>> idToErrors = new Map<Id, List<String>>();
        for (Approval.ProcessResult result : processResults)
        {
            Id recId = recordIds[indx];
            if (!result.isSuccess())
            {
                for ( Database.error strError : result.getErrors() )
                {
                    if(!idToErrors.containsKey(recId))
                    {
                        idToErrors.put(recId, new List<String>{strError.getMessage()});
                    }
                    else
                    {
                        idToErrors.get(recId).add(strError.getMessage());
                    }

                }

            }
            indx++;
        }

        return idToErrors;
    }

    public static List<String> submitForApproval(Id recId)
    {
        //List<String> emptyList = new List<String>();
        List<String> returnList;
        Map<Id, List<String>> idToErrors = submitForApproval(new List<Id>{recId});

        if(idToErrors.size() >0)
             returnList = idToErrors.get(recId); //return null; //SDFC 7223
        
        return returnList;
    }

}