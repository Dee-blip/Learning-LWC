public with sharing class P2P_AccountAssociationController {
	public Account account { get; private set; } 
	private Integer nextId = 0; 
	private String selectedId;
	public List<ConditionRow> conditions { get; private set; } 
	private List<RecordAssociation__c> deleted = new List<RecordAssociation__c>();
	//public List<Account> assocAccts {get; private set;} 
	public String encoded {get; private set;}
	public Boolean error {get; private set;}
	public String errorMsg {get; private set;}

	//custom lookup
	private List<SObject> sObjects;
	private String sObjectType { get; set; }
	public List<SelectOption> matchingaccounts {get; set;}
	public Boolean multiple { get; set; }
	private String returnUrl;
	private static final String TAB_URL_SUFFIX = '/o';
	
	public String templateId { get; set; }
	
	
	public P2P_AccountAssociationController(){
		
	}
	
	public P2P_AccountAssociationController(ApexPages.StandardController controller) {
		String accAssId = ApexPages.currentPage().getParameters().get('id');
		if (accAssId == null) {
			RecordAssociation__c accAss = new RecordAssociation__c();
			accAss = (RecordAssociation__c) controller.getRecord();
			this.account = [Select Id, Name from Account where Id = :accAss.Account__c];
		} else {
			RecordAssociation__c accAss = [Select Associated_Account__c, Account__c from RecordAssociation__c where Id = :accAssId ];
			this.account = [SELECT Id, Name FROM Account WHERE Id = :accAss.Account__c];
		}
		conditions = new List<ConditionRow>();
		String url = '/apex/selectAccount?fieldName1={!$Component.assAcc}&fieldName2={!$Component.assAcc_Id}';
		encoded = url; 
	}
			
	public PageReference onLoad() {
		for (RecordAssociation__c association : [SELECT primary__c, Account__c, Associated_Account__c, Associated_Account__r.Name, Account_Role__c FROM RecordAssociation__c WHERE Account__c = :account.Id]) {
			nextId++;
			conditions.add(new ConditionRow(String.valueOf(nextId), association, true));
		}
		
		if (conditions.size() == 0) {
			nextId++;
			conditions.add(new ConditionRow(String.valueOf(nextId), new RecordAssociation__c(), false));
		}		
		return null;
	}	
	
	public PageReference onAddCondition() {
		String selectedId = ApexPages.currentPage().getParameters().get('selectedId');
		if (selectedId != null) {
			for (Integer i=0;i<conditions.size();i++) {
				ConditionRow row = conditions.get(i);
				if (row.getId().equals(selectedId)) {
					nextId++;
					if (i == (conditions.size() - 1)) {
						conditions.add(new ConditionRow(String.valueOf(nextId), new RecordAssociation__c(), false));
					} else {
						conditions.add(i + 1, new ConditionRow(String.valueOf(nextId), new RecordAssociation__c(), false));
					}
					return null;
				}
			}
		}
		return null;
	}
	
	public PageReference onRemoveCondition() {
		String selectedId = ApexPages.currentPage().getParameters().get('selectedId');
		if (selectedId != null) {
			for (Integer i=0;i<conditions.size();i++) {
				ConditionRow row = conditions.get(i);
				if (row.getId().equals(selectedId)) {
					conditions.remove(i);
					if (row.getCondition().Id != null) {
						deleted.add(row.getCondition());
					}
					return null;
				}
			}
		}
		return null;
	}
/*	
	public PageReference selectAccount(){
		assocAccts = [select id, Name, type, billingstate, billingCountry from Account where Association_Account__c = true ORDER BY Name];
		return null;
	}
*/	 
	
	public PageReference onSave() {
		delete deleted;
		try {
			List<RecordAssociation__c> existingAssocs 
				= [Select Associated_Account__c, Account__c, Primary__c, Account_Role__c 
					from RecordAssociation__c where Account__c = :account.Id];
			
			Set<Id> existingAssocAccIds = new Set<Id>();
			Map<Id,String> assocAccToRole = new Map<Id,String>();
			Map<Id,Id> accToAssocAcc = new Map<Id,Id>();
			Map<Id,Boolean> assocAccToPref = new Map<Id,Boolean>();
			Map<String,Integer> existingAssocCount = new Map<String,Integer>();
			
			Set<Id> allAssociatedAccounts = new Set<Id>();
			
			if(!existingAssocs.isEmpty()){
				for(RecordAssociation__c r : existingAssocs){
					existingAssocAccIds.add(r.Associated_Account__c);
					assocAccToRole.put(r.Associated_Account__c, r.Account_Role__c);
					assocAccToPref.put(r.Associated_Account__c, r.Primary__c);
				}
			}			
			
			List<RecordAssociation__c> batch = new List<RecordAssociation__c>();
			List<RecordAssociation__c> updateBatch = new List<RecordAssociation__c>();
			List<RecordAssociation__c> delBatch = new List<RecordAssociation__c>();
			Map<Id,RecordAssociation__c> newAssocMap = new Map<Id,RecordAssociation__c>();
			
			System.debug('row size =>' + conditions.size());
			for (ConditionRow row : conditions) {
				RecordAssociation__c cond = row.getCondition();	
				if (cond.Id == null) {
					cond.Account__c = account.Id;
				}

				//validations
				if (cond.Associated_Account__c == null) {
					error=true;
					errorMsg = 'Please select an Associated Account'; 					
					return null;
				}
				
				

				if (allAssociatedAccounts.contains(cond.Associated_Account__c)) {
					error=true;
					errorMsg = 'Cannot add duplicate Account Associations'; 					
					return null;
				}	 			
				allAssociatedAccounts.add(cond.Associated_Account__c);
				
				if(cond.Associated_Account__c == cond.Account__c){
					error=true;
					errorMsg = 'You cannot create an Account Association with your own account record'; 					
					return null;
				}
				
				Boolean isUpdateRole = false;
				Boolean isUpdate = false;
				newAssocMap.put(cond.Associated_Account__c, cond);
				
				if(existingAssocAccIds.contains(cond.Associated_Account__c)){
					//update if role is changed
					if(assocAccToRole.get(cond.Associated_Account__c) != null){
						if(!assocAccToRole.get(cond.Associated_Account__c).equals(cond.Account_Role__c)){
							batch.add(cond);
							isUpdateRole = true;
						}
					}else if(cond.Account_Role__c != null){
							batch.add(cond);
							isUpdateRole = true;
					}	
					//update if preferred is changed
					if(isUpdateRole){
						if(assocAccToPref.get(cond.Associated_Account__c) != cond.Primary__c){							
							batch.set((batch.size()-1), cond);							
						}	
					} else if(assocAccToPref.get(cond.Associated_Account__c) != cond.Primary__c){
							batch.add(cond);
					}			
				}							
				else{
					batch.add(cond);
				}					
			}
			
			//If Associated Account is updated, error
			for(RecordAssociation__c ex: existingAssocs){
				if(!newAssocMap.containsKey(ex.Associated_Account__c)){
					RecordAssociation__c toDel = [Select Id, Associated_Account__c from RecordAssociation__c where Associated_Account__c = :ex.Account__c and Account__c = :ex.Associated_Account__c];
					delBatch.add(toDel);				
				}
			}
			
			if(!delBatch.isEmpty()){
				error=true;
				errorMsg = 'The Associated Account field cannot be edited on existing records. Please delete the Account Association and add a new association record instead.'; 
				return null;
			}
			upsert batch;			
			
		}catch(Exception e){
			error=true;
			errorMsg = e.getMessage().substring(e.getMessage().indexOf('_EXCEPTION,')+11); 
			return null;
		}
		
		return new PageReference('/' + account.Id);
	}
	
	public PageReference onCancel() {
		return new PageReference('/' + account.Id);
	}

	public class LookupException extends Exception {}
	
	public class ConditionRow {
		private String id;
		private RecordAssociation__c condition;
		public Boolean hasRecord {get; set;}
		
		public ConditionRow(String id, RecordAssociation__c condition, Boolean hasRecord) {
			this.id = id;
			this.condition = condition;
			this.hasRecord = hasRecord;
		}
		
		public Boolean gethasRecord(){
			return hasRecord;
		}
		
		public String getId() {
			return id;
		}
		
		public RecordAssociation__c getCondition() {
			return condition;
		}
	}
}