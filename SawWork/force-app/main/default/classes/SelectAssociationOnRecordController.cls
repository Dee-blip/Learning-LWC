public with sharing class SelectAssociationOnRecordController {
      //class for adding a select check box against each task in VF page 
      public class preferredAccountWithSelect {
          public RecordAssociation__c pAccount { get; private set; }
          public boolean selected { get; set; }
          public boolean primary { get; set; }          
          public preferredAccountWithSelect(RecordAssociation__c p, boolean s, boolean prime) {
            pAccount  = p;
            selected = s;
            primary = prime; 
          }  
      } 
      public String errorMsg {get; private set;}
      //if account associations already exist, this map keeps the list of existing Distributor ids and the POCs 
      Map<Id,Object_Association__c> ExistingDistributorMap = new Map<Id,Object_Association__c> () ;
      //list of all distributors
      Map<Id,RecordAssociation__c> DistributorMap; 
      Id leadId, oppId;
      String owner;
      String accountId = '';
      Lead l = new Lead();
      Opportunity opp = new Opportunity();
      public String recordName { get; private set; } 
      public String accountName { get; private set; }     
      //the actual Distributor list that is returned to VF page 
      public List<preferredAccountWithSelect> preferredAccountWithSelects; 
      
      public List<preferredAccountWithSelect> getpreferredAccountWithSelects() {    
           return preferredAccountWithSelects; 
      }
        
     
      public SelectAssociationOnRecordController() {
       
           //the object in question 
           if(ApexPages.currentPage().getParameters().containsKey('leadId') && !ApexPages.currentPage().getParameters().get('leadId').equals('')){
            leadId = ApexPages.currentPage().getParameters().get('leadId');
           }else if(ApexPages.currentPage().getParameters().containsKey('oppId') && !ApexPages.currentPage().getParameters().get('oppId').equals('')){
            oppId = ApexPages.currentPage().getParameters().get('oppId');
           }
        Object_Association__c[] existingDistributors;   
        errorMsg = '';
        accountId = '';
        User u1 = new User();
         if(leadId != null)  {
               //do distributors already exist? 
              existingDistributors =  [select Associated_Account__c, Associated_Account__r.Name, LeadId__c  from Object_Association__c where
                                                                              LeadId__c = :leadId ORDER BY Name];           
                                                                              
              Lead l = [Select OwnerId, Name from Lead where id = :leadId];
              recordName = l.Name;            
              Id ownerId = l.OwnerId;
              owner = (String)ownerId;
              if(owner.startsWith('005')){
                List<User> uList = [select Contact.AccountId from User where id = :ownerId];
                if(!uList.isEmpty()){
                    u1 = uList[0];
                }
              }
              if(owner.startsWith('00G')){
              }
               //put them in a map to retrive them later. 
               for (Object_Association__c pd: existingDistributors) {
                    ExistingDistributorMap.put(pd.Associated_Account__c, pd);
               } 
         }else if(oppId != null){
              existingDistributors =  [select Associated_Account__c, Associated_Account__r.Name, OpportunityId__c  from Object_Association__c where
                                                                              OpportunityId__c = :oppId];       //, Account_Role__c, Account__c
              Opportunity o = [Select OwnerId, Name from Opportunity where id = :oppId];
              Id ownerId = o.OwnerId;
              recordName = o.Name;
              owner = (String)ownerId;
              if(owner.startsWith('005')){
                u1 = [select Contact.AccountId from User where id = :ownerId];
              }   
                                                                             
               //put them in a map to retrive them later. 
               for (Object_Association__c pd:existingDistributors) {
                    ExistingDistributorMap.put(pd.Associated_Account__c, pd);
               }    
          }
           accountId = (String)u1.Contact.AccountId;                    
           if(accountId != null){
                Account a = [Select id, Name from Account where id = :u1.Contact.AccountId];
                accountName = a.Name;               
           }              
           
           //map can't sorted by name, so create another list                                               
           RecordAssociation__c[] DistributorList = [select id, Primary__c, Associated_Account__r.Name, Name, Account_Role__c, Account__c from 
                                                         RecordAssociation__c where Account__c = :u1.Contact.AccountId ORDER BY Name];      //and LeadId__c = null and OpportunityId__c = null
           
           if(DistributorList.isEmpty()){
                if(accountId == null){
                    errorMsg = 'The record is not owned by a partner user so no association can be made';
                }
                else errorMsg = 'No Record Associations can be created as there are no Account Associations for the record owners account (' + accountName + ')';
           }
           DistributorMap = new Map<Id,RecordAssociation__c> (DistributorList);         
           Set<Id> ExistingDistributorSet = ExistingDistributorMap.KeySet();
           preferredAccountWithSelects = new List<preferredAccountWithSelect>();
           Set<Id> assoAccIds = new Set<Id>();
           for (RecordAssociation__c d:DistributorList) {
                assoAccIds.add(d.Associated_Account__c);
           }
            Map<Id, Id> accountIdUserRoleIdMap = new Map<Id, Id>();
            String criteria = GroupSharingHelper.join(assoAccIds, ',', '\'');
            if(criteria == ''){
                criteria = '\'\'';
            } 
            String pQuery = 'select id, PortalAccountId from UserRole where PortalAccountId in (' + criteria + ')' +
                            ' and Name like \'%Executive\' and PortalType = \'Partner\'';
            System.debug('pQuery = ' + pQuery);
            List<UserRole> roles = Database.query(pQuery);              
           for(UserRole uRole : roles){
                accountIdUserRoleIdMap.put(uRole.PortalAccountId, uRole.Id);
            }
           
           for (RecordAssociation__c d:DistributorList) {
              //whether Distributor is selected or not depends on whether it was one of existingDistributor
              preferredAccountWithSelect pd;
              if (ExistingDistributorSet.Contains(d.Associated_Account__c)) {   
                  //also check if it was primary 
                  pd = new preferredAccountWithSelect(d,true,DistributorMap.get(d.id).Primary__c);
              } else {
                if(accountIdUserRoleIdMap.containsKey(d.Associated_Account__c)){
                  pd = new preferredAccountWithSelect(d,false,false);
                }
              }
              preferredAccountWithSelects.add(pd);
           }          
      }       

      public PageReference Save() {

           Object_Association__c[]  DistributorsToAdd = new Object_Association__c[0];  
           Object_Association__c[]  DistributorsToUpdate = new Object_Association__c[0];  
           Object_Association__c[]  DistributorsToDelete = new Object_Association__c[0];  
           Set<Id> ExistingDistributors = ExistingDistributorMap.KeySet();
           String multiSelectPreferredDistributor;//string for multi-select box
           for (preferredAccountWithSelect p: preferredAccountWithSelects) {
               if (p.selected) {
                  if (ExistingDistributors.contains(p.pAccount.Associated_Account__c)) {                     
                     //this Distributor was selected, and exists in existing list of distributors, update the primary flag.
                      Object_Association__c pdToUpdate = ExistingDistributorMap.get(p.pAccount.Associated_Account__c); 
                      DistributorsToUpdate.add(pdToUpdate);
                  } else {
                      //a new distributor 
                      Object_Association__c pdToAdd = new Object_Association__c(Associated_Account__c = p.pAccount.Associated_Account__c, LeadId__c = leadId, OpportunityId__c = oppId,
                                                                                Primary__c = p.Primary);         
                      DistributorsToAdd.add(pdToAdd);
                  }                    
               } else if(ExistingDistributors.contains(p.pAccount.Associated_Account__c)) {
                  //this Distributor was de-selected and was there in existing preferred distributor, delete it. 
                  Object_Association__c pdToDelete = ExistingDistributorMap.get(p.pAccount.Associated_Account__c); 
                  DistributorsToDelete.add(pdToDelete);
               } 
           } 
           insert DistributorsToAdd;
           delete DistributorsToDelete;
           update DistributorsToUpdate;
           
          
           //back to Account page 
           if(leadId != null){
            PageReference AccountPage = new PageReference('/' + leadId);
            return AccountPage;
           }else if(oppId != null){
            PageReference AccountPage = new PageReference('/' + oppId);
            return AccountPage;
           }
           return null;
       }


       public pageReference uncheckPrimaryIfChecked() {
        
            for (preferredAccountWithSelect p: preferredAccountWithSelects) {
               if (!p.selected && p.primary) {
                  p.primary = false;
               }
            }
            return null;
       }        
 
       public PageReference Cancel() {
           //back to Account page 
           if(leadId != null){
            PageReference AccountPage = new PageReference('/' + leadId);
            return AccountPage;
           }else if(oppId != null){
            PageReference AccountPage = new PageReference('/' + oppId);
            return AccountPage;
           }
           return null;
       } 
       
        public PageReference addPreferredAccountAssociation(){
            User u = new User();
            List<Object_Association__c> existingObjAssoc = new List<Object_Association__c>();
            Id ownerId;
            if(leadId != null){
                Lead l = [Select OwnerId from Lead where id = :leadId];
                existingObjAssoc = [Select Associated_Account__c from Object_Association__c where LeadId__c = :leadId];
                ownerId = l.OwnerId;
                owner = (String)ownerId;
                if(owner.startsWith('005')){
                    u = [select Contact.AccountId from User where id = :ownerId];
                }
            }
            if(oppId != null){
                Opportunity o = [Select OwnerId from Opportunity where id = :oppId];
                existingObjAssoc = [Select Associated_Account__c from Object_Association__c where OpportunityId__c = :oppId];
                ownerId = o.OwnerId;
                owner = (String)ownerId;
                if(owner.startsWith('005')){
                    u = [select Contact.AccountId from User where id = :ownerId];
                }  
            }
            
            RecordAssociation__c assoc;
            
            try{
            assoc = [select id, Primary__c, Associated_Account__c, Associated_Account__r.Name, Name, Account_Role__c, Account__c 
                                            from RecordAssociation__c 
                                            where Account__c = :u.Contact.AccountId and                                              
                                            Primary__c = true 
                                            ORDER BY Name];             
            for(Object_Association__c oa : existingObjAssoc){
                if(assoc.Associated_Account__c == oa.Associated_Account__c){
                    if(leadId != null){
                        return new PageReference('/'+leadid);
                    }else if(oppId != null){
                        return new PageReference('/'+oppid);
                    }
                }
            }
            
            Object_Association__c prefToAdd = new Object_Association__c(Associated_Account__c = assoc.Associated_Account__c,
                                                                        LeadId__c = leadId, OpportunityId__c = oppId);
            MTVUtil.addAssoc(new List<Object_Association__c>{prefToAdd});
            //insert prefToAdd;                                                     
            }catch(QueryException e){
                System.debug('Query Exception in getting primary acc association : '+e.getMessage());
            }
            if(leadId != null){
                return new PageReference('/'+leadid);
            }else if(oppId != null){
                return new PageReference('/'+oppid);
            }
            return null;
        }  
}