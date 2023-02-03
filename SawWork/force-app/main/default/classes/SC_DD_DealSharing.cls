/****************************************************************************
* Class name          :   SC_DD_DealSharing.cls
* Author              :   Vishnu Vardhan
* Created             :   25-February-2020
* Purpose             :   To Share Deal record with SLMs & SLDs in it's GRAZT
* Test Class          :   SC_DD_DealDeskTest
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
* +getDealSharingRules :   Derive Sharing rules for given list of Deals
* -getGraztCombinations :   For given GRAZT, return all possible combinations of user GRAZTs

DATE             DEVELOPER     CR              DESCRIPTION
===========      =========     =======         ===========
March 12, 2020   Vishnu Vardhan   ESESP-4937      GRAZT changes
****************************************************************************/
public without sharing class SC_DD_DealSharing {

    /*
    Algo :
        1. Create a Map GRAZT combinations and deals under them. ex: grazt=> deals, dgra* => deals, dgr** => deals
        2. Query User GRAZT mapping and Loop over it
                a. fetch list of deals under that grazt from the above map, "grazt combination" => "deals"
                b. create sharing rules for all deals in that grazt and User, Manager, Manager's Manager
    */
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * +getDealSharingRules :   Derive Sharing rules for given list of Deals
    ****************************************************************************/
    public static List<SC_DD_Deal__Share> getDealSharingRules(List<SC_DD_Deal__c> deals) {

        Map<String, List<SC_DD_Deal__c>> graztDealMap = new Map<String, List<SC_DD_Deal__c>>();
        //TERR_HIER_1__c, TERR_HIER_2__c, TERR_HIER_3__c, TERR_HIER_4__c, TERR_HIER_5__c
        // Step 1: Create a Map GRAZT combinations and deals under them. ex: grazt=> deals, dgra* => deals, dgr** => deals
        for(SC_DD_Deal__c deal: [select id, Account__r.TERR_HIER_1__c, Account__r.TERR_HIER_2__c, Account__r.TERR_HIER_3__c , 
                                Account__r.TERR_HIER_4__c, Account__r.TERR_HIER_5__c from SC_DD_Deal__c where id in :deals]) {
            for( String graztKey: getGraztCombinations( deal.Account__r.TERR_HIER_1__c, deal.Account__r.TERR_HIER_2__c, 
                                                        deal.Account__r.TERR_HIER_3__c , deal.Account__r.TERR_HIER_4__c,deal.Account__r.TERR_HIER_5__c )) 
            {
                if(!graztDealMap.containsKey(graztKey)) {
                    graztDealMap.put(graztKey, new List<SC_DD_Deal__c>());
                }
                graztDealMap.get(graztKey).add(deal);
            }
        }

        List<SC_DD_Deal__Share> dealSharingRecs = new List<SC_DD_Deal__Share>();

        // Step 2 : Query User GRAZT mapping and Loop over it
        for(Inv_WorkBox_Region_Mapping__c userRegion: [ select id, User__c, User__r.Id, User__r.ManagerId, User__r.Manager.ManagerId,
                                                        TERR_HIER_1_F__c, TERR_HIER_2_F__c, TERR_HIER_3_F__c, TERR_HIER_4_F__c, TERR_HIER_5_F__c, GRAZT__c
                                                        from Inv_WorkBox_Region_Mapping__c where RecordType.Name = 'DealDesk' AND GRAZT__c in :graztDealMap.keySet() AND Is_Old__c = false]) 
        {   
            // Step 2.a : fetch list of deals under that grazt from the above map, "grazt combination" => "deals"
            for( SC_DD_Deal__c deal: graztDealMap.get(userRegion.GRAZT__c)) {
                Id slmSld = userRegion.User__c;
                Id sld1 = userRegion.User__r.ManagerId;
                Id sld2 = userRegion.User__r.Manager.ManagerId;
                // Step 2.b : create sharing rules for all deals in that grazt and User, Manager, Manager's Manager
                dealSharingRecs.addAll(
                    new List<SC_DD_Deal__Share> {
                        new SC_DD_Deal__Share( parentId = deal.Id, UserOrGroupId = slmSld, AccessLevel = 'Read', RowCause = Schema.SC_DD_Deal__Share.RowCause.SLM_SLD__c),
                        new SC_DD_Deal__Share( parentId = deal.Id, UserOrGroupId = sld1, AccessLevel = 'Read', RowCause = Schema.SC_DD_Deal__Share.RowCause.SLD1__c),
                        new SC_DD_Deal__Share( parentId = deal.Id,  UserOrGroupId = sld2, AccessLevel = 'Read', RowCause = Schema.SC_DD_Deal__Share.RowCause.SLD2__c) 
                    });
            }
        }

        return dealSharingRecs;

    }

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -getGraztCombinations :   For given GRAZT, return all possible combinations of user GRAZTs
    ****************************************************************************/
    static list<String> getGraztCombinations(String geo, String region, String area, String zone,  String territory){
        return new List<String>{
            geo + '-*-*-*-*',
            geo + '-' + region + '-*-*-*',
            geo + '-' + region + '-' + area + '-*-*',
            geo + '-' + region + '-' + area + '-' + zone + '-*',
            geo + '-' + region + '-' + area + '-' + zone + '-' + territory
        };	
    }

}