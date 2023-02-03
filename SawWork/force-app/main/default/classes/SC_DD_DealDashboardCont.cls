/****************************************************************************
* Class name          :   SC_DD_DealDashboardCont.cls
* Author              :   Vishnu Vardhan
* Created             :   25-February-2020
* Purpose             :   Controller for DealDashboard
* Test Class          :   SC_DD_DealDeskTest
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
* +getPendingDeals    :   Get List of Deals pending with current user
* -isAccountInUsersGrazt :   Determine whether an Account falls under User's GRAZTs

DATE             DEVELOPER         CR              DESCRIPTION
===========      =========         =======         ===========
11-May-2020     Vishnu Vardhan     ESESP-3581      To enable special approvers at GRAZT level (in addition to SPOs)
March 12, 2021  Vishnu Vardhan     ESESP-4937      GRAZT changes

****************************************************************************/
public with sharing class SC_DD_DealDashboardCont {
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * +getPendingDeals    :   Get List of Deals pending with current user
    ****************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<SC_DD_Deal__c> getPendingDeals(Id userId){

        User currUser = [select id, profile.name from user where id =: userId];

        // For SPO Users, show list of deals which are escalated and pending with SPO
        if(FeatureManagement.checkPermission('DD_SPO')){
            return  [select id, Name, Account__r.TERR_HIER_1__c, Account__r.TERR_HIER_2__c, Account__r.TERR_HIER_3__c, 
                    Account__r.TERR_HIER_4__c, Account__r.TERR_HIER_5__c, Computed_ESR_Local__c, Deal_Zone__c, GSS_Product__r.Product_Combination__c,
                    Account__r.Name, Approval_Stage__c, Expected_Profitability_Score__c 
                    from SC_DD_Deal__c where Approval_Stage__c = 'SPO' AND Evaluation_Action__c = 'Escalated'];
        }

        // For DDA user, show list of deals which are sent back to DDA
        if(currUser.profile.name == SC_DD_ApprovalCompCont.DDA_PROFILE) {
            return  [select id, Name, Account__r.TERR_HIER_1__c, Account__r.TERR_HIER_2__c, Account__r.TERR_HIER_3__c, 
                            Account__r.TERR_HIER_4__c, Account__r.TERR_HIER_5__c, Computed_ESR_Local__c, Deal_Zone__c, GSS_Product__r.Product_Combination__c, 
                    Account__r.Name, Approval_Stage__c, Expected_Profitability_Score__c 
                                from SC_DD_Deal__c where requestor__c = :currUser.Id and Approval_Stage__c = 'DDA' and Evaluation_Action__c = 'Pending with DDA'];
        }        

        
        // For SLM, SLD1, SLD2, show list of all deals which are pending with them
        Map<String, List<String>> graztApproversMap = new Map<String,List<String>>{'SLM/SLD' => new List<String>(),
                                                                                    'SLD1' => new List<String>(),
                                                                                    'SLD2' => new List<String>()
                                                                            };

        for(Inv_WorkBox_Region_Mapping__c ur: [select Id, GRAZT__c, User__c, User__r.ManagerId, User__r.Manager.ManagerId 
                                from  Inv_WorkBox_Region_Mapping__c where RecordType.Name = 'DealDesk' 
                                and ( User__c = :currUser.Id OR User__r.ManagerId = :currUser.Id OR User__r.Manager.ManagerId = :currUser.Id)
                                AND Is_Old__c = false])
        {
            if(ur.User__c == currUser.Id) {
                graztApproversMap.get('SLM/SLD').add(ur.GRAZT__c);
            }
            else if(ur.User__r.ManagerId == currUser.Id ) {
                graztApproversMap.get('SLD1').add(ur.GRAZT__c);
            }
            else if(ur.User__r.Manager.ManagerId == currUser.Id) {
                graztApproversMap.get('SLD2').add(ur.GRAZT__c);
            }
        }

        List<SC_DD_Deal__c> allOpenDeals = [select id, Name, DGRAT__c, Computed_ESR_Local__c, Deal_Zone__c, Account__r.Name, 
                                            Account__r.TERR_HIER_1__c, Account__r.TERR_HIER_2__c, Account__r.TERR_HIER_3__c, Account__r.TERR_HIER_4__c, 
                                            Account__r.TERR_HIER_5__c,   GSS_Product__r.Product_Combination__c, Approval_Stage__c, Expected_Profitability_Score__c 
                                            from SC_DD_Deal__c where Approval_Stage__c in ('SLM/SLD', 'SLD1', 'SLD2', 'SPO')];
        // ESESP-3581 - Get Map of GRAZT and their Special Approvers
        Map<String, Set<String>> graztSpecialApprovers = SC_DD_DealTriggerHandler.getGraztSpecialApprovers(allOpenDeals);

        List<SC_DD_Deal__c> pendingDeals = new List<SC_DD_Deal__c>();

        for( SC_DD_Deal__c dl: allOpenDeals) {
            Boolean isSpecialApprover = graztSpecialApprovers!=null && graztSpecialApprovers.get(dl.DGRAT__c) != null && graztSpecialApprovers.get(dl.DGRAT__c).contains(UserInfo.getUserEmail());
            
            if( isSpecialApprover
                || ( dl.Approval_Stage__c == 'SLD1' && isAccountInUsersGrazt(graztApproversMap.get('SLD1'), dl.Account__r) )
                || ( dl.Approval_Stage__c == 'SLD2' && isAccountInUsersGrazt(graztApproversMap.get('SLD2'), dl.Account__r) )
                || ( dl.Approval_Stage__c == 'SLM/SLD' && isAccountInUsersGrazt(graztApproversMap.get('SLM/SLD'), dl.Account__r)) ) {
                    pendingDeals.add(dl);
            }
        }

        return pendingDeals;
    }
    /****************************************************************************
    * Author                 :   Vishnu Vardhan
    * Created                :   25-February-2020
    * -isAccountInUsersGrazt :   Determine whether an Account falls under User's GRAZTs
    ****************************************************************************/
    static boolean isAccountInUsersGrazt(List<String> usersGrazt, Account acc) {

        return( usersGrazt.contains(acc.TERR_HIER_1__c + '-' + acc.TERR_HIER_2__c + '-' + acc.TERR_HIER_3__c + '-' + acc.TERR_HIER_4__c + '-' + acc.TERR_HIER_5__c ) || 
                usersGrazt.contains(acc.TERR_HIER_1__c + '-' + acc.TERR_HIER_2__c + '-' + acc.TERR_HIER_3__c + '-' + acc.TERR_HIER_4__c + '-*') ||
                usersGrazt.contains(acc.TERR_HIER_1__c + '-' + acc.TERR_HIER_2__c + '-' + acc.TERR_HIER_3__c + '-*-*') ||
                usersGrazt.contains(acc.TERR_HIER_1__c + '-' + acc.TERR_HIER_2__c + '-*-*-*') ||
                usersGrazt.contains(acc.TERR_HIER_1__c + '-*-*-*-*')
                );
    }
}