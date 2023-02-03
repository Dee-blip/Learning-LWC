public class ClosePlanDetailController {
    public Close_Plan__c cpObj{get;set;}
    public PageReference pageRef {get; set;}
    
    public ClosePlanDetailController(ApexPages.StandardController controller){
        cpObj = (Close_Plan__c)controller.getRecord();
        cpObj = [select Id,Name,Problem_Value_Statement__c,Agreed_to_Close_Date__c,Time_line_built_with_the_customer__c,Owner.Name,
                 Opportunity__r.Name,Approver_1__c,Approver_2__c,Approver_3__c,Approver_4__c,Approver_5__c,Approver_Availability_to_Sign__c,
                 Countersign_required__c,MAA__c,Proposal_address_painpoint__c,Uncovered_needs__c,POC_Date__c,Success_Criteria_Met__c,
                 Add_l_products_services_proposed__c,Upside_Potential__c,Sign_Date__c,PO_receipt_date__c,Partner_PO_receipt_date__c,
                 Compelling_Event__c,Services_Scoped__c,Pricing_accepted_customer__c,Pricing_approved_internal__c,Budget_confirmed__c,
                 Agreement_Prioritized_Procurement__c,Know_Procedures__c,Relationship_with_the_Business__c,Path_to_Reduce_PO_Time__c,
                 Credit_Check__c,Procurement_requisition_opened__c,PO_Required__c,Know_Procurement_Person__c,Procurement_Process__c,
                 Terms_Conditions__c,Approved_Vendor__c,Agreement_Prioritized_Legal__c,Available_for_meetings_to_expedite__c,
                 Legal_Process__c,Meeting_with_Econ_Buyer__c,Meeting_with_Champion__c,Meeting_with_Procurement__c,Meeting_with_Legal__c,
                 Meeting_with_Compliance__c,Meeting_with_IT__c,Meeting_with_C_Level__c,Kickoff_Meeting_1__c,Kickoff_Meeting_2__c,
                 Customer_has_OFs__c,OF_Match_Opportunity__c,CMG_review__c,Provisioning_Forms_completed__c,Rev_Alignment_Language__c,
                 Plan_for_detractors__c,Technical_obstacles__c,AKAM_Created_By__c,AKAM_Created_Date__c,AKAM_System__c,AKAM_Modified_By__c,
                 AKAM_Modified_Date__c,AKAM_Close_Plan_ID__c,Pricing_accepted_customer_comments__c,Pricing_approved_internal_comments__c 
                 from Close_Plan__c where id =: cpObj.Id];
        pageRef = new PageReference('/'+cpObj.Id);
    }
    
    public PageReference setRenderClosePlanPage() {
        System.PageReference ref = new System.PageReference('/apex/ClosePlanDetail');
        ref.getHeaders().put('content-disposition', 'attachment; filename='+cpObj.Name+'.pdf');
        return ref;
    }
    
    public PageReference refreshCurrentPage() {
        return pageRef;
    }
}