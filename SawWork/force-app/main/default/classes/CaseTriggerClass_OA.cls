/*=====================================================================================================+
Class name          :   CaseTriggerClass_OA
Test Class          :   CaseTriggerClass_OATest
Author              :   Vadhana
Created             :   06-Feb-19
Purpose             :   Case Trigger Class implementation for Order Management

Last Modified   Developer   Purpose            
=============   =========   ============ 
23 Mar 2022     Harshil     ESESP-6846: Adding logic to include CMG users for OA - Deal Desk
+=====================================================================================================*/
public class CaseTriggerClass_OA 
{
    public static boolean oaRecursiveCheckEdit = false;
    public static boolean oaRecursiveCheck = false;
    public static boolean oaRecursiveCheckSendEmail = false;
    public static boolean oaRecursiveCustSegUpdate = false;
    public static boolean recursiveCheckCloseCase = False;
    public static boolean skipCloseCaseEmailLogic = False;
    public static List<String> closedCaseStatusList = new List<String>{'Closed-Approved','Closed-Auto Approved','Closed-Approval Not Needed','Closed','Data Migration - Auto Close','Closed-Insufficient Information','Closed-Quote Term Updated','Closed-Quote Approved'};
        
        public static void validateOACase(List<Case> lOACase,Map<Id,String> mRecordType,Boolean isInsert,
                                          Map<Id,Case> oldMap,Map<Id,Case> newMap,Map<String,String> mErrorMssgRec)
    {
        if(!oaRecursiveCheck)
        {
            List<Case> lParentCases = new List<Case>();
            List<Case> lOACases = new List<Case>();
            List<Case> lOACasesForSmallDeal = new List<Case>();    
            
            List<Id> lOAIds = new List<Id>();
            List<Id> lOACaseId = new List<Id>();
            Map<Id,Set<String>> mOAIdRecType = new Map<Id,Set<String>>();
            Map<Id,Set<String>> mOAIdCaseSet = new Map<Id, Set<String>>();
            List<Id> parentCaseIdList = new List<Id>();
            
            Set<String> sOAEscalationRTs = new Set<String>{'Order Approval-Legal','Order Approval-Deal Desk'};
                Set<String> sOAMultipleRTs = new Set<String>{'Order Approval-Legal','Order Approval-Deal Desk','Order Approval-Sales Manager','Order Approval-Order Management'};
                    
                    Map<Id, String> mParentCaseRT = new Map<Id, String>();  
            Map<String,String> parentCaseIdADNameMap = new Map<String,String>();
            
            for(Case varCase : lOACase)
            {
                lOACaseId.add(varCase.ParentId);
                if(String.isNotBlank(varCase.Order_Approval__c))
                {
                    lOACasesForSmallDeal.add(varCase);
                    lOAIds.add(varCase.Order_Approval__c);
                    if(!mOAIdCaseSet.containsKey(varCase.Order_Approval__c))
                    {
                        mOAIdCaseSet.put(varCase.Order_Approval__c,new Set<String>());
                    }
                    mOAIdCaseSet.get(varCase.Order_Approval__c).add(varCase.Id);
                }
            }
            
            String caseQuery = 'SELECT Id, RecordType.Name,Order_Approval__c FROM Case WHERE ';
            if(!lOACaseId.isEmpty() && !lOAIds.isEmpty())
                caseQuery += 'Id IN :lOACaseId OR Order_Approval__c IN :lOAIds';
            else
                if(!lOACaseId.isEmpty())
                caseQuery += 'Id IN :lOACaseId';
            else
                if(!lOAIds.isEmpty())
                caseQuery += 'Order_Approval__c IN :lOAIds';
            
            if(!lOACaseId.isEmpty() || !lOAIds.isEmpty())
            {
                for(Case varCase : Database.query(caseQuery))
                {
                    if(lOACaseId.contains(varCase.Id))
                    {
                        mParentCaseRT.put(varCase.Id, varCase.RecordType.Name);
                    }
                    
                    if(lOAIds.contains(varCase.Order_Approval__c))
                    {
                        if(!mOAIdRecType.containsKey(varCase.Order_Approval__c))
                        {
                            mOAIdRecType.put(varCase.Order_Approval__c,new Set<String>());
                        }
                        mOAIdRecType.get(varCase.Order_Approval__c).add(varCase.RecordTypeId);
                    }   
                }
            }
            
            for(Case varCase : lOACase)
            {
                if(!sOAEscalationRTs.contains(mParentCaseRT.get(varCase.ParentId))
                   && String.isNotBlank(varCase.ParentId)
                   && mRecordType.get(varCase.RecordTypeId) == 'Order Approval-Escalations' 
                   && (isInsert || newMap.get(varCase.Id).ParentId != oldMap.get(varCase.Id).ParentId)
                  )
                {
                    varCase.addError(mErrorMssgRec.get('OA Escalation Case Validation'));
                }
                if(sOAMultipleRTs.contains(mRecordType.get(varCase.RecordTypeId))
                   && mOAIdRecType.containsKey(varCase.Order_Approval__c) 
                   && mOAIdRecType.get(varCase.Order_Approval__c).contains(varCase.RecordTypeId) 
                   && isInsert)
                {
                    varCase.addError(mRecordType.get(varCase.RecordTypeId) + ' ' + mErrorMssgRec.get('OA Multiple Case Validation'));
                }
                
            }
            
            //smallDealApproval(lOAIds, mRecordType, lOACasesForSmallDeal,mErrorMssgRec);
        }
        oaRecursiveCheck = true;
    }
    
    /*public static void smallDealApproval(List<Id> lOAIds, Map<Id,String> mRecordType,
    List<Case> lOACasesForSmallDeal, Map<String,String> mErrorMssgRec)
    {
    Set<String> sOARecsSmallDeal = new Set<String>();
    if(! lOAIds.isEmpty())
    {
    List<Order_Approval__c> lOAs = [SELECT Id, Ovverride_Small_Deal__c, Small_Deal__c 
    FROM Order_Approval__c 
    WHERE Id IN : lOAIds 
    AND Ovverride_Small_Deal__c = false 
    AND Small_Deal__c = true];
    for(Order_Approval__c varOA : lOAs){
    sOARecsSmallDeal.add(varOA.Id);
    }
    
    for(Case varCase : lOACasesForSmallDeal){
    System.debug(' ## varCase ' + varCase.Order_Approval__c + ' ## mRecordType.get(varCase.Id) ' + mRecordType.get(varCase.Id));
    if(varCase.AutoClose__c && sOARecsSmallDeal.contains(varCase.Order_Approval__c) 
    && mRecordType.get(varCase.RecordTypeId) == 'Order Approval-Deal Desk')
    {
    varCase.addError(mErrorMssgRec.get('OA Small Deal Validation')); 
    }
    }
    }
    }*/
    
    public static void closeOACaseAndPendingAD(List<Id> lOACloseCaseId,Map<Id,Case> newMap,List<Id> oaIDs)
    {
        List<Approval_Details__c> lAD = new List<Approval_Details__c>();
        List<Approval_Details__c> lADUpdate = new List<Approval_Details__c>();
        
        Map<Id,Order_Approval__c> closeOACaseOAClosedAll = new Map<Id,Order_Approval__c>();
        List<Order_Approval__c> oaCloseUpdate = new List<Order_Approval__c>();
        
        lAD = [SELECT Name, Approval_Status__c,Related_To__c,Validation_Override__c 
               FROM Approval_Details__c 
               WHERE Related_To__c IN :lOACloseCaseId 
               AND Approval_Status__c IN ('Pending','Escalated')
              ];
        if(!lAD.isEmpty())
        {
            for(Approval_Details__c eachAD : lAD)
            {
                if(newMap.get(eachAD.Related_To__c).Status == 'Closed-Insufficient Information'){
                    eachAD.Approval_Status__c = 'Closed Without Approval';
                    eachAD.Validation_Override__c = true;
                    lADUpdate.add(eachAD);
                } 
                else if(newMap.get(eachAD.Related_To__c).AutoClose__c)
                {
                    eachAD.Approval_Status__c = 'Auto-Closed Without Approval';
                    eachAD.Validation_Override__c = true;
                    lADUpdate.add(eachAD);
                }
            }
            if(lADUpdate.size() > 0)
                update lADUpdate;
        }
        
        closeOACaseOAClosedAll = new Map<Id,Order_Approval__c>([SELECT Id,Validation_Override__c,CCG_Status__c ,
                                                                (SELECT Id,Status 
                                                                 FROM Cases__r 
                                                                 WHERE Status not in:(closedCaseStatusList)
                                                                 
                                                                 AND RecordType.Name IN ('Order Approval-Deal Desk','Order Approval-Legal',
                                                                                         'Order Approval-Order Management','Order Approval-Escalations',
                                                                                         'Order Approval-Others','Order Approval-Sales Manager'
                                                                                        ))
                                                                FROM Order_Approval__c
                                                                WHERE CCG_Status__c = 'In Progress' 
                                                                AND Associated_Opportunity__r.StageName LIKE 'Closed%'
                                                                AND ID in :oaIDs
                                                               ]);
        if(!closeOACaseOAClosedAll.isEmpty())
        {
            for(Order_Approval__c eachOA : closeOACaseOAClosedAll.values())
            {
                if(eachOA.Cases__r.isEmpty())
                {
                    eachOA.CCG_Status__c = 'Closed';
                    eachOA.Validation_Override__c = TRUE;
                    oaCloseUpdate.add(eachOA);
                }
            }
            if(!oaCloseUpdate.isEmpty())
                update oaCloseUpdate;
        }
    }
    public static void populateOAApproverChange(List<Case> lOACase,Map<Id,String> mRecordType,
                                                Map<Id,Case> oldMap,Map<String,String> mErrorMssgRec)
    {
        for(Case eachCase : lOACase) {
            if(mRecordType.get(eachCase.RecordTypeId) == 'Order Approval-Sales Manager'
               || mRecordType.get(eachCase.RecordTypeId) == 'Order Approval-Others'
               || mRecordType.get(eachCase.RecordTypeId) == 'Order Approval-Escalations')
            {
                eachCase.OwnerId = eachCase.Approver__c;
            }
        }                                            
    }
    public static void validateOACaseOwnerChange(List<Id> lstCaseOwnerId, List<Case> lstCaseOA, Map<Id,String> mRecordType,Map<String,String> mErrorMssgRec)
    {
        Map<Id,User> mpUser = new Map<Id,User>([SELECT Id,Name,Profile.Name
                                                FROM User
                                                WHERE Id IN :lstCaseOwnerId or Id=:userinfo.getUserId()]);
        
        //ESESP-6846: Checking if User has OA_Deal_Desk permission set
        Boolean hasDDPermissionSet = FeatureManagement.checkPermission('OA_Deal_Desk');
        
        for(Case eachCase : lstCaseOA)
        {
            eachCase.Approver__c = eachCase.OwnerId;
            if(mRecordType.get(eachCase.RecordTypeId) == 'Order Approval-Legal')
            {
                if(mpUser.get(userinfo.getUserId()).Profile.Name != 'Legal' && !(mpUser.get(userinfo.getUserId()).Profile.Name).contains('Sales') 
                   && mpUser.get(userinfo.getUserId()).Profile.Name != 'System Administrator' && mpUser.get(userinfo.getUserId()).Profile.Name != 'SA - Manager' 
                   && mpUser.get(userinfo.getUserId()).Profile.Name != 'SA - Analyst'&& mErrorMssgRec.get('OA Only Legal') != NULL){
                       eachCase.addError(mErrorMssgRec.get('OA Only Legal'));
                }
                else if(mpUser.get(eachCase.OwnerId).Profile.Name != 'Legal' 
                        && mErrorMssgRec.get('OA Legal Owner') != NULL)
                {
                    eachCase.addError(mErrorMssgRec.get('OA Legal Owner'));
                }
            }
            
            if(mRecordType.get(eachCase.RecordTypeId) == 'Order Approval-Deal Desk')
            {
                //ESESP-6846: Added condition to check permission set
                if(mpUser.get(userinfo.getUserId()).Profile.Name != 'Deal Desk' && !(mpUser.get(userinfo.getUserId()).Profile.Name).contains('Sales') 
                   && mpUser.get(userinfo.getUserId()).Profile.Name != 'System Administrator' && mpUser.get(userinfo.getUserId()).Profile.Name != 'SA - Manager' 
                   && mpUser.get(userinfo.getUserId()).Profile.Name != 'SA - Analyst' && mErrorMssgRec.get('OA Only DD') != NULL
                   && !hasDDPermissionSet){
                    eachCase.addError(mErrorMssgRec.get('OA Only DD'));
                }
                //ESESP-6846: Added condition to check permission set
                else if(mpUser.get(eachCase.OwnerId).Profile.Name != 'Deal Desk' 
                        && mErrorMssgRec.get('OA DD Owner') != NULL &&
                        [Select Id from PermissionSetAssignment where PermissionSet.Name = 'OA_Deal_Desk' and AssigneeId  = :eachCase.OwnerId].size() == 0)
                {
                    eachCase.addError(mErrorMssgRec.get('OA DD Owner'));
                }
            }
            
            if(mRecordType.get(eachCase.RecordTypeId) == 'Order Approval-Order Management')
            {
                if(mpUser.get(userinfo.getUserId()).Profile.Name != 'SA - Analyst' && mpUser.get(userinfo.getUserId()).Profile.Name != 'SA - Manager' 
                   && !(mpUser.get(userinfo.getUserId()).Profile.Name).contains('Sales') && mpUser.get(userinfo.getUserId()).Profile.Name != 'System Administrator' && mErrorMssgRec.get('OA Only OM') != NULL){
                       eachCase.addError(mErrorMssgRec.get('OA Only OM'));
                   }
                else if(mpUser.get(eachCase.OwnerId).Profile.Name != 'SA - Analyst' && mpUser.get(eachCase.OwnerId).Profile.Name != 'SA - Manager'
                        && mErrorMssgRec.get('OA OM Owner') != NULL)
                {
                    eachCase.addError(mErrorMssgRec.get('OA OM Owner'));
                }
            }
        }
    }
    
    public static void validateCloseCase(List<Id> lOACloseCaseId,Map<String,String> mErrorMssgRec,Map<Id,Case> newMap,List<Id> lOACloseCaseOppId,Map<Id,String> mRecordType, Boolean escalateAD)
    {
        Map<Id,List<Approval_Details__c>> caseADMap = new Map<Id,List<Approval_Details__c>>();
        
        for(Approval_Details__c thisAD : [SELECT Name, Approval_Status__c,Related_To__c,Related_To__r.RecordTypeId 
                                          FROM Approval_Details__c 
                                          WHERE Related_To__c IN :lOACloseCaseId 
                                          AND (Approval_Status__c IN ('Pending','Escalated') OR Approval_Status__c LIKE 'Approved%')
                                         ])
        {
            if(caseADMap.containsKey(thisAD.Related_To__c) && caseADMap.get(thisAD.Related_To__c) != null){
                List<Approval_Details__c> lAD = new List<Approval_Details__c>();
                lAD.add(thisAD);
                lAD.addAll(caseADMap.get(thisAD.Related_To__c));
                caseADMap.put(thisAD.Related_To__c,lAD);
            }
            
            else{
                caseADMap.put(thisAD.Related_To__c,new List<Approval_Details__c>{thisAD});
            }
                
        }
        
        List<Approval_Details__c> lADUpdate = new List<Approval_Details__c>();
        List<Approval_Details__c> clonedADList = new List<Approval_Details__c>();
        //Id omRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
        
        List<Order_Approval__c> lOAUpdate = new List<Order_Approval__c>();
        Map<Id,Order_Approval__c> mOA = new Map<Id,Order_Approval__c>();
        for(Id eachCaseId: newMap.keySet()){
            system.debug('caseADMap : '+caseADMap);
            if(caseADMap.get(eachCaseId) != null){
                for(Approval_Details__c eachAD: caseADMap.get(eachCaseId))
                {
                    //REQ:4.3.2
                    //if((newMap.get(eachAD.Related_To__c).AutoClose__c) && (mRecordType.get(newMap.get(eachAD.Related_To__c).RecordTypeId) == 'Order Approval-Others' || 
                    //mRecordType.get(newMap.get(eachAD.Related_To__c).RecordTypeId) == 'Order Approval-Escalations' || 
                    //mRecordType.get(newMap.get(eachAD.Related_To__c).RecordTypeId) == 'Order Approval-Sales Manager')){
                    if(newMap.get(eachAD.Related_To__c).AutoClose__c && eachAD.Approval_Status__c != 'Pending')
                    {
                        newMap.get(eachAD.Related_To__c).Status = 'Closed-Approval Not Needed';
                    }
                    //}
                    //REQ:4.3.2
                    if(newMap.get(eachAD.Related_To__c).AutoClose__c && !closedCaseStatusList.contains(newMap.get(eachAD.Related_To__c).Status)){
                        if(eachAD.Approval_Status__c == 'Escalated' || eachAD.Approval_Status__c == 'Pending')
                        {
                            newMap.get(eachAD.Related_To__c).Status = 'Closed-Approval Not Needed';
                        }
                    }
                    if(!escalateAD && !newMap.get(eachAD.Related_To__c).AutoClose__c 
                       && closedCaseStatusList.contains(newMap.get(eachAD.Related_To__c).Status) && !newMap.get(eachAD.Related_To__c).Validation_Override__c)
                    {
                        //REQ:
                        if(eachAD.Approval_Status__c == 'Escalated' || eachAD.Approval_Status__c == 'Pending')
                        {
                            if(String.isNotBlank(mErrorMssgRec.get('OA Case Closure Validation')))
                                newMap.get(eachAD.Related_To__c).addError(mErrorMssgRec.get('OA Case Closure Validation'));
                        }
                        //REQ:4.3.3 and 4.3.4
                        if(eachAD.Approval_Status__c.containsIgnoreCase('Approved') && !newMap.get(eachAD.Related_To__c).AutoClose__c && !newMap.get(eachAD.Related_To__c).Validation_Override__c)
                        {
                            system.debug('************ : '+mRecordType.get(newMap.get(eachAD.Related_To__c).RecordTypeId));
                            if(mRecordType.get(newMap.get(eachAD.Related_To__c).RecordTypeId) == 'Order Approval-Order Management'
                               && (String.isBlank(newMap.get(eachAD.Related_To__c).Manually_Edited__c) 
                                   || String.isBlank(newMap.get(eachAD.Related_To__c).Order_Type__c) 
                                   || String.isBlank(newMap.get(eachAD.Related_To__c).Paper_Source__c) 
                                   || newMap.get(eachAD.Related_To__c).Valid_Until_Date__c == NULL
                                   || String.isBlank(newMap.get(eachAD.Related_To__c).Final_Approval_Notes__c)
                                  ))
                            {
                                if(String.isNotBlank(mErrorMssgRec.get('OA OM Case Close Validation')))
                                    newMap.get(eachAD.Related_To__c).addError(mErrorMssgRec.get('OA OM Case Close Validation'));
                                
                            }
                            
                            if(mRecordType.get(newMap.get(eachAD.Related_To__c).RecordTypeId) == 'Order Approval-Legal'
                               && !newMap.get(eachAD.Related_To__c).Validation_Override__c
                               && (String.isBlank(newMap.get(eachAD.Related_To__c).Final_Approval_Notes__c)
                                   || String.isBlank(newMap.get(eachAD.Related_To__c).Legal__c) 
                                   || String.isBlank(newMap.get(eachAD.Related_To__c).Complexity__c))
                              )
                            {
                                if(String.isNotBlank(mErrorMssgRec.get('OA Legal Case Close Validation')))
                                    newMap.get(eachAD.Related_To__c).addError(mErrorMssgRec.get('OA Legal Case Close Validation'));
                            }
                            
                            if(mRecordType.get(newMap.get(eachAD.Related_To__c).RecordTypeId) == 'Order Approval-Deal Desk'
                               && !newMap.get(eachAD.Related_To__c).Validation_Override__c
                               && String.isBlank(newMap.get(eachAD.Related_To__c).Final_Approval_Notes__c))
                            {
                                if(String.isNotBlank(mErrorMssgRec.get('OA DD Case Close Validation')))
                                    newMap.get(eachAD.Related_To__c).addError(mErrorMssgRec.get('OA DD Case Close Validation'));
                            }
                            
                            if(mRecordType.get(newMap.get(eachAD.Related_To__c).RecordTypeId) == 'Order Approval-Sales Manager'
                               && !newMap.get(eachAD.Related_To__c).Validation_Override__c
                               && String.isBlank(newMap.get(eachAD.Related_To__c).Final_Approval_Notes__c))
                            {
                                if(String.isNotBlank(mErrorMssgRec.get('OA SM Case Close Validation')))
                                    newMap.get(eachAD.Related_To__c).addError(mErrorMssgRec.get('OA SM Case Close Validation'));
                            }
                        }
                    }
                } 
            }
            else{
                if(newMap.get(eachCaseId).AutoClose__c)
                    newMap.get(eachCaseId).Status = 'Closed-Approval Not Needed';
            }
        }
        
        if(!lOACloseCaseOppId.isEmpty())
        {
            Map<Id,Opportunity> mOpp = new Map<Id,Opportunity>([SELECT Id,Is_Restricted_Country__c, Commercial_Segmentation__c,
                                                                Deal_Type__c,Partner_Involved__r.Rev_Aligned__c,Zero_MRR_Amount__c,Account.BillingCountry
                                                                FROM Opportunity
                                                                WHERE Id IN : lOACloseCaseOppId]);
            
            
            for(Id varCaseId : lOACloseCaseId)
            {
                if(mOpp.keySet().size() > 0)
                {
                    if(!newMap.get(varCaseId).IALT_Received__c && mOpp.get(newMap.get(varCaseId).Opportunity__c).Is_Restricted_Country__c
                       && !newMap.get(varCaseId).Validation_Override__c && mRecordType.get(newMap.get(varCaseId).RecordTypeId) == 'Order Approval-Order Management'
                       && !newMap.get(varCaseId).AutoClose__c
                      )
                    {
                        newMap.get(varCaseId).addError(mErrorMssgRec.get('OA Restricted Country OM Validation'));
                    }
                    
                    // validation check for Swiss Approval
                    if(!newMap.get(varCaseId).Validation_Override__c 
                       && mRecordType.get(newMap.get(varCaseId).RecordTypeId) == 'Order Approval-Order Management'
                       && !newMap.get(varCaseId).AutoClose__c && !newMap.get(varCaseId).Swiss_Approval_Required__c
                       && mOpp.get(newMap.get(varCaseId).Opportunity__c).Deal_Type__c == 'Indirect' 
                       && mOpp.get(newMap.get(varCaseId).Opportunity__c).Partner_Involved__r.Rev_Aligned__c
                       
                       && mOpp.get(newMap.get(varCaseId).Opportunity__c).Zero_MRR_Amount__c != 'Trial/ POC'
                       && 
                       (mOpp.get(newMap.get(varCaseId).Opportunity__c).Account.BillingCountry.containsIgnoreCase('USA')
                        || mOpp.get(newMap.get(varCaseId).Opportunity__c).Account.BillingCountry.containsIgnoreCase('Canada')
                        || mOpp.get(newMap.get(varCaseId).Opportunity__c).Account.BillingCountry.containsIgnoreCase('TBD'))
                      )
                    {
                        newMap.get(varCaseId).addError(mErrorMssgRec.get('OM Swiss Approval Reqd'));
                    }
                    
                }
            }
        }
    }
    
    public static void reopenOACase(List<Id> reopenCaseId,List<Id> lOAId, Map<Id,Case> newMap)
    {
        List<Order_Approval__c> lUpdateOAStatus = new List<Order_Approval__c>();
        List<Order_Approval__c> lOA = [SELECT Associated_Opportunity__c,Associated_Opportunity__r.StageName,CCG_Status__c,Validation_Override__c 
                                       FROM Order_Approval__c
                                       WHERE Id in : lOAId AND CCG_Status__c = 'Closed' 
                                       
                                      ];
        
        for(Order_Approval__c varOA : lOA)
        {
            varOA.CCG_Status__c = 'In Progress';
            varOA.Validation_Override__c = TRUE;
            lUpdateOAStatus.add(varOA);
        }
        update lUpdateOAStatus;
    }
    
    public static void populateOppOwnerOACase(List<Case> lOACaseOppOwner,List<Id> oppId,Map<String,String> mErrorMssgRec)
    {
        Map<Id,Opportunity> mOpp = new Map<Id,Opportunity>();
        List<Case> lCase = new List<Case>();
        mOpp = new Map<Id,Opportunity>([SELECT Owner.Email,OwnerId,StageName 
                                        FROM Opportunity 
                                        WHERE Id in :oppId]);
        for(Case eachCase : lOACaseOppOwner)
        {
            if(mOpp.keySet().size() > 0){
                if(mOpp.get(eachCase.Opportunity__c).StageName.containsIgnoreCase('Closed') && !eachCase.Validation_Override__c)
                    eachCase.addError(mErrorMssgRec.get('OA Closed Opportunity Validation'));
                if(eachCase.OwnerId != mOpp.get(eachCase.Opportunity__c).OwnerId)
                {
                    eachCase.AlternateContactEmailManagedSecurity__c = mOpp.get(eachCase.Opportunity__c).Owner.Email;
                }
            }
        }
    }
    
    public static void updateADOnEscalation(Map<Id,String> parentCaseIdADNameMap, Map<Id,Id> parentCaseIdMap)
    {
        List<Approval_Details__c> lAD = new List<Approval_Details__c>();
        List<Approval_Details__c> lADUpdate = new List<Approval_Details__c>();
        List<Approval_Details__c> clonedADList = new List<Approval_Details__c>();
        String query = '';
        
        lAD = [SELECT Name, Approval_Status__c,Related_To__c, Approval_Request__c 
               FROM Approval_Details__c 
               WHERE Related_To__c IN :parentCaseIdADNameMap.keySet() 
               AND Approval_Status__c IN ('Pending','Escalated')
              ];
        
        if(!lAD.isEmpty())
        {
            for(Approval_Details__c eachAD : lAD)
            {
                if(eachAD.Approval_Status__c == 'Pending' && String.isNotBlank(parentCaseIdADNameMap.get(eachAD.Related_To__c))
                   && parentCaseIdADNameMap.get(eachAD.Related_To__c) == eachAD.Name)
                {
                    eachAD.Approval_Status__c = 'Escalated';
                    lADUpdate.add(eachAD);
                    query = CaseTriggerClass_OA.getCreatableFieldsSOQL('Approval_Details__c', 'Name = '+'\''+parentCaseIdADNameMap.get(eachAD.Related_To__c)+'\'');
                }
            }
            if(!lADUpdate.isEmpty())
            {
                update lADUpdate;
            }
            
            if(String.isNotEmpty(query)){
                for(Approval_Details__c thisAD : Database.query(query)){
                    Approval_Details__c ADCopy = thisAD.clone(false, true);
                    ADCopy.Related_To__c = parentCaseIdMap.get(thisAD.Related_To__c);
                    ADCopy.Approval_Status__c = 'Pending';
                    ADCopy.RecordTypeId = Schema.SObjectType.Approval_Details__c.getRecordTypeInfosByName().get('Deal Desk Approval Details').getRecordTypeId();
                    clonedADList.add(ADCopy);
                }
                if(!clonedADList.isEmpty())
                {
                    insert clonedADList;
                }
            }
        }
    }
    
    public static void validateEscalationCase(List<Id> parentCaseIdList,List<Case> newMap,Map<String,String> mErrorMssgRec){
        List<Approval_Details__c> relatedADList = new List<Approval_Details__c>();
        List<Case> relatedEscalationCaseList = new List<Case>();
        Map<String,Id> parentCaseADNameMap = new Map<String,Id>();
        Map<String,String> parentCaseADStatusMap = new Map<String,String>();
        Map<String,Id> parentCaseADOwnerMap = new Map<String,Id>();
        Map<String,String> caseIdADIdMap = new Map<String,String>();
        
        relatedADList = [select id,name,Approval_Status__c,Related_To__c, Related_To__r.OwnerId from Approval_Details__c where Related_To__c in:(parentCaseIdList)];
        for(Approval_Details__c eachAD : relatedADList){
            parentCaseADNameMap.put(eachAD.name,eachAD.Related_To__c);
            parentCaseADStatusMap.put(eachAD.name,eachAD.Approval_Status__c);
            parentCaseADOwnerMap.put(eachAD.name,eachAD.Related_To__r.OwnerId);
        }
        
        relatedEscalationCaseList = [select id,AKAM_Case_ID__c, Approval_Detail_ID__c from Case where parentId in:(parentCaseIdList) and RecordType.Name = 'Order Approval-Escalations'];
        for(Case thisEscCase : relatedEscalationCaseList){
            caseIdADIdMap.put(thisEscCase.Approval_Detail_ID__c, thisEscCase.AKAM_Case_ID__c);
        }
        
        for(Case eachCase: newMap){
            for(String eachCaseADID : parentCaseADNameMap.keySet()){
                if(eachCase.Approval_Detail_ID__c == eachCaseADID){
                    if(caseIdADIdMap.keySet().contains(eachCase.Approval_Detail_ID__c) && caseIdADIdMap.get(eachCase.Approval_Detail_ID__c) != null)
                        eachCase.addError(mErrorMssgRec.get('OA Escalation Case Duplicate Validation').replace('{0}',caseIdADIdMap.get(eachCase.Approval_Detail_ID__c)));
                    //eachCase.addError('An Escalation Case '+caseIdADIdMap.get(eachCase.Approval_Detail_ID__c)+' already exists for this Approval Detail.');
                    
                    if(parentCaseADNameMap.get(eachCase.Approval_Detail_ID__c) == eachCase.ParentId 
                       && parentCaseADStatusMap.get(eachCase.Approval_Detail_ID__c) != 'Pending')
                        eachCase.addError(mErrorMssgRec.get('OA Escalation Case ADS Validation').replace('{0}',parentCaseADStatusMap.get(eachCase.Approval_Detail_ID__c)));
                    //eachCase.addError('An Escalation Case cannot be created for and Approval Detail of status '+parentCaseADStatusMap.get(eachCase.Approval_Detail_ID__c));
                    
                    if(parentCaseADNameMap.get(eachCase.Approval_Detail_ID__c) == eachCase.ParentId 
                       && parentCaseADOwnerMap.get(eachCase.Approval_Detail_ID__c) != UserInfo.getUserId())
                        eachCase.addError(mErrorMssgRec.get('OA Escalation Case PCO Validation'));
                }
            }
        }
    }
    
    // Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
    public static string getCreatableFieldsSOQL(String objectName, String whereClause){
        String selects = '';
        if (whereClause == null || whereClause == ''){ return null; }
        
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
        
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }
        
        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}
            
        }
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
    }
    
    public static void shareCaseWithOppTM(Map<Id,Id> caseOppIdMap, List<Case> newCaseList)
    {
        List<OpportunityTeamMember> oppTMList = new List<OpportunityTeamMember>();
        List<CaseShare> csShareList = new List<CaseShare>();
        oppTMList = [SELECT Id, OpportunityId, UserId, Name,User.isActive, Title, TeamMemberRole 
                     FROM OpportunityTeamMember 
                     WHERE OpportunityId IN:(caseOppIdMap.values())];
        
        for(Case thisCase : newCaseList)
        {            
            if(thisCase.Opportunity__c != null)
            {
                for(OpportunityTeamMember oppTM : oppTMList)
                {
                    if(oppTM.User.isActive && oppTM.UserId != UserInfo.getUserId())
                    {
                        if(caseOppIdMap.get(thisCase.id) == oppTM.OpportunityId)
                        {
                            CaseShare csShare = new CaseShare();
                            csShare.CaseAccessLevel = 'edit';
                            csShare.CaseId = thisCase.id;
                            csShare.RowCause = 'Manual';
                            csShare.UserOrGroupId = oppTM.UserId;
                            csShareList.add(csShare); 
                        }
                    }
                }
            }
        } 
        system.debug('csShareList : '+csShareList);
        if(csShareList.size() > 0)
        {
            try
            {
                Database.insert(csShareList,false);
            }
            catch(Exception e){}
        }
    } 
    
    public static void oaCaseShareWithOTM(Map<Id,OpportunityTeamMember> otmNewMap,Map<Id,Id> mapOppIDOTMId,Boolean addOrDelete)
    {
        if(addOrDelete)
        {
            List<CaseShare> lstCaseShare = new List<CaseShare>();
            
            Map<Id,Case> mpOACase = new Map<Id,Case>([SELECT Id,Opportunity__c,OwnerId
                                                      FROM Case
                                                      WHERE Opportunity__c in :mapOppIDOTMId.keySet() 
                                                      AND RecordType.Name like 'Order Approval-%']);
            
            for(Case eachCase : mpOACase.values())
            {
                if(mapOppIDOTMId.get(eachCase.Opportunity__c) != eachCase.OwnerId)
                {
                    CaseShare csShare = new CaseShare();
                    csShare.CaseAccessLevel = 'edit';
                    csShare.CaseId = eachCase.id;
                    csShare.RowCause = 'Manual';
                    csShare.UserOrGroupId = mapOppIDOTMId.get(eachCase.Opportunity__c);
                    lstCaseShare.add(csShare);
                }
            }
            
            if(lstCaseShare.size() > 0)
            {
                try
                {
                    Database.insert(lstCaseShare,false);
                }
                catch(Exception e){}
            }
        }
        else
        {
            List<CaseShare> lstCaseShareToDel = new List<CaseShare>();
            Map<Id,Case> mpOACase = new Map<Id,Case>([SELECT Id,Opportunity__c
                                                      FROM Case
                                                      WHERE Opportunity__c in :mapOppIDOTMId.keySet() AND RecordType.Name like 'Order Approval-%']);
            if(mpOACase.size() >0){
                lstCaseShareToDel = new List<CaseShare>([SELECT Id,CaseId,UserOrGroupId
                                                                     FROM CaseShare
                                                                     WHERE UserOrGroupId in :mapOppIDOTMId.values() 
                                                                     	AND CaseId in: mpOACase.keySet() and RowCause = 'Manual']);
            }
            if(!lstCaseShareToDel.isEmpty())
                delete lstCaseShareToDel;
        }
    } 
    
    //ESESP-2796
    public static void checkCustSegTreatmentFieldNull( List<Id> oppIdList, Map<String,String> mErrorMssgRec, List<case> caseList, List<Id> accountIds,
                                                     List<Case> caseListGST, List<Id> oppIdListGST){
        Set<Id> profileIdSet = new Set<Id>();
        if(caseList.size()>0) {
        	for( Profile pf : [select Id, Name from Profile where Name = 'Momentum Integration' OR Name = 'Mulesoft Integration' 
                           OR Name = 'Marketo Integration' OR Name = 'Luna Integration']){
                               profileIdSet.add(pf.Id);
            }
        }                                                
       
        Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>([ Select Id, Commercial_Segmentation__c, Deal_Type__c  FROM Opportunity 
                                                               Where Id In: oppIdList OR Id IN: oppIdListGST ]);
        Map<Id,Account> accMap;
        if(accountIds.size()>0)
        	accMap = new Map<Id, Account>([Select Id, GST__c, BillingCountry  FROM Account 
                                                               Where Id In: accountIds]);
        for( Case varCase : caseList ){
            if( oppMap.get(varCase.Opportunity__c).Commercial_Segmentation__c == 'Standardized'
               && !profileIdSet.contains(UserInfo.getProfileId()) && !varCase.Validation_Override__c  
               && varCase.Customer_Segment_Order_Treatment__c == NULL  )
            {
                varCase.addError(mErrorMssgRec.get('OA Commercial Segmentation Required') );
            }
        }
        //SFDC-9221 Manish Mahajan
        List<L2Q_TaxID_Country_Code__mdt> listMdt = [Select Id,Prefix__c,Country_Name__c from L2Q_TaxID_Country_Code__mdt];
            List<String> GSTCountries = new List<String>();
            for(L2Q_TaxID_Country_Code__mdt mdt: listMdt){
                GSTCountries.add(mdt.Country_Name__c);
            }
                                                         
        for( Case varCase : caseListGST ){
            if( accMap != NULL && varCase.Opportunity__c != NULL && varCase.AccountId != NULL
              && oppMap.get(varCase.Opportunity__c).Deal_Type__c == 'Direct' 
              && String.isBlank(accMap.get(varCase.AccountId).GST__c) 
              && GSTCountries.contains(accMap.get(varCase.AccountId).BillingCountry)){
                varCase.addError(mErrorMssgRec.get('OA_OM_GST_Check') );
            }
        }
    }
    
    public static void updateADApprover(List<Id> lOAApproverChangeCaseId, Map<Id,Case> newMap){
        List<Approval_Details__c> updateADList = new List<Approval_Details__c>();
        for(Approval_Details__c thisAD : [Select id,Approver_New__c,Approval_Status__c,Related_To__c from Approval_Details__c where Related_To__c in:(lOAApproverChangeCaseId) and Approval_Status__c IN('Pending','Escalated')]){
            thisAD.Approver_New__c = newMap.get(thisAD.Related_To__c).Approver__c;
            updateADList.add(thisAD);
        }
        try{
            update updateADList;
        }
        catch(Exception e)
        {
            system.debug('Exception while reopening : '+e.getMessage());
            throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));   
        }
    }
    public static void validateCaseEdit(Case oldCase, Case newCase, String caseRT,Map<String,String> mErrorMssgRec){
        Map<String,String> caseRTPLMap = new Map<String, String>{'Order Approval-Deal Desk' => 'Case-Order Approval-Deal Desk Layout',
                                                                'Order Approval-Legal' => 'Case-Order Approval-Legal Layout',
                                                                'Order Approval-Escalations' => 'Case-Order Approval-Escalations Layout',
                                                                'Order Approval-Order Management' => 'Case-Order Approval-Order Management Layout',
                                                                'Order Approval-Others' => 'Case-Order Approval-Others Layout',
                                                                'Order Approval-Sales Manager' => 'Case-Order Approval-Sales Manager'};
                
       
        if(!oaRecursiveCheckEdit)
        {
            List<String> casePageLayoutList = new List<String>();
            casePageLayoutList.add(caseRTPLMap.get(caseRT));
            List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, casePageLayoutList);
            String queryString = 'AccountId,Opportunity__c';
            Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
            for (Metadata.LayoutSection section : layoutMd.layoutSections) {
                if(section.label == 'Case Information'){
                    for (Metadata.LayoutColumn column : section.layoutColumns) {
                        if (column.layoutItems != null) {
                            for (Metadata.LayoutItem item : column.layoutItems) {
                                if(item.field != null){
                                    queryString += ','+item.field;
                                    system.debug('ITEM FIELD : : : '+item.field);
                                    system.debug('VALIDATIPN : '+newCase.get('Validation_Override__c'));
                                    if(Userinfo.getUserId() != newCase.get('OwnerId') && oldCase.get(String.valueOf(item.field)) != newCase.get(String.valueOf(item.field))){
                                        system.debug('inside if : '+item.field);
                                        system.debug('iuadhsau : '+mErrorMssgRec.get('OA Field Edit Error'));
                                        system.debug('aysdgkhasj : '+String.valueOf(item.field));
										if(item.field != 'OwnerId' && item.field != 'Approver__c' && item.field != 'Age_Business_Days__c' && item.field != 'AutoClose__c')
                                        {
                                            if(newCase.get('Status') == 'Reopened'  && 
                                                (item.field == 'Status' || item.field == 'Reopened__c' || item.field == 'Re_open_Reason_Code__c' || item.field == 'Re_open_Comments__c'))
                                            {
                                                newCase.AKAM_Reopened_Date__c = system.now();
                                            }
                                            else if(newCase.get('Validation_Override__c') != true ){
                                                newCase.addError(mErrorMssgRec.get('OA Field Edit Error').replace('{0}',String.valueOf(item.field)));
                                            }
                                        }
                                        /*if(item.field == 'OwnerId' || item.field == 'Approver__c' || item.field == 'Age_Business_Days__c' || item.field == 'AutoClose__c'){
                                            break;
                                        }
                                        else if(newCase.get('Status') == 'Reopened'  && 
                                                (item.field == 'Status' || item.field == 'Reopened__c' || item.field == 'Re_open_Reason_Code__c' || item.field == 'Re_open_Comments__c'))
                                        {
                                            newCase.AKAM_Reopened_Date__c = system.now();   
                                            break;
                                        }
                                        
                                        else if(newCase.get('Validation_Override__c') != true ){
                                            newCase.addError(mErrorMssgRec.get('OA Field Edit Error').replace('{0}',String.valueOf(item.field)));
                                        }*/
                                    }
                                }
                            }
                        }
                    }
                }
            }
            oaRecursiveCheckEdit = true;
		}                                                                                                                               
    }
    
    
    public static Messaging.SingleEmailMessage sendEmailWithoutContact(ID emailTempId, Id userId, Id caseId,Id orgWideEmailId) {
        Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();
        email = Messaging.renderStoredEmailTemplate(emailTempId, userId,caseId);
        email.setOrgWideEmailAddressId(orgWideEmailId);
        email.setSaveAsActivity(false);
        return email;
    }
    
    public static void caseClosureNotificationLogic( List<Id> caseIds, Map<Id,List<Id>> oaIdWithListCaseId, Map<Id, Id> caseIdWithOppIdMap, List<Id> oaCaseIdOwnerAssignenment ){
        Map<Id,Set<String>> caseIdWithUserIdSet = new Map<Id,Set<String>>();
        Map<Id,Set<String>> CPQCaseIdWithUserIdSet = new Map<Id,Set<String>>();
        Set<String> userIdSet;
        Map<Id,String> oaIdWithOppOwnerId = new Map<Id,String>();
        Map<Id,List<Id>> oppIdWithOppTeamMemIdList = new Map<Id, List<ID>>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<Id> oppTeamMembIds;
		Map<Id,Id> caseIdwithUserId = new Map<Id,Id>();
        Id caseCloseTemplateId, caseAssignmentTemplateId;
        
        OrgWideEmailAddress  owe = [select id, Address from OrgWideEmailAddress where DisplayName = 'Order Approval' LIMIT 1];
        //Sales - Secondary,Channel - Primary,TeamMemberRole 
        for(EmailTemplate et: [Select id,Name from EmailTemplate where name = 'Case Close All Order Approvals' OR Name ='Case Assignment Notification']){
            if(et.Name == 'Case Close All Order Approvals')
                caseCloseTemplateId = et.id;
            else if(et.Name == 'Case Assignment Notification')
                caseAssignmentTemplateId = et.id;
        }
        for( Case cs : [Select Id, createdById,createdBy.Email, OwnerId, Owner.Email ,Order_Approval__c, RecordType.Name, 
                        Order_Approval__r.Associated_Opportunity__r.Owner.Email,AlternateContactEmailManagedSecurity__c,IsCreatedbyCPQ__c 
                        FROM Case 
                        WHERE Id IN :caseIds 
                        OR Id in : oaCaseIdOwnerAssignenment
                        OR (Order_Approval__c IN :oaIdWithListCaseId.keySet() 
                            AND RecordType.Name = 'Order Approval-Order Management')]){
        	if(caseIds.contains(cs.id) && cs.Order_Approval__r.Associated_Opportunity__r.Owner.Email != 'eae-ops@akamai.com'){
                userIdSet = new Set<String>();
                userIdSet.add(cs.Order_Approval__r.Associated_Opportunity__r.OwnerId);    
                userIdSet.add(cs.createdById);
                if(cs.IsCreatedbyCPQ__c){
                    CPQCaseIdWithUserIdSet.put(cs.Id, userIdSet);
                }
                else{
                    caseIdWithUserIdSet.put(cs.Id, userIdSet);
                }
            } 
            //to send email to case creator when                     
            if(oaCaseIdOwnerAssignenment.contains(cs.id)){
                caseIdwithUserId.put(cs.Id, cs.createdById);
            }                    
                                
            if(oaIdWithListCaseId.containsKey(cs.Order_Approval__c) && cs.RecordType.Name == 'Order Approval-Order Management'
               && (''+cs.OwnerId).startsWith('005') && userIdSet != null && !userIdSet.contains(cs.OwnerId)){
                   oaIdWithOppOwnerId.put(cs.Order_Approval__c,cs.OwnerId);
            }
                                
        }
        if(!caseIdWithOppIdMap.isEmpty()){
            for(OpportunityTeamMember otm : [Select Id,user.Email, UserId,OpportunityId  From OpportunityTeamMember 
                                         Where (TeamMemberRole = 'Sales - Secondary' OR TeamMemberRole = 'Channel - Primary')
                                         	And OpportunityId in : caseIdWithOppIdMap.values()]){
                if(!oppIdWithOppTeamMemIdList.containsKey( otm.OpportunityId )  ){
                    oppIdWithOppTeamMemIdList.put( otm.OpportunityId, new List<Id>());                    
                }
                oppTeamMembIds = oppIdWithOppTeamMemIdList.get(otm.OpportunityId);
                oppTeamMembIds.add(otm.UserId); 
                oppIdWithOppTeamMemIdList.put( otm.OpportunityId, oppTeamMembIds );                                     
            }
        }
        
        //sending email to case creator and opp owner
        for(Id csId : caseIdWithUserIdSet.keySet()){
            for(String usrId : caseIdWithUserIdSet.get(csId)){
                emailList.add(CaseTriggerClass_OA.sendEmailWithoutContact( caseCloseTemplateId, usrId, csId, owe.Id));
            }
        }
        
        //sending email to CPQ case creator and opp owner
        for(Id csId : CPQCaseIdWithUserIdSet.keySet()){
            for(String usrId : CPQCaseIdWithUserIdSet.get(csId)){
                emailList.add(CaseTriggerClass_OA.sendEmailWithoutContact( caseCloseTemplateId, usrId, csId, owe.Id));
            }
        }
        
        //sending email to OM case owner
        for(Id oaId : oaIdWithOppOwnerId.keySet()){
            for(Id caseId : oaIdWithListCaseId.get(oaId)){
                emailList.add(CaseTriggerClass_OA.sendEmailWithoutContact( caseCloseTemplateId, oaIdWithOppOwnerId.get(oaId), caseId, owe.Id));
            }
        }  
        //sending email to opp team member, if OTM is not case creator
        for(Id caseId : caseIdWithOppIdMap.keySet()){
            if(oppIdWithOppTeamMemIdList.containsKey(caseIdWithOppIdMap.get(caseId))){
                for( Id userId : oppIdWithOppTeamMemIdList.get(caseIdWithOppIdMap.get(caseId))){
                    if(caseIdWithUserIdSet.containsKey(caseId) && !caseIdWithUserIdSet.get(caseId).contains(userId)){
                        emailList.add(CaseTriggerClass_OA.sendEmailWithoutContact( caseCloseTemplateId, userId, caseId, owe.Id));
                    }
            	}
            }
            
        }
        //sending email to case creator when case assignment changed to user from queue 
		for(Id caseId : caseIdwithUserId.keySet()){
            emailList.add(CaseTriggerClass_OA.sendEmailWithoutContact( caseAssignmentTemplateId, caseIdwithUserId.get(caseId), caseId, owe.Id));
        } 
        if(emailList.size()>0){                    
            Messaging.sendEmail(emailList); 
        }
        
        CaseTriggerClass_OA.oaRecursiveCheckSendEmail = True;
    	
    }
    
     //OA Changes
    public static void updateOACaseStatus(Map<EmailMessage,Boolean> lstMessages, Map<Id,Case> caseMap)
    {
        Set<Id> recentUpdatedCaseIds = new Set<Id>();
        List<Case> caseLst = new List<Case>();
        Case cs;
        List<messaging.SingleEmailMessage> emailMessagesList = new List<messaging.SingleEmailMessage>();
        messaging.SingleEmailMessage email;
        //Collect the incoming emails' CaseIds
        for(EmailMessage em : lstMessages.keySet())
        {
            cs = caseMap.get(em.ParentId);
            cs.Validation_Override__c = True; 
            
            // Checking if Parent Object = Case
            if(String.valueOf(em.ParentId).startsWith('500') && cs != null) 
            {
                if( cs.IsClosed == False ){
                    // Checking if it is Incoming Email, else outgoing Email
                    if(em.Incoming == true) {
                        if( cs.Owner.Email == em.FromAddress ){
                            cs.Status = 'Waiting for Internal Response';
                        } else {  
                            cs.Status = 'Internal Response Received';
                        } 
                    }
                    else {
                        
                        if( cs.Status == 'Unassigned' || cs.Status == 'Assigned'|| cs.Status == 'New Request' 
                           || cs.Status == 'In Progress' || cs.Status == 'Reopened' || cs.Status == 'Internal Response Received'){
                               if( checkSenderApprovingGroup(cs) ){
                                   cs.Status = 'Waiting for Internal Response';
                               }
                           } else if( cs.Status == 'Waiting for Internal Response' && !checkSenderApprovingGroup(cs)){
                               cs.Status = 'Internal Response Received';
                           }
                    } 
                } else if( em.Incoming == TRUE && CaseTriggerClass_OA.skipCloseCaseEmailLogic == False){
                    String bodyMsg = 'Hi '+em.FromName
									+'</br></br>You have sent a message related to an approval case that has been closed.'
                    				+' For general inquires please reach out directly to the individual who was previously assisting you.'
                    				+' If you require continued assistance or a change related to this case you must return to Salesforce and Reopen the case. Link to the case:<a href=\''+URL.getSalesforceBaseUrl().toExternalForm()+'/'+cs.Id+'\'>'+cs.AKAM_Case_ID__c+'</a>'
									+'</br></br>Thanks!';
                    email=new messaging.SingleEmailMessage();
                    email.setToAddresses(new List<String>{em.FromAddress});
                    email.setSubject(cs.RecordType.Name+' Case [AKAM-CASE #'+cs.AKAM_Case_ID__c +'] is Closed');
                    email.setHtmlBody (bodyMsg);
                    emailMessagesList.add(email);
                }
            }
            caseLst.add(cs);
        } 
        
        if(caseLst.size() > 0) 
        {
            update caseLst;
        }
        messaging.sendEmail(emailMessagesList);
    }
    public static Boolean checkSenderApprovingGroup(Case cs){
        String recordTypeName = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosById().get(cs.RecordTypeId).getName();
        Boolean isAG = false;
        
        //ESESP-6846: Checking if User has OA_Deal_Desk permission set
        Boolean hasDDPermissionSet = FeatureManagement.checkPermission('OA_Deal_Desk');
        
        if(recordTypeName == 'Order Approval-Order Management' || recordTypeName == 'Order Approval-Deal Desk' || recordTypeName == 'Order Approval-Legal'){
            Map<Id,String> profileidNameMap = new Map<Id,String>();
            for(Profile pf : [Select id, Name from Profile where Name = 'SA - Analyst' or Name = 'SA - Manager' Or Name = 'Legal' Or Name = 'Deal Desk']){
                profileidNameMap.put(pf.id,pf.Name);
            }
            //ESESP-6846: Added condition to check permission set
            if( userinfo.getuserid() == cs.OwnerId  
               ||( recordTypeName == 'Order Approval-Order Management' &&
                  (profileidNameMap.get(userInfo.getProfileId()) == 'SA - Analyst' || profileidNameMap.get(userInfo.getProfileId()) == 'SA - Manager') )
               || ( recordTypeName == 'Order Approval-Deal Desk' && (profileidNameMap.get(userInfo.getProfileId()) == 'Deal Desk' || hasDDPermissionSet)) 
               || ( recordTypeName == 'Order Approval-Legal' && profileidNameMap.get(userInfo.getProfileId()) == 'Legal' ) 
              ){
                isAG = true;
            }
        } else if( userinfo.getuserid() == cs.OwnerId  ){
            isAG = true;
        }
        
        return isAG;
    }

    //SFDC-8991 OA Auto renewal Changes L2Q Team
    public static void caseValidationOnAutoRenewalOppty(Set<Id> caseOpptyOAAutoRenewal,List<Case> newMap,Map<String,String> mErrorMssgRec){
                Set<Id> opptyIdList = new Set<Id>();
        system.debug('Inside the method '+opptyIdList +'Record '+caseOpptyOAAutoRenewal);

        for(Opportunity opp : [Select Id,Auto_Renewal__c,Opportunity_Type__c
                                FROM Opportunity
                                WHERE Id IN :caseOpptyOAAutoRenewal AND Auto_Renewal__c = true AND Opportunity_Type__c = 'Auto-Renewal'])
        {
            system.debug('Inside for loop of Oppty'+opp);
            opptyIdList.add(opp.Id);
        }

        for(Case csRec: newMap){
            if(!opptyIdList.isEmpty() && opptyIdList.contains(csRec.Opportunity__c))
            {
                csRec.addError(mErrorMssgRec.get('OA Case Validation Auto Renewal Oppty'));
            }
        } 
    }
}