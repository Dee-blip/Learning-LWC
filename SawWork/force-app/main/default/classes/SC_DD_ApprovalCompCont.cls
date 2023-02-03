/****************************************************************************
* Class name          :   SC_DD_ApprovalCompCont.cls
* Author              :   Vishnu Vardhan
* Created             :   25-February-2020
* Purpose             :   Controller for ddApproval LWC component
* Test Class          :   SC_DD_DealDeskTest
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
* +getEntitledActions :   Get List Of Entitled Approval Permissions for Current User
* +performAction      :   Perform Action - Approve, Reject, Escalate
* -getApproverType    :   Determine role of Current User(Approver Type) for Current Deal - DDA, SLM/SLD, SLD1, SLD2, SPO
* -getActions         :   fetch entitled actions for "approverType", from custom setting
* -isGraztSpecialApprover :   check if Current User Special Approver for a given GRAZT
DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
April 6, 2020    Vishnu Vardhan   ESESP-3415      Fixes LWC error when controller return null value
May 11, 2020     Vishnu Vardhan   ESESP-3581      To enable special approvers at GRAZT level (in addition to SPOs)
June 18, 2020    Vishnu Vardhan   ESESP-3579      Approval Flow for Other Product Deals
June 18, 2020    Vishnu Vardhan   ESESP-4937      GRAZT changes
****************************************************************************/
public without sharing class SC_DD_ApprovalCompCont {
    
    public static final String DDA_PROFILE = 'Deal Desk';
    static final String WILD_CHAR = '*';
    static final List<String> apporvalStages = new List<String>{'DDA', 'SLM/SLD', 'SLD1', 'SLD2', 'SPO'};
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * Description         :   Wrapper Class
    ****************************************************************************/
    public class ApprovalPermissions {
        @auraEnabled 
        public String approverType;
        @auraEnabled 
        public List<String> entitlesdActions;
        public ApprovalPermissions() {
            this.entitlesdActions = new List<String>();
        }
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * +getEntitledActions :   Get List Of Entitled Approval Permissions for Current User
    ****************************************************************************/
    @auraEnabled(cacheable=true)
    public static ApprovalPermissions getEntitledActions(SC_DD_Deal__c deal) {
        
        ApprovalPermissions appPermissions = new ApprovalPermissions();
        
        // If Closed Deal - no action can be taken
        if(deal.Approval_Stage__c == 'Closed') {
            // ESESP-3415 - return empty instance of APprovalPermissions instead of null value
            return appPermissions; 
        }


        // Determine role of Current User(Approver Type) for Current Deal - DDA, SLM/SLD, SLD1, SLD2
        appPermissions.approverType = getApproverType(deal, System.UserInfo.getUserId());

        SC_DD_GSSServiceProduct__c servProd = [select id, Name from SC_DD_GSSServiceProduct__c 
                                                                    where Id = :deal.GSS_Product__c and 
                                                                    Is_Service_Support_Product__c = true and 
                                                                    Is_Active__c = true];

        // ESESP-3579 Permissions for Other Deal
        if(servProd.Name == 'Other') {
            if((appPermissions.approverType == 'SPO')) {
                appPermissions.entitlesdActions.add('Approve');
                appPermissions.entitlesdActions.add('Reject');
            } 
            else if(appPermissions.approverType == 'SLM/SLD' || appPermissions.approverType == 'SLD1' || appPermissions.approverType == 'SLD2' ) {
                appPermissions.entitlesdActions.add('Approve');
                appPermissions.entitlesdActions.add('Reject');
                appPermissions.entitlesdActions.add('Escalate');
            }
            return appPermissions;
        }
        
        
        // Get entitled actions for "ApproverType"
        Deal_Desk_Button_Visibility__c actionsCustSetting =  getActions(deal, appPermissions.approverType);
        // Based on the Custom Setting, build entitled actions Permission set
        if( actionsCustSetting.Has_Approve_Access__c) {
            appPermissions.entitlesdActions.add('Approve');
        }
        if( actionsCustSetting.Has_Reject_Access__c) {
            appPermissions.entitlesdActions.add('Reject');
        }
        if(actionsCustSetting.Has_Escalate_Access__c) {
            appPermissions.entitlesdActions.add('Escalate');
        }
        if(actionsCustSetting.Has_SendToDDA_Access__c && deal.Approval_Stage__c != 'DDA') {
            appPermissions.entitlesdActions.add('Send To DDA');
        }
        // return entitled actions permission set
        return appPermissions;
    }

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * +performAction      :   Perform Action - Approve, Reject, Escalate
    ****************************************************************************/
    @auraEnabled 
    public static Boolean performAction(SC_DD_Deal__c deal, String actionName, String comments) {
        ApprovalPermissions appPermissions = getEntitledActions(deal);
        if(appPermissions == null || !appPermissions.entitlesdActions.contains(actionName)) {
            return false;
        }
        deal.Commented_By__c = appPermissions.approverType;
        deal.Comments__c = comments;
        deal.Previous_Approver__c = UserInfo.getUserId();
        deal.Auto_Escalated__c = false;      

        if(actionName == 'Approve') {
            deal.Approval_Stage__c = 'Closed';
            deal.Evaluation_Action__c = 'Approved';
        }
        else if(actionName == 'Reject') {
            deal.Approval_Stage__c = 'Closed';
            deal.Evaluation_Action__c = 'Rejected';
        }
        // ESESP-3579 - When "Other" deal is manually escalated, move to next approval stage
        else if(actionName == 'Escalate' && deal.GSS_Product_Name__c == 'Other') {
            Integer currentStageIndx = apporvalStages.indexOf(appPermissions.approverType);
            deal.Approval_Stage__c = apporvalStages[ currentStageIndx + 1 ];
            deal.Evaluation_Action__c = 'Escalated';
        }
        // When deal is auto-escalated, move to next approval stage
        // When deal is manually-escalated, move to SPO stage
        else if(actionName == 'Escalate') {
            deal.Evaluation_Action__c = 'Escalated';
            if(deal.Approval_Stage__c == 'DDA') {
                deal.Approval_Stage__c = 'SLM/SLD' ;
            } 
            else {
                deal.Approval_Stage__c = 'SPO';
            }
        }
        else if(actionName == 'Send To DDA') {
            deal.Approval_Stage__c = 'DDA';
            deal.Evaluation_Action__c = 'Pending with DDA';
        }
                
        update deal;
        return true;

    }

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -getApproverType    :   Determine role of Current User(Approver Type) for Current Deal - DDA, SLM/SLD, SLD1, SLD2, SPO
    ****************************************************************************/
    static String getApproverType(SC_DD_Deal__c deal, Id userId) {
        String approverType;
        String approvalStage = deal.Approval_Stage__c;
        // Current User
        User currUser = [select id, Profile.Name, ManagerId from User where Id = :userId];

        // Set Account
        Account acc = [select TERR_HIER_1__c, TERR_HIER_2__c, TERR_HIER_3__c, TERR_HIER_4__c, TERR_HIER_5__c, SC_DD_DGRAT__c from Account where Id = :deal.Account__c];

        if(FeatureManagement.checkPermission('DD_SPO') || (String.isNotBlank(deal.Id) && isGraztSpecialApprover(acc.SC_DD_DGRAT__c))) {
            approverType = 'SPO';
        } else if( approvalStage == 'DDA' && currUser.Profile.Name == DDA_PROFILE ) {
            approverType = 'DDA';
        }
        else{
            Inv_WorkBox_Region_Mapping__c graztRec;
            
            List<Inv_WorkBox_Region_Mapping__c> graztList = [select Id, TERR_HIER_1__c, TERR_HIER_2__c, TERR_HIER_3__c, TERR_HIER_4__c, TERR_HIER_5__c,
                                User__c, User__r.ManagerId, User__r.Manager.ManagerId
                                from  Inv_WorkBox_Region_Mapping__c where RecordType.Name = 'DealDesk' 
                                AND Is_Old__c = false
                                AND (User__c = :currUser.Id OR User__r.ManagerId = :currUser.Id OR User__r.Manager.ManagerId = :currUser.Id)
                                AND TERR_HIER_1_F__c = :acc.TERR_HIER_1__c
                                    AND (  (TERR_HIER_2_F__c = :acc.TERR_HIER_2__c  and TERR_HIER_3_F__c = :acc.TERR_HIER_3__c and TERR_HIER_4_F__c = :acc.TERR_HIER_4__c and TERR_HIER_5_F__c = :acc.TERR_HIER_5__c) 
                                        OR (TERR_HIER_2_F__c = :acc.TERR_HIER_2__c  and TERR_HIER_3_F__c = :acc.TERR_HIER_3__c and TERR_HIER_4_F__c = :acc.TERR_HIER_4__c and TERR_HIER_5_F__c = :WILD_CHAR) 
                                        OR (TERR_HIER_2_F__c = :acc.TERR_HIER_2__c  and TERR_HIER_3_F__c = :acc.TERR_HIER_3__c and TERR_HIER_4_F__c = :WILD_CHAR and TERR_HIER_5_F__c = :WILD_CHAR)
                                        OR (TERR_HIER_2_F__c = :acc.TERR_HIER_2__c  and TERR_HIER_3_F__c = :WILD_CHAR and TERR_HIER_4_F__c = :WILD_CHAR and TERR_HIER_5_F__c = :WILD_CHAR)
                                        OR (TERR_HIER_2_F__c = :WILD_CHAR  and TERR_HIER_3_F__c = :WILD_CHAR and TERR_HIER_4_F__c = :WILD_CHAR and TERR_HIER_5_F__c = :WILD_CHAR) ) limit 1 ];

            if(graztList.size() > 0) {
                graztRec = graztList[0];
                if(approvalStage == 'SLM/SLD' && graztRec.User__c == currUser.Id) {
                    approverType = 'SLM/SLD';
                } else if( (approvalStage == 'SLM/SLD' || approvalStage == 'SLD1') && graztRec.User__r.ManagerId == currUser.Id) {
                    approverType = 'SLD1';
                } else if((approvalStage == 'SLM/SLD' || approvalStage == 'SLD1'|| approvalStage == 'SLD2')  &&  graztRec.User__r.Manager.ManagerId  == currUser.Id) {
                    approverType = 'SLD2';
                }
            }
        }
        return approverType;
    }
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -getActions         :   fetch entitled actions for "approverType", from custom setting
    ****************************************************************************/
    static Deal_Desk_Button_Visibility__c getActions(SC_DD_Deal__c deal, String approverType) {
        
        if(String.isBlank(approverType)) {
            return new Deal_Desk_Button_Visibility__c();
        }

        String  permissionKey = deal.Deal_Zone__c + '-' + approverType;

        return Deal_Desk_Button_Visibility__c.getInstance(permissionKey);
    }

    //11-May-2020     Vishnu Vardhan     ESESP-3581      To enable special approvers at GRAZT level (in addition to SPOs)
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   11-May-2020
    * -isGraztSpecialApprover      :   check if Current User Special Approver for a given GRAZT
    ****************************************************************************/
    public static Boolean isGraztSpecialApprover(String accGrazt) {
        Set<String> graztQueues = new Set<String>();
        for(SC_Utility__mdt graztQueueInfo: [select id, Active__c, DeveloperName, Value__c, MasterLabel 
                                                from SC_Utility__mdt where value_text__c = 'DealDesk_DGRAT_Access']) {

            if(graztQueueInfo.Value__c.contains(accGrazt)){
                return [select id from groupmember where group.developername = :graztQueueInfo.DeveloperName and UserOrGroupId = :UserInfo.getUserId() limit 1].size() > 0;
            }
        }
        return false;
    }

}