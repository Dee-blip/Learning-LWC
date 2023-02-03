/***
    PSA_SelectableObject
    @author Liz Ichihashi
    @Description : This Class is used as a helper object to hold on to an Sobject
                   as well as a boolean (checkbox).  The boolean can be used
                   as a "selected" checkbox, or an "expand" image in the custom
                   PSA Pages such as Create Project From Template, Update Project Timeline Status
                   and Project Contract Select.
                   
                   This class is used by other classes that require selectable or expandable object lists.
	@History
	--Developer		      --Date			--Change
	Liz Ichihashi    	  7/04/2013		Created the class.	   
*/
public with sharing class PSA_SelectableObject {

	@AuraEnabled
	public boolean selected {get; set;}
	@AuraEnabled
	public boolean disabled {get; set;}
	@AuraEnabled
	public boolean displayed {get; set;}
	@AuraEnabled
	public SObject obj {get; set;}
	@AuraEnabled
	public List<PSA_SelectableObject> childObjects {get; set;}
	@AuraEnabled 
	public Integer offset{get; set;}
	
	@AuraEnabled
	public boolean showBudgets {get; set;}
	@AuraEnabled
	public boolean showProjectProducts {get; set;}
	@AuraEnabled
	public boolean showMilestones {get; set;}
	@AuraEnabled
	public String plusImageDisplayStyle {get; set;}
	@AuraEnabled
	public String minusImageDisplayStyle {get; set;}
	@AuraEnabled
	public Integer rowNumber {get;set;}
	@AuraEnabled
	public Boolean childHasNext {get;set;}
	@AuraEnabled
	public Boolean childHasPrev {get;set;}
	@AuraEnabled
	public Boolean expanded{get;set;}
	@AuraEnabled
	public String hyperLink{get;set;}
	@AuraEnabled
	public String accountLink{get;set;}
	@AuraEnabled
	public String parentContractLink{get;set;}

	
	public PSA_SelectableObject() {
		selected = false;
		disabled = false;
		displayed = true;
		showBudgets = true;
		showProjectProducts = true;
		showMilestones = true;  
		plusImageDisplayStyle= '';
		minusImageDisplayStyle= 'display:none';
		offSet = 0 ;
	}
	
	@AuraEnabled
	public pse__Milestone__c getMilestone() {
		if (obj instanceOf pse__Milestone__c) {
			return (pse__Milestone__c) obj; 
		}
		return null;
	}

	@AuraEnabled
	public pse__Project_Task__c getProjectTask(){
		if(obj instanceOf pse__Project_Task__c){
			return (pse__Project_Task__c) obj;
		}
		return null;
	}
	
	@AuraEnabled
	public pse__Proj__c getProject() {
		if (obj instanceOf pse__Proj__c) {
			return (pse__Proj__c) obj; 
		}
		return null;
	}	
	
	@AuraEnabled
	public Merge_Contract_Header__c getContract() {
		if (obj instanceOf Merge_Contract_Header__c) {
			return (Merge_Contract_Header__c) obj; 
		}
		return null;
	}	
	
	@AuraEnabled
	public Merge_Contract_Detail__c getContractDetail() {
		if (obj instanceOf Merge_Contract_Detail__c) {
			return (Merge_Contract_Detail__c) obj; 
		}
		return null;
	}	
	
	@AuraEnabled
	public pse__Resource_Request__c getResourceRequest() {
		if (obj instanceOf pse__Resource_Request__c) {
			return (pse__Resource_Request__c) obj; 
		}
		return null;
	}	
	
	@AuraEnabled
	public pse__Budget__c getBudget() {
		if (obj instanceOf pse__Budget__c) {
			return (pse__Budget__c) obj; 
		}
		return null;
	}	

	@AuraEnabled
	public boolean getHasBudgets() {
		if (getProject() != null && showBudgets && getProject().pse__Budgets__r.size() > 0) {
			return true;
		} else {
			return false;
		}
	}
	  
	@AuraEnabled
	public boolean getHasMilestones() {
		if (getProject() != null && showMilestones && getProject().pse__Milestones__r.size() > 0) {
			return true;  
		} else {
			return false;
		}
	}
	
	@AuraEnabled
	public boolean getHasProjectProducts() {
		if (getProject() != null && showProjectProducts && getProject().pse__Project_Methodologies__r.size() > 0) {
			return true;
		} else {
			return false;
		}
	}
}