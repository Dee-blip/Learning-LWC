public class GroupSharing {

    public static Map<Id,Id> parentAccMap = new Map<Id,Id>();
    static List<AccountShare> accShares = new List<AccountShare>();
    //static Boolean removeSharesFirstRunFlag = true;
    public static Boolean accountShareManagementTriggerFirstRunFlag = true;    
    
    //Commenting for SFDC-948, as this logic was getting called in each alternate update and was creating shares
    //@future
    //public static void createOpportunityShares(Map<Id,String> oppAccMap, Map<Id,Id> accountIdUserRoleIdMap, Map<Id,Id> gMap) {
    //    //get the highest roles for these accounts
    //    createOppShares(oppAccMap, accountIdUserRoleIdMap, gMap);
    //}

    public static void createOppShares(Map<Id,String> oppAccMap, Map<Id,Id> accountIdUserRoleIdMap, Map<Id,Id> gMap){
        List<OpportunityShare> oppShares = new List<OpportunityShare>();
        for (Id oppId : oppAccMap.keySet()) {
            List<Id> parentIds = oppAccMap.get(oppId).split(',');
            for(Id pid : parentIds){
                Id roleId = accountIdUserRoleIdMap.get(pId); 
                if (roleId == null) {
                    System.debug('oppId for null = ' + oppId);
                } else {
                    Id relatedGroupId = gMap.get(roleId);   
                    System.debug('relatedGroupId = ' + relatedGroupId);
                    if (relatedGroupId != null) {
                        oppShares.add(new OpportunityShare( 
                                                        OpportunityAccessLevel = 'Edit', 
                                                        OpportunityId = oppId, 
                                                        UserOrGroupId = relatedGroupId));                   
                    } else {
                        System.debug('roleId for null = ' + roleId);
                    }
                }
            }
        }
        if (oppShares.size() > 0){
            System.debug('#oppShares.size()#'+ oppShares.size());
            insert oppShares;
        }       
        
    }
    //Vinay:CR 1179730 Error on LeadShares: Too many SOQL queries
	//Commenting out the whole function as its not needed anymore.
   /* @future
    public static void createLeadShares(Map<Id,String> leadAccMap, Map<Id,Id> accountIdUserRoleIdMap, Map<Id,Id> gMap) {
        //get the highest roles for these accounts
        List<LeadShare> leadShares = new List<LeadShare>();
        for (Id Id : leadAccMap.keySet()) {
            List<Id> parentIds = leadAccMap.get(Id).split(',');
            for(Id pid : parentIds){
                Id roleId = accountIdUserRoleIdMap.get(pId);
                if (roleId == null) {
                    System.debug('Id for null = ' + Id);
                } else {
                    Id relatedGroupId = gMap.get(roleId);   
                    System.debug('relatedGroupId = ' + relatedGroupId);
                    if (relatedGroupId != null) {
                        if(leadShares.size() < 1000){
                            leadShares.add(new LeadShare( LeadAccessLevel = 'Edit', LeadId = Id, UserOrGroupId = relatedGroupId));  
                        }
                        else{
                            insert leadShares;
                            leadShares.clear();
                            leadShares.add(new LeadShare( LeadAccessLevel = 'Edit', LeadId = Id, UserOrGroupId = relatedGroupId));
                        }                       
                    } else {
                        System.debug('roleId for null = ' + roleId);
                    }
                }
            }
        }
        if(leadShares.size() > 0){
            insert leadShares;
        }
    }*/

    //added by ankita 3/25/2010 for case support - Zebra
    
    @future
    public static void createCaseShares(Map<Id,String> caseAccMap, Map<Id,Id> accountIdUserRoleIdMap, Map<Id,Id> gMap) {
        //get the highest roles for these accounts
        List<CaseShare> caseShares = new List<CaseShare>();
        for (Id Id : caseAccMap.keySet()) {
            List<Id> parentIds = caseAccMap.get(Id).split(',');
            for(Id pid : parentIds){
                Id roleId = accountIdUserRoleIdMap.get(pId);
                if (roleId == null) {
                    System.debug('Id for null = ' + Id);
                } else {
                    Id relatedGroupId = gMap.get(roleId);   
                    System.debug('relatedGroupId = ' + relatedGroupId);
                    if (relatedGroupId != null) {
                        caseShares.add(new CaseShare( CaseAccessLevel = 'Edit', 
                                                        CaseId = Id, 
                                                        UserOrGroupId = relatedGroupId));                    
                    } else {
                        System.debug('roleId for null = ' + roleId);
                    }
                }
            }
        }
        if(caseShares.size() > 0){
            insert caseShares;
        }
    }

    static Map<ID,Set<Id>> getChildAccounts(Set<Id> accIds){
        //create a set of child account ids 
        Map<Id,Set<Id>> childAcctsMap = new Map<Id,Set<Id>>();
        List<Account> childAccs;
        if(GroupSharingHelper.ISTEST){ childAccs = [select id, ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, Parent.Parent.Parent.parent.ParentId from Account where id in :accIds or parentId in :accIds or parent.ParentId in :accIds  or parent.parent.parentId in :accIds or parent.parent.parent.parentId in :accIds or parent.parent.parent.parent.parentId in :accIds limit 10] ;
        }else{                                          
             childAccs = [select id, ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, Parent.Parent.Parent.parent.ParentId 
                                    from Account 
                                    where id in :accIds 
                                    or parentId in :accIds 
                                    or parent.ParentId in :accIds 
                                    or parent.parent.parentId in :accIds
                                    or parent.parent.parent.parentId in :accIds
                                    or parent.parent.parent.parent.parentId in :accIds];
        }
        String children = '';
        for(Account a : childAccs){
            Set<Id> childIds = new Set<Id>();
            if(accIds.contains(a.Id)){
                if(childAcctsMap.containsKey(a.Id)){ childIds = childAcctsMap.get(a.Id); childIds.add(a.Id);
                }else{ 
                    childIds.add(a.id); 
                    childAcctsMap.put(a.Id,childIds);
                }
            }else if(accIds.contains(a.ParentId)){
                if(childAcctsMap.containsKey(a.ParentId)){
                    childIds = childAcctsMap.get(a.ParentId);
                    childIds.add(a.Id);
                }else{ childIds.add(a.Id); childAcctsMap.put(a.ParentId,childIds);}
            }else if(accIds.contains(a.parent.ParentId)){
                if(childAcctsMap.containsKey(a.parent.ParentId)){ childIds = childAcctsMap.get(a.parent.ParentId); childIds.add(a.Id);
                }else{ childIds.add(a.Id); childAcctsMap.put(a.parent.ParentId,childIds);}
            }else if(accIds.contains(a.parent.parent.ParentId)){
                if(childAcctsMap.containsKey(a.parent.parent.ParentId)){ childIds = childAcctsMap.get(a.parent.parent.ParentId); childIds.add(a.Id);
                }else{ childIds.add(a.Id); childAcctsMap.put(a.parent.parent.ParentId,childIds);}
            }else if(accIds.contains(a.parent.parent.parent.ParentId)){
                if(childAcctsMap.containsKey(a.parent.parent.parent.ParentId)){ childIds = childAcctsMap.get(a.parent.parent.parent.ParentId); childIds.add(a.Id);
                }else{ childIds.add(a.Id); childAcctsMap.put(a.parent.parent.parent.ParentId,childIds); }
            }else if(accIds.contains(a.parent.parent.parent.parent.ParentId)){
                if(childAcctsMap.containsKey(a.parent.parent.parent.ParentId)){ childIds = childAcctsMap.get(a.parent.parent.parent.ParentId); childIds.add(a.Id);
                }else{ childIds.add(a.Id); childAcctsMap.put(a.parent.parent.parent.ParentId,childIds); }
            }
        }
        return childAcctsMap;
        
    }
    
    public static void removeShares(List<Id> accIds,List<Id> gIds){
    	//if(!removeSharesFirstRunFlag)
    		//return;
        // Added code
        /*Configuration__c opportunitySettings;
        Map<String, Configuration__c> settingsMap = Configuration__c.getAll();
        if(settingsMap.containsKey('Opportunity')){
            opportunitySettings = settingsMap.get('Opportunity');
        }
        String customField ;
        // Boolean shareWithThisAcc = false;
        if(opportunitySettings != null){
            customField = opportunitySettings.Field_Name__c;
        }*/
        String customField = MTVUtil.getFieldName('Opportunity');
        //
        System.debug('##customField##'+customField);
        Set<Id> leadIds = new Set<id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> caseIds = new Set<id>();
        /**************Vinay:Added new code (CR:1131499)*****************/
        Set<Id> FrIds = new Set<id>();
        Set<Id> FcIds = new Set<id>();
        Set<Id> FbIds = new Set<id>();
        /**************(END)Vinay:Added new code (CR:1131499)*****************/
        String leadQry = 'select id from Lead where partneraccountId in (' + GroupSharingHelper.join(accIds, ',', '\'') + ')';
        // Changed code
        String oppQry = 'select id from Opportunity where '+ customField + ' in (' + GroupSharingHelper.join(accIds, ',', '\'') + ')';
        //
        String caseQry = 'select id from Case where accountId in ('+ GroupSharingHelper.join(accIds, ',', '\'') + ')';
         /**************Vinay:Added new code (CR:1131499)*****************/
        String FrQry = 'select id from SFDC_MDF__c where Account__c in ('+ GroupSharingHelper.join(accIds, ',', '\'') + ')';
        
        String FcQry = 'select id from SFDC_MDF_Claim__c where Account__c in ('+ GroupSharingHelper.join(accIds, ',', '\'') + ')';
        
        String FbQry = 'select id from SFDC_Budget__c where Account__c in ('+ GroupSharingHelper.join(accIds, ',', '\'') + ')';
         /**************(END)Vinay:Added new code (CR:1131499)*****************/
        if(GroupSharingHelper.ISTEST){ leadQry = leadQry + ' limit 10'; oppQry = oppQry + ' limit 10'; caseQry = caseQry + ' limit 10'; FrQry =FrQry + ' limit 10'; FcQry =FcQry + ' limit 10'; FbQry =FbQry + ' limit 10';
             /**************(END)Vinay:Added new code (CR:1131499)*****************/
        } 
        List<Opportunity> opps = Database.query(oppQry);//[select id from Opportunity where partnerAccountId in :accIds];
        List<Lead> leads = Database.query(leadQry);//[select id from Lead where partneraccountId in :accIds];
        List<Case> cases = Database.query(caseQry);//[select id from Case where accountId in :accIds];
       	 /**************Vinay:Added new code (CR:1131499)*****************/
       	List<SFDC_MDF__c> Frs = Database.query(FrQry);
       	List<SFDC_MDF_Claim__c> Fcs = Database.query(FcQry);
       	List<SFDC_Budget__c> Fbs = Database.query(FbQry);
       	 /**************(END)Vinay:Added new code (CR:1131499)*****************/
        for(Lead l : leads){ leadIds.add(l.Id); }
        for(Opportunity o : opps){ oppIds.add(o.id); }
        for(Case c : cases){  caseIds.add(c.Id); }
         /**************Vinay:Added new code (CR:1131499)*****************/
        for(SFDC_MDF__c fr : Frs){ FrIds.add(fr.Id); }
        for(SFDC_MDF_Claim__c fr : Fcs){ FcIds.add(fr.Id); }
        for(SFDC_Budget__c fr : Fbs){ FbIds.add(fr.Id); }
         /**************(END)Vinay:Added new code (CR:1131499)*****************/
        List<LeadShare> lshares = new List<LeadShare>();
        List<OpportunityShare> oShares = new List<OpportunityShare>();
        List<AccountShare> aShares = new List<AccountShare>();
        List<CaseShare> cShares = new List<CaseShare>();
         /**************Vinay:Added new code (CR:1131499)*****************/
        List<SFDC_MDF__Share> FrShares = new List<SFDC_MDF__Share>();
        List<SFDC_MDF_Claim__Share> FcShares = new List<SFDC_MDF_Claim__Share>();
        List<SFDC_Budget__Share> FbShares = new List<SFDC_Budget__Share>();
         /**************(END)Vinay:Added new code (CR:1131499)*****************/
        
        for(LeadShare ls : [select id from LeadShare where leadId in :leadIds and rowCause = 'Manual' and UserOrGroupId in :gids]){lshares.add(ls);}
        
        if(lshares.size() > 0){ delete lshares; }
        
        for(AccountShare acs : [select id from AccountShare where AccountId in :accIds and rowCause = 'Manual' and UserOrGroupId in :gIds]){aShares.add(acs); }
        
        if(aShares.size() > 0){  delete aShares;     }
        
        for(OpportunityShare os : [select id from OpportunityShare where opportunityId in :oppIds and rowCause = 'Manual' and UserOrgroupId in :gIds and IsDeleted=false ]){oShares.add(os);}
        
        if(oShares.size() > 0){ delete oShares;}
        
        
    
        for(CaseShare cs : [select id from CaseShare where caseId in :caseIds and rowCause = 'Manual' and UserOrGroupId in :gids]){ cShares.add(cs); }
        
        if(cShares.size() > 0){ delete cShares;}
         /**************Vinay:Added new code (CR:1131499)*****************/
        for(SFDC_MDF__Share cs : [select id from SFDC_MDF__Share where ParentId in :FrIds and rowCause = 'Manual' and UserOrGroupId in :gids]){ FrShares.add(cs);}
        
        if(FrShares.size() > 0){ delete FrShares;}

        for(SFDC_MDF_Claim__Share cs : [select id from SFDC_MDF_Claim__Share where ParentId in :FcIds and rowCause = 'Manual' and UserOrGroupId in :gids]){FcShares.add(cs); }
        
        if(FcShares.size() > 0){ delete FcShares;}

        for(SFDC_Budget__Share cs : [select id from SFDC_Budget__Share where ParentId in :FbIds and rowCause = 'Manual' and UserOrGroupId in :gids]){ FbShares.add(cs);}
        
        if(FbShares.size() > 0){ delete FbShares;}
         /**************(END)Vinay:Added new code (CR:1131499)*****************/
        //removeSharesFirstRunFlag = false;
    }
    
    @future
    public static void calcChildShares(Map<Id, String> accParentMap, Map<Id,Id> accountIdUserRoleIdMap, Map<Id,Id> gMap, String mode){
        System.debug('In calcChildShares--accParentMap='+ accParentMap);
        System.debug('In calcChildShares --accountIdUserRoleIdMap='+ accountIdUserRoleIdMap);
        System.debug('In calcChildShares--gMap='+ gMap);
        Map<Id,Map<id,Id>> accGrpMap = new Map<Id,Map<id,Id>>();//map of acct id and its parents' group id
        Map<Id, Set<Id>> accChildMap = new Map<Id,Set<Id>>();
        List<Id> accChilds = new List<Id>();
        List<Id> accChilds1 = new List<Id>();
        accChildMap = getChildAccounts(accParentMap.keySet());
        for(Id id : accChildMap.keySet()){
            accChilds1.addAll(accChildMap.get(id));
        }
        for(Id i : accParentMap.keySet()){
            List<Id> parentIds = accParentMap.get(i).split(',');            
            Map<Id,Id> parentGrpMap = new Map<Id,Id>();
            for(Id pid : parentIds){
                Id roleId = accountIdUserRoleIdMap.get(pId);
                if (roleId == null) {
                } else { Id relatedGroupId = gMap.get(roleId); parentGrpMap.put(pid,relatedGroupId);
                }
            }
            System.debug('In calcChildShares loop parentGrpMap='+ parentGrpMap);
            accGrpMap.put(i,parentGrpMap);
        }
        System.debug('Child Accounts = ' + accChilds);
        List<Id> relatedGroupIds = GroupSharingHelper.getRelatedGroupIds(accParentMap, accountIdUserRoleIdMap, gMap);
        System.debug('Group Ids = '+relatedGroupIds);
        if(mode.equals('remove')){ removeShares(accChilds,gMap.Values());
        	//Vinay : changed code here and added abv line
            //removeShares(accChilds,relatedGroupIds);
            if(accChilds1.size() > 0){ removeShares(accChilds1,gMap.Values());
            }
        }else{
            createShares2(accChildMap,accGrpMap, new Map<Id,Id>(),gMap);
        }
    }

    @future
    public static void calcChildSharesFromUser(Set<Id> accIds, Map<Id,Id> accountIdUserRoleIdMap, Map<Id,Id> gMap, String mode){
        Map<Id,Id> accGrpMap = new Map<Id,Id>();//map of acct id and its group id
        Map<Id, Set<Id>> accChildMap = new Map<Id,Set<Id>>();
        accChildMap = getChildAccounts(accIds);
        for(Id i : accIds){
            Id roleId = accountIdUserRoleIdMap.get(i);
            if (roleId == null) {
                System.debug('Id for null = ' + i);
            } else {
                Id relatedGroupId = gMap.get(roleId);   
                accGrpMap.put(i,relatedGroupId);
            }
        }
        createShares(accChildMap,new Map<Id, Map<Id,Id>>(),accGrpMap);
    }
	static void createShares(Map<Id, Set<Id>> accChildMap, Map<Id,Map<id,Id>> accGrpMap, Map<Id,Id> acctGroupIdMap){
		createShares2(accChildMap,accGrpMap,acctGroupIdMap,new Map<Id,Id>());
	}
    static void createShares2(Map<Id, Set<Id>> accChildMap, Map<Id,Map<id,Id>> accGrpMap, Map<Id,Id> acctGroupIdMap,Map<Id,Id> gMapMTV){
        // Added code
        /*Configuration__c opportunitySettings;
        Map<String, Configuration__c> settingsMap = Configuration__c.getAll();
        if(settingsMap.containsKey('Opportunity')){
            opportunitySettings = settingsMap.get('Opportunity');
        }
        String customField ;
        // Boolean shareWithThisAcc = false;
        if(opportunitySettings != null){
            customField = opportunitySettings.Field_Name__c;
        }*/
        String customField = MTVUtil.getFieldName('Opportunity');
        System.debug('Custom Field Name: ' + customField);
        //
        System.debug('accChildMap = ' + accChildMap);
        System.debug('accGrpMap = ' + accGrpMap);
        System.debug('acctGroupIdMap - ' + acctGroupIdMap);
        List<AccountShare> aShares = new List<AccountShare>();
        List<LeadShare> lShares = new List<LeadShare>();
        List<OpportunityShare> oShares = new List<OpportunityShare>();
        List<CaseShare> cShares = new List<CaseShare>();
        List<Id> accChilds = new List<Id>();
        List<Id> accChilds1 = new List<Id>();
        Map<String, Default__c> accessSettingsMap = Default__c.getAll();
        Default__c settings ;
        if(accessSettingsMap.containsKey('Default')){
            settings = accessSettingsMap.get('Default');
        }
        String caseAccess = 'None';
        String oppAccess = 'None';
        if(settings != null){
            caseAccess = settings.Case_Access_Level__c == null ? 'None': settings.Case_Access_Level__c;
            oppAccess = settings.Opportunity_Access_Level__c == null ? 'None' : settings.Opportunity_Access_Level__c;
        }
        for(Id i : accChildMap.keySet()){
            System.debug('Account id = ' + i);
            accChilds1.addAll(accChildMap.get(i));
            
            for(Id j : accChildMap.get(i)){
                System.debug('Child Account id = ' + j);
                if(!accGrpMap.isEmpty()){
                    for(Id k : accGrpMap.get(i).values()){
                        System.debug('Group id accGrpMap = ' + k);
                        aShares.add(new AccountShare(accountaccesslevel = 'Edit', AccountId = j, CaseAccessLevel = caseAccess, OpportunityAccessLevel = oppAccess, UserOrGroupId = k));
                    }
                }else if(!acctGroupIdMap.isEmpty()){
                        System.debug('Group id = ' + acctGroupIdMap.get(i));
                        if(acctGroupIdMap.containsKey(i)){
                            aShares.add(new AccountShare(accountaccesslevel = 'Edit', AccountId = j, CaseAccessLevel = caseAccess, OpportunityAccessLevel = oppAccess, UserOrGroupId = acctGroupIdMap.get(i)));
                        }
                }
            }
        }
        System.debug('##aShares.size()##'+aShares.size());
        if(aShares.size() > 0){
            insert aShares; 
            System.debug('##aShares##'+aShares);
        }
        String leadQry = 'select id, partnerAccountId, PartnerAccount.ParentId, partnerAccount.Parent.ParentId,' + 
                            ' PartnerAccount.parent.parent.parentId, partnerAccount.parent.parent.parent.parentId,' +
                            ' partneraccount.parent.parent.parent.parent.parentid from Lead';
        String whereCls ;
        String cond1 = GroupSharingHelper.join(accChilds, ',', '\'');
        if(cond1 == ''){
            whereCls = '';
        }else{ whereCls = ' where partnerAccountId in (' + cond1 + ')';
        }
        String cond2 = GroupSharingHelper.join(accChilds1, ',', '\'');
        if(cond2 != ''){
            if(whereCls != ''){ whereCls = whereCls + ' or partnerAccountId in (' + cond2 + ')';
            }else{
                whereCls = ' where partnerAccountId in ('+ cond2 + ')';
            }
        }
        leadQry = leadQry + whereCls;
                            
/*      Map<Id, Lead> leadMap = new Map<Id, Lead>([select id, partnerAccountId, PartnerAccount.ParentId, partnerAccount.Parent.ParentId, 
                                                    PartnerAccount.parent.parent.parentId, partnerAccount.parent.parent.parent.parentId,
                                                    partneraccount.parent.parent.parent.parent.parentid
                                                    from Lead where partnerAccountId in :accChilds or partnerAccountId in :accChilds1]);*/
        if(GroupSharingHelper.ISTEST){leadQry = leadQry + ' limit 10';
        }                                           
        List<Lead> leads = Database.query(leadQry);                                         
        Map<Id, Lead> leadMap = new Map<Id, Lead>(leads);                                           
        List<Id> parents = new List<Id>();
        Map<Id,List<Id>> leadParentMap = new Map<Id,List<Id>>();
        Boolean isPartnerPortal = false;
        if(settings != null){
            isPartnerPortal = settings.is_Partner_Portal_Enabled__c;
        }
        if(isPartnerPortal){
        for(Id i : leadMap.keySet()){
            Account parent = leadMap.get(i).partnerAccount.parent;  
            if(parent != null){  parents.add(parent.Id); while(parent.ParentId != null){ parents.add(parent.ParentId); if(parent.Parent != null){ parent = parent.Parent; }}}
            leadParentMap.put(i,parents);
        }
        for(Id id : leadParentMap.keySet()){
            Id relatedId;
            for(Id j : leadParentMap.get(id)){
                if(!accGrpMap.isEmpty()){                   
                    if(accGrpMap.get(leadMap.get(id).PartnerAccountId) != null){ relatedId = accGrpMap.get(leadMap.get(id).PartnerAccountId).get(j);
                    }
                    if(accGrpMap.get(leadMap.get(id).PartnerAccount.ParentId) != null){ relatedId = accGrpMap.get(leadMap.get(id).PartnerAccount.ParentId).get(j); 
                    }
                    if(accGrpMap.get(leadMap.get(id).partnerAccount.Parent.ParentId) != null){ relatedId = accGrpMap.get(leadMap.get(id).partnerAccount.Parent.ParentId).get(j);
                    }
                    
                    if(accGrpMap.get(leadMap.get(id).PartnerAccount.parent.parent.parentId) != null){ relatedId = accGrpMap.get(leadMap.get(id).PartnerAccount.parent.parent.parentId).get(j);
                    }
                    
                    if(accGrpMap.get(leadMap.get(id).partnerAccount.parent.parent.parent.parentId) != null){ relatedId = accGrpMap.get(leadMap.get(id).partnerAccount.parent.parent.parent.parentId).get(j);
                    }
                    
                    if(accGrpMap.get(leadMap.get(id).partneraccount.parent.parent.parent.parent.parentid) != null){ relatedId = accGrpMap.get(leadMap.get(id).partneraccount.parent.parent.parent.parent.parentid).get(j);
                    }                   
                }
                else if(!acctGroupIdMap.isEmpty()){ relatedId = acctGroupIdMap.get(j); }
                
                if(relatedId != null){ lShares.add(new LeadShare(LeadAccessLevel = 'Edit', LeadId = id, UserOrGroupId = relatedId));  }               
            }
        }
        }   
        if(lShares.size() > 0){ insert lShares;
        }  // Changed code 
        
        /**********************************************************************/
        // For Fund Requests
        /**********************************************************************/
        List<SFDC_MDF__Share> FrShares = new List<SFDC_MDF__Share>();
        String FrQry = 'select id, Account__c, Account__r.ParentId, Account__r.Parent.ParentId,' + 
                            ' Account__r.parent.parent.parentId, Account__r.parent.parent.parent.parentId,' +
                            ' Account__r.parent.parent.parent.parent.parentid from SFDC_MDF__c';
        cond1 = GroupSharingHelper.join(accChilds, ',', '\'');
        if(cond1 == ''){
            whereCls = '';
        }else{ whereCls = ' where Account__c in (' + cond1 + ')';
        }
        cond2 = GroupSharingHelper.join(accChilds1, ',', '\'');
        if(cond2 != ''){
            if(whereCls != ''){ whereCls = whereCls + ' or Account__c in (' + cond2 + ')';
            }else{
                whereCls = ' where Account__c in ('+ cond2 + ')';
            }
        }
        frQry = frQry + whereCls;
                            
/*      Map<Id, Lead> leadMap = new Map<Id, Lead>([select id, partnerAccountId, PartnerAccount.ParentId, partnerAccount.Parent.ParentId, 
                                                    PartnerAccount.parent.parent.parentId, partnerAccount.parent.parent.parent.parentId,
                                                    partneraccount.parent.parent.parent.parent.parentid
                                                    from Lead where partnerAccountId in :accChilds or partnerAccountId in :accChilds1]);*/                                        
        List<SFDC_MDF__c> frs = Database.query(frQry);                                         
        Map<Id, SFDC_MDF__c> frMap = new Map<Id, SFDC_MDF__c>(frs);                                           
        parents = new List<Id>();
        Map<Id,List<Id>> frParentMap = new Map<Id,List<Id>>();
        isPartnerPortal = false;
        //if(settings != null){
        //    isPartnerPortal = settings.is_Partner_Portal_Enabled__c;
        //}
        //if(isPartnerPortal){
        for(Id i : frMap.keySet()){
            Account parent = frMap.get(i).Account__r.parent;  
            if(parent != null){ 
                parents.add(parent.Id);  
                while(parent.ParentId != null){ parents.add(parent.ParentId); if(parent.Parent != null){ parent = parent.Parent; }}
            }
            frParentMap.put(i,parents);
        }
        for(Id id : frParentMap.keySet()){
            Id relatedId;
            for(Id j : frParentMap.get(id)){
                if(!accGrpMap.isEmpty()){                   
                    if(accGrpMap.get(frMap.get(id).Account__c) != null){ relatedId = accGrpMap.get(frMap.get(id).Account__c).get(j);
                    }
                    if(accGrpMap.get(frMap.get(id).Account__r.ParentId) != null){ relatedId = accGrpMap.get(frMap.get(id).Account__r.ParentId).get(j); 
                    }
                    if(accGrpMap.get(frMap.get(id).Account__r.Parent.ParentId) != null){ relatedId = accGrpMap.get(frMap.get(id).Account__r.Parent.ParentId).get(j);
                    }
                    
                    if(accGrpMap.get(frMap.get(id).Account__r.parent.parent.parentId) != null){ relatedId = accGrpMap.get(frMap.get(id).Account__r.parent.parent.parentId).get(j);
                    }
                    
                    if(accGrpMap.get(frMap.get(id).Account__r.parent.parent.parent.parentId) != null){ relatedId = accGrpMap.get(frMap.get(id).Account__r.parent.parent.parent.parentId).get(j);
                    }
                    
                    if(accGrpMap.get(frMap.get(id).Account__r.parent.parent.parent.parent.parentid) != null){ relatedId = accGrpMap.get(frMap.get(id).Account__r.parent.parent.parent.parent.parentid).get(j);
                    }                   
                }
                else if(!acctGroupIdMap.isEmpty()){ relatedId = acctGroupIdMap.get(j); }
                
                if(relatedId != null){ FrShares.add(new SFDC_MDF__Share(AccessLevel = 'Edit', ParentId = id, UserOrGroupId = relatedId));}               
            }
        }
        //}   
        if(FrShares.size() > 0){ insert FrShares;
        }  // Changed code 
        /**********************************************************************/
        // For Fund Claims
        /**********************************************************************/
        List<SFDC_MDF_Claim__Share> FcShares = new List<SFDC_MDF_Claim__Share>();
        String FcQry = 'select id, Account__c, Account__r.ParentId, Account__r.Parent.ParentId,' + 
                            ' Account__r.parent.parent.parentId, Account__r.parent.parent.parent.parentId,' +
                            ' Account__r.parent.parent.parent.parent.parentid from SFDC_MDF_Claim__c';
        cond1 = GroupSharingHelper.join(accChilds, ',', '\'');
        if(cond1 == ''){
            whereCls = '';
        }else{ whereCls = ' where Account__c in (' + cond1 + ')';
        }
        cond2 = GroupSharingHelper.join(accChilds1, ',', '\'');
        if(cond2 != ''){
            if(whereCls != ''){ whereCls = whereCls + ' or Account__c in (' + cond2 + ')';
            }else{
                whereCls = ' where Account__c in ('+ cond2 + ')';
            }
        }
        FcQry = FcQry + whereCls;
                                    
        List<SFDC_MDF_Claim__c> fcs = Database.query(FcQry);                                         
        Map<Id, SFDC_MDF_Claim__c> fcMap = new Map<Id, SFDC_MDF_Claim__c>(fcs);                                           
        parents = new List<Id>();
        Map<Id,List<Id>> fcParentMap = new Map<Id,List<Id>>();
        isPartnerPortal = false;
        //if(settings != null){
        //    isPartnerPortal = settings.is_Partner_Portal_Enabled__c;
        //}
        //if(isPartnerPortal){
        for(Id i : fcMap.keySet()){
            Account parent = fcMap.get(i).Account__r.parent;  
            if(parent != null){ 
                parents.add(parent.Id);  
                while(parent.ParentId != null){ parents.add(parent.ParentId); if(parent.Parent != null){ parent = parent.Parent; } }
            }
            fcParentMap.put(i,parents);
        }
        for(Id id : fcParentMap.keySet()){
            Id relatedId;
            for(Id j : fcParentMap.get(id)){
                if(!accGrpMap.isEmpty()){                   
                    if(accGrpMap.get(fcMap.get(id).Account__c) != null){ relatedId = accGrpMap.get(fcMap.get(id).Account__c).get(j); }
                    if(accGrpMap.get(fcMap.get(id).Account__r.ParentId) != null){  relatedId = accGrpMap.get(fcMap.get(id).Account__r.ParentId).get(j); }
                    if(accGrpMap.get(fcMap.get(id).Account__r.Parent.ParentId) != null){ relatedId = accGrpMap.get(fcMap.get(id).Account__r.Parent.ParentId).get(j);}
                    
                    if(accGrpMap.get(fcMap.get(id).Account__r.parent.parent.parentId) != null){ relatedId = accGrpMap.get(fcMap.get(id).Account__r.parent.parent.parentId).get(j);}
                    
                    if(accGrpMap.get(fcMap.get(id).Account__r.parent.parent.parent.parentId) != null){ relatedId = accGrpMap.get(fcMap.get(id).Account__r.parent.parent.parent.parentId).get(j);}
                    
                    if(accGrpMap.get(fcMap.get(id).Account__r.parent.parent.parent.parent.parentid) != null){ relatedId = accGrpMap.get(fcMap.get(id).Account__r.parent.parent.parent.parent.parentid).get(j);}                   
                }
                else if(!acctGroupIdMap.isEmpty()){ relatedId = acctGroupIdMap.get(j);}
                if(relatedId != null){  FcShares.add(new SFDC_MDF_Claim__Share(AccessLevel = 'Edit', ParentId = id, UserOrGroupId = relatedId)); }               
            }
        }
        //}   
        if(FcShares.size() > 0){ insert FcShares;
        }  // Changed code 
        /**********************************************************************/
        // For Fund Budgets
        /**********************************************************************/
        List<SFDC_Budget__Share> FbShares = new List<SFDC_Budget__Share>();
        String FbQry = 'select id, Account__c, Account__r.ParentId, Account__r.Parent.ParentId,' + 
                            ' Account__r.parent.parent.parentId, Account__r.parent.parent.parent.parentId,' +
                            ' Account__r.parent.parent.parent.parent.parentid from SFDC_Budget__c';
        cond1 = GroupSharingHelper.join(accChilds, ',', '\'');
        if(cond1 == ''){
            whereCls = '';
        }else{  whereCls = ' where Account__c in (' + cond1 + ')';}
        cond2 = GroupSharingHelper.join(accChilds1, ',', '\'');
        if(cond2 != ''){
            if(whereCls != ''){ whereCls = whereCls + ' or Account__c in (' + cond2 + ')';
            }else{
                whereCls = ' where Account__c in ('+ cond2 + ')';
            }
        }
        FbQry = FbQry + whereCls;
                                    
        List<SFDC_Budget__c> fbs = Database.query(FbQry);                                         
        Map<Id, SFDC_Budget__c> fbMap = new Map<Id, SFDC_Budget__c>(fbs);                                           
        parents = new List<Id>();
        Map<Id,List<Id>> fbParentMap = new Map<Id,List<Id>>();
        isPartnerPortal = false;
        //if(settings != null){
        //    isPartnerPortal = settings.is_Partner_Portal_Enabled__c;
        //}
        //if(isPartnerPortal){
        for(Id i : fbMap.keySet()){
            Account parent = fbMap.get(i).Account__r.parent;  
            if(parent != null){  parents.add(parent.Id);  while(parent.ParentId != null){ parents.add(parent.ParentId); if(parent.Parent != null){ parent = parent.Parent; } } }
            fbParentMap.put(i,parents);
        }
        for(Id id : fbParentMap.keySet()){
            Id relatedId;
            for(Id j : fbParentMap.get(id)){
                if(!accGrpMap.isEmpty()){                   
                    if(accGrpMap.get(fbMap.get(id).Account__c) != null){ relatedId = accGrpMap.get(fbMap.get(id).Account__c).get(j); }
                    if(accGrpMap.get(fbMap.get(id).Account__r.ParentId) != null){ relatedId = accGrpMap.get(fbMap.get(id).Account__r.ParentId).get(j); }
                    if(accGrpMap.get(fbMap.get(id).Account__r.Parent.ParentId) != null){ relatedId = accGrpMap.get(fbMap.get(id).Account__r.Parent.ParentId).get(j);}
                    
                    if(accGrpMap.get(fbMap.get(id).Account__r.parent.parent.parentId) != null){ relatedId = accGrpMap.get(fbMap.get(id).Account__r.parent.parent.parentId).get(j); }
                    
                    if(accGrpMap.get(fbMap.get(id).Account__r.parent.parent.parent.parentId) != null){ relatedId = accGrpMap.get(fbMap.get(id).Account__r.parent.parent.parent.parentId).get(j); }
                    
                    if(accGrpMap.get(fbMap.get(id).Account__r.parent.parent.parent.parent.parentid) != null){ relatedId = accGrpMap.get(fbMap.get(id).Account__r.parent.parent.parent.parent.parentid).get(j);}                   
                }
                else if(!acctGroupIdMap.isEmpty()){ relatedId = acctGroupIdMap.get(j); }
                if(relatedId != null){ FbShares.add(new SFDC_Budget__Share(AccessLevel = 'Edit', ParentId = id, UserOrGroupId = relatedId)); }               
            }
        }
        //}   
        if(FbShares.size() > 0){ insert FbShares; }  // Changed code 
        /**********************************************************************/
        String customField_r;
        if(customField.indexOf('__c') != -1){ customField_r = customField.substring(0, customField.length()-1)+ 'r';
        }else{
            customField_r = customField.substring(0, customField.indexOf('Id'));
        }   
        System.debug('####customField ='+customField );
        System.debug('####customField_r ='+customField_r );
        
        String oppQry = 'select id,  '+ customField +', partnerAccountId,'+ customField_r +'.ParentId, ' + customField_r +'.Parent.ParentId,' + 
                            customField_r +'.parent.parent.parentId, '+ customField_r + '.parent.parent.parent.parentId,' +
                            customField_r + '.parent.parent.parent.parent.parentid from Opportunity';
        /*String oppQry = 'select id,  '+ customField +', partnerAccountId, PartnerAccount.ParentId, partnerAccount.Parent.ParentId,' + 
                            ' PartnerAccount.parent.parent.parentId, partnerAccount.parent.parent.parent.parentId,' +
                            ' partneraccount.parent.parent.parent.parent.parentid from Opportunity'; */
        
        String whereCls1 ;
        String oppcond1 = GroupSharingHelper.join(accChilds, ',', '\'');
        if(cond1 == ''){
            whereCls1 = '';
        }else{  whereCls1 = ' where '+ customField +' in (' + oppcond1 + ')'; } 
        String oppcond2 = GroupSharingHelper.join(accChilds1, ',', '\'');
        if(cond2 != ''){
            if(whereCls1 != ''){  whereCls1 = whereCls1 + ' or '+ customField +' in (' + oppcond2 + ')';
            }else{
                whereCls1 = ' where '+ customField +' in ('+ oppcond2 + ')';
            }                     // 
        }
        oppQry = oppQry + whereCls1;
        system.debug('Opp Query = ' + oppQry);
        /*String oppQry = 'select id, partnerAccountId, PartnerAccount.ParentId, partnerAccount.Parent.ParentId,' + 
                        ' PartnerAccount.parent.parent.parentId, partnerAccount.parent.parent.parent.parentId,' +
                        ' partneraccount.parent.parent.parent.parent.parentid ' +
                        ' from Opportunity where partnerAccountId in (' + cond1 + ')' + //GroupSharingHelper.join(accChilds, ',', '\'')
                        ' or partnerAccountId in (' + cond2 + ')' ; //GroupSharingHelper.join(accChilds1, ',','\'')*/
        if(GroupSharingHelper.ISTEST){ oppQry = oppQry + ' limit 10'; }                                           
        List<Opportunity> opps = Database.query(oppQry);
        System.debug('#opps#'+opps);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(opps);
/*      Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([select id, partnerAccountId, PartnerAccount.ParentId, partnerAccount.Parent.ParentId, 
                                                    PartnerAccount.parent.parent.parentId, partnerAccount.parent.parent.parent.parentId,
                                                    partneraccount.parent.parent.parent.parent.parentid
                                                    from Opportunity where partnerAccountId in :accChilds or partnerAccountId in :accChilds1]);*/
        List<Id> oparents = new List<Id>();
        Map<Id,List<Id>> oppParentMap = new Map<Id,List<Id>>();
        String sParent= customField_r + '.parent';
        isPartnerPortal = true;
        Map<Id,Id> oppAccMap = new Map<Id,Id>();
        if(isPartnerPortal){
        System.debug('#just inside partnerportal#');
            for(Id i : oppMap.keySet()){
                System.debug('#inside partnerportal#');
                SObject sObj = oppMap.get(i);
                //SObject nameObj = sObj.getSObject(sParent);                          
               Account parent ;//= (Account)sObj.getSObject(sParent); //nameObj;
                String partnerOwner =  (String) sObj.get(customField);
                System.debug('partner owner account = ' + partnerOwner);
                oppAccMap.put(i,partnerOwner);
          /*      if(parent != null){      
                    oparents.add(parent.Id);     
                    while(parent.ParentId != null){
                        oparents.add(parent.ParentId);
                        if(parent.Parent != null){
                            parent = parent.Parent;
                        }
                    }
                } */
             //   oppParentMap.put(i,oparents);
            }
            GroupSharingHelper.getAccParentMap(oppAccMap.values(),true);
            Map<Id,String> opportunityAccMap = new Map<Id, String>();
            for(Opportunity o : oppMap.values()){
                if(customField != null){
                    for(String s : customField.split(',')){ if(GroupSharingHelper.parentAccMap.containsKey((Id)o.get(s.trim()))){ String p = GroupSharingHelper.parentAccMap.get((Id)o.get(s.trim())); if(opportunityAccMap.containsKey(o.id)){ p = p + ',' + opportunityAccMap.get(o.Id); } opportunityAccMap.put(o.Id, p); }} }
            }
        if(!opportunityAccMap.isEmpty()){
            List<String> pIds = new List<String>();
            for(String s : opportunityAccMap.values()){ if(!s.equals('') || s != null){ pIds.addAll(s.split(',')); }}
            Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(pIds, 'Partner');
            System.debug('accountIdUserRoleIdMap = ' + accountIdUserRoleIdMap);
            Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
            System.debug('gMap = ' + gMap);
            //changes this line as there was a bug in MTV
            //GroupSharing.createOppShares(opportunityAccMap,accountIdUserRoleIdMap,gMap);
            GroupSharing.createOppShares(opportunityAccMap,accountIdUserRoleIdMap,gMapMTV);
        }
        }
        /*System.debug('##oShares.size()##'+oShares.size());
        if (oShares.size() > 0){
            insert oShares;
        }*/       

        //added for case support
/*      Map<Id, Case> caseMap = new Map<Id, Case>([select id, AccountId, Account.ParentId, Account.Parent.ParentId, 
                                                    Account.parent.parent.parentId, Account.parent.parent.parent.parentId,
                                                    account.parent.parent.parent.parent.parentid
                                                    from Case where AccountId in :accChilds or AccountId in :accChilds1]);
        List<Id> cparents = new List<Id>();
        Map<Id,List<Id>> caseParentMap = new Map<Id,List<Id>>();
        for(Id i : caseMap.keySet()){
            Account parent = caseMap.get(i).Account.parent; 
            if(parent != null){ 
                cparents.add(parent.Id);    
                //added by Ankita on 4/14/2010 to handle more than 5 levels of hierarchy
                try{  
                while(parent.ParentId != null){
                    cparents.add(parent.ParentId);
                    if(parent.Parent != null){
                        parent = parent.Parent;
                    }
                }
                }catch(Exception e){
                    System.debug('Exception in getting parents: ' + e.getMessage());
                    System.debug('');
                    Account a = [select id, parentid, Parent.ParentId, parent.Parent.ParentId 
                                from Account 
                                where id = :parent.ParentId];
                    Account prt = parent;               
                    while(prt.ParentId != null){
                        cparents.add(prt.ParentId);
                        if(prt.Parent != null){
                            prt = prt.Parent;
                        }
                    }
                }
            }
            caseParentMap.put(i,cparents);
        }
        for(Id id : caseParentMap.keySet()){
            Id relatedId;
            for(Id j : caseParentMap.get(id)){
                if(!accGrpMap.isEmpty()){                   
                    if(accGrpMap.get(caseMap.get(id).AccountId) != null){
                        relatedId = accGrpMap.get(caseMap.get(id).AccountId).get(j);
                    }
                    if(accGrpMap.get(caseMap.get(id).Account.ParentId) != null){
                        relatedId = accGrpMap.get(caseMap.get(id).Account.ParentId).get(j); 
                    }
                    if(accGrpMap.get(caseMap.get(id).Account.Parent.ParentId) != null){
                        relatedId = accGrpMap.get(caseMap.get(id).Account.Parent.ParentId).get(j);
                    }
                    
                    if(accGrpMap.get(caseMap.get(id).Account.parent.parent.parentId) != null){
                        relatedId = accGrpMap.get(caseMap.get(id).Account.parent.parent.parentId).get(j);
                    }
                    
                    if(accGrpMap.get(caseMap.get(id).Account.parent.parent.parent.parentId) != null){
                        relatedId = accGrpMap.get(caseMap.get(id).Account.parent.parent.parent.parentId).get(j);
                    }
                    
                    if(accGrpMap.get(caseMap.get(id).account.parent.parent.parent.parent.parentid) != null){
                        relatedId = accGrpMap.get(caseMap.get(id).account.parent.parent.parent.parent.parentid).get(j);
                    }                   
                }
                else if(!acctGroupIdMap.isEmpty()){
                    relatedId = acctGroupIdMap.get(j);
                }
                if(relatedId != null){                  
                    if (cShares.size() < 1000){
                        cShares.add(new CaseShare(CaseAccessLevel = 'Edit', CaseId = id, UserOrGroupId = relatedId));   
                    }
                    else{
                        insert cShares;
                        cShares.clear();
                        cShares.add(new CaseShare(CaseAccessLevel = 'Edit', CaseId = id, UserOrGroupId = relatedId));   
                    }
                    
                }               
            }
        }   
        if(cShares.size() > 0){
            insert cShares;
        }*/ 
    }   
    
    @future
    public static void removeCaseShares(Set<Id> caseIds,List<Id> gIds){
        List<CaseShare> cShares = new List<CaseShare>();
        for(CaseShare cs : [select id from CaseShare where caseId in :caseIds and rowCause = 'Manual' and UserOrGroupId in :gids for update ]){ cShares.add(cs); }
        if(cShares.size() > 0){ delete cShares; }
    }

    //Commenting for SFDC-948, as this logic was getting called in each alternate update and was removing shares
    //@future
    //public static void removeOpportunityShares(Set<Id> oppIds,List<Id> gIds){
    //    List<OpportunityShare> cShares = new List<OpportunityShare>();
    //    for(opportunityShare cs : [select id from OpportunityShare where OpportunityId in :oppIds and rowCause = 'Manual' and UserOrGroupId in :gids for update ]){// 
    //        if (cShares.size() < 1000){
    //            cShares.add(cs);
    //        }
    //        else{
    //            delete cShares;
    //            cShares.clear();
    //            cShares.add(cs);
    //        }
    //    }
    //    if(cShares.size() > 0){
    //        delete cShares;
    //    }
        
    //}
    public static void accountShareManagementTrigger(Account[] triggerNew, Map<Id, Account> triggerOldMap)
    {
    	if(!accountShareManagementTriggerFirstRunFlag) return;
	    Map<Id,Id> accParentMap = new Map<Id, Id>();
	    Map<Id,Id> oldParentMap = new Map<Id,Id>();
	    List<Id> accIds = new List<Id>();
	    List<Id> assAccIds = new List<Id>();
	    Map<Id,Id> oppMap = new Map<Id,Id>();
	    Map<Id,Id> leadMap = new Map<Id,Id>();
	    Map<Id,String> leadPMap = new Map<Id,String>();
	    Map<Id,String> oppPMap = new Map<Id,String>();
	    List<Id> ownerChanged = new List<Id>();
	    
	    //Need to use from Custom Setting - flag to check if all users belonging to case -> account who should have access to the case
	    Boolean shareWithThisAcc = false; 
	    
	    //disable this trigger if org where installed is not interested in Parent Hierarchy
	    
	    //check if account hierarchy is enabled
	    Configuration config = new Configuration();
	    Boolean accountHierarchyEnabled = config.isAccountHierarchyEnabled();
	    System.debug('Account Hierarchy turned : ' + accountHierarchyEnabled);
	    
	    // Need to add return if not enable from opp - line( 14-16 )
	    
	    for(Account a : triggerNew){
	    	if(a.IsPartner==True)
	        	{
	        		accIds.add(a.Id);
	        	}
	    }
	    
	    // No need to check accountHierarchyEnabled
	    // Need to use update and insert in one loop
	    if(Trigger.isInsert && accountHierarchyEnabled){
	        for(Account a : triggerNew){
	        	if(a.IsPartner==True) { if(a.ParentId != null){ accParentMap.put(a.Id, a.ParentId); }}
	        }
	    }
	    //Need to handle if any account which is not partner enable in future   
	    if(Trigger.isUpdate){
	        for(Account a : triggerNew){
	        	if(a.IsPartner==True)
	        	{
		            if(accountHierarchyEnabled && ( (triggerOldMap.get(a.id).ParentId != a.ParentId))){//((trigger.oldMap.get(a.id).ParentId ==null) && (a.ParentId != null))||
		                if(a.ParentId != null){ accParentMap.put(a.Id, a.ParentId);
		                }
		                if(triggerOldMap.get(a.Id).ParentId != null){ oldParentMap.put(a.Id, triggerOldMap.get(a.Id).ParentId);
		                }
		            }
		            if((triggerOldMap.get(a.id).OwnerId != a.OwnerId)){
		                if(accountHierarchyEnabled && a.ParentId != null){ accParentMap.put(a.Id, a.ParentId);} ownerChanged.add(a.Id);
		            }
	        	}
	        }
	    }
	    
	    if(!oldParentMap.isEmpty()){ GroupSharingHelper.getOldAccParentMap(oldParentMap,shareWithThisAcc);  Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(GroupSharingHelper.oldParentIds, 'Partner'); Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values()); GroupSharing.calcChildShares(GroupSharingHelper.oldParentAccMap, accountIdUserRoleIdMap, gMap, 'remove'); }
	    System.debug('Trigger-AccountShareManagement --accParentMap='+ accParentMap);
	    if(!accParentMap.isEmpty()){ GroupSharingHelper.getAccParentMap(accIds,shareWithThisAcc); Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(GroupSharingHelper.parentIds, 'Partner'); Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values()); GroupSharing.calcChildShares(GroupSharingHelper.parentAccMap, accountIdUserRoleIdMap, gMap, 'add');
	    }
	    //need to use code is for record associations as in opp
	    if(!ownerChanged.isEmpty()){
	        List<RecordAssociation__c> assacc = new List<RecordAssociation__c>([Select Associated_Account__c, Account__c from RecordAssociation__c where Account__c in :ownerChanged]);
	        for(RecordAssociation__c r : assacc){ assAccIds.add(r.Associated_Account__c); }
	        //need to use code is for object associations as in opp
	        AccountAssociationHelper helper = new AccountAssociationHelper(assacc);
	        Map<Id,Id> accountIdUserRoleIdMap1 = GroupSharingHelper.getRoles(assAccIds, 'Partner'); Map<Id,Id> gMap1 = GroupSharingHelper.getGroups(accountIdUserRoleIdMap1.values());
	        AccountAssociationHelper.createShares(ownerChanged, accountIdUserRoleIdMap1, gMap1, helper.getGroupIds(), helper.getAcctParentMap()); 
	    }
    	accountShareManagementTriggerFirstRunFlag = false;
    }
}