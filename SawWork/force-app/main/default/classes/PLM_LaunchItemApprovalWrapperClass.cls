/**
 PLM_LaunchItemApprovalWrapperClass
 @author : Chandra Lohani(clohani@akamai.com)
 @Description : This class is used as a wrapper class to store launch item Approval record and information about it.
 
 @History : 
 
 Developer Name             Date             Description
 Chandra Lohani	          26-12-2012       Create this class for CR 1419337 
*/
public class PLM_LaunchItemApprovalWrapperClass {
	
	public Launch_Item_Approval__C teamMember{get;set;}
	public Id launchItemApprovalId{get;set;}
	public Boolean isChecked{get;set;}
	public Boolean isExisting{get;set;}
	public Integer index{get;set;}
	public Boolean isDeleted{get;set;}
	public Boolean isAttchmentExists{get;set;}
	public Boolean isChanged{get;set;}
	public String userName{get;set;} 
	public String userId{get;set;}
    public List<Launch_Item_Approval__c> func_div_StandingDelegation{get; set;}
    public PLM_LaunchItemApprovalWrapperClass(Launch_Item_Approval__c teamMember,Boolean isChecked,Boolean isExisting,Boolean isDeleted,Integer index, Id launchItemApprovalId)
    {
    	this.teamMember=teamMember;
    	this.isChecked=isChecked;
    	this.isExisting=isExisting;
    	this.isDeleted=isDeleted;
    	this.index=index;
    	this.isChanged=false;
    	this.launchItemApprovalId=launchItemApprovalId;
     }
     public PLM_LaunchItemApprovalWrapperClass(List<Launch_Item_Approval__c> func_div_StandingDelegation, Launch_Item_Approval__c teamMember,Boolean isChecked,Boolean isExisting,Boolean isDeleted,Integer index, Id launchItemApprovalId)
    {
    	this.func_div_StandingDelegation=func_div_StandingDelegation;
    	this.teamMember=teamMember;
    	this.isChecked=isChecked;
    	this.isExisting=isExisting;
    	this.isDeleted=isDeleted;
    	this.index=index;
    	this.isChanged=false;
    	this.launchItemApprovalId=launchItemApprovalId;
     }
     public PLM_LaunchItemApprovalWrapperClass()
     {
     	
     }
     public PLM_LaunchItemApprovalWrapperClass(Boolean isAttchmentExists)
     {
     	this.isAttchmentExists=isAttchmentExists;
     }

}