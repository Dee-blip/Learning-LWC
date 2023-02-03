/****************************************************************************
* Class name          :   SC_DD_EsrLogicOverrides.cls
* Author              :   Vishnu Vardhan
* Created             :   22-January-2021
* Purpose             :   ESR logic override class 
*                         If any product has complex ESR formula, implement SC_DD_DealDeskCont.Intf_EsrOverride interface 
                          and update the implemented class name in Product record
* Test Class          :   SC_DD_DealDeskTest
-------------------------------------------------------------------------------

DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
Jan 22, 2021     Vishnu Vardhan   ESESP-4694      new products - Protect & Perform 1.1 
*****************************************************************************/

public with sharing class SC_DD_EsrLogicOverrides {
   
    // Computed ESR logic for Advanced Product
    public virtual class PnPAdvancedProductEsr implements SC_DD_DealDeskCont.Intf_EsrOverride {
        SC_DD_Deal__c deal;
        final String PCK_PROJ_MAN = getPackCompLabel();
        final String PCK_ADDL_PROJ_MANAG_HOURS = getAddlProjLabel();

        public Decimal getComputedEsrLocal(SC_DD_Deal__c deal) {
            this.deal = deal;
            Map<String,SC_DD_DealDeskCont.Config> packageCompInfo = (Map<String,SC_DD_DealDeskCont.Config>)JSON.deserializeStrict(deal.Package_Comp_Info__c, Map<String,SC_DD_DealDeskCont.Config>.class);
            Decimal projManagementCompUnits = packageCompInfo.get(PCK_PROJ_MAN).requested;
            Decimal projManagementUnitPrice = 1;
            Decimal addlProjManagementHoursPerQuarter = packageCompInfo.get(PCK_ADDL_PROJ_MANAG_HOURS).requested;

            // If Project Components are entered, fetch Project Component Unit Price
           // if( !(projManagementCompUnits > 0) && addlProjManagementHoursPerQuarter >  0) {
                //Oct 26, 2020     Vishnu Vardhan   ESESP-4288
            //    throw new AuraHandledException( 'Include Project Management Fee in Requested Price for deal evaluation purposes. It will however need to be listed separately on the Order Form as it has it\'s own fee line (add-on)');
           // }

           //April 2022     Manasa     ESESP-6655
            // If Project Components are entered, fetch Project Component Unit Price
            if(projManagementCompUnits > 0) {
                List<SC_DD_Product_Pricing__c> prodPricing = [select List_ESR_Local_Currency__c, Local_List_Price__c, Currency__c from SC_DD_Product_Pricing__c 
                                                                where recordType.name = 'Component' and Package_Component__r.name = 'Project Management' and Currency__c = :deal.Local_Currency__c and GSS_Product__c = :deal.GSS_Product__c];
                if(prodPricing.size() == 0) {
                    throw new AuraHandledException( 'Project Management Component is not available for selected currency');
                }
                projManagementUnitPrice = prodPricing[0].Local_List_Price__c;
            } else if(addlProjManagementHoursPerQuarter >  0) {
                
                throw new AuraHandledException( 'Include Project Management Fee in Requested Price for deal evaluation purposes. It will however need to be listed separately on the Order Form as it has it\'s own fee line (add-on)');
            }

            // Computed ESR
            return getEsr(projManagementCompUnits, projManagementUnitPrice, addlProjManagementHoursPerQuarter);
        }

        virtual Decimal getEsr(Decimal projManagementCompUnits, Decimal projManagementUnitPrice, Decimal addlProjManagementHoursPerQuarter) {
            return 0;//deal.Requested_Price__c / deal.Requested_Hours__c; 
        }
        virtual string getPackCompLabel() {
            return 'Project Management (If 1= 24 Hrs/Qtr)';
        }
        virtual string getAddlProjLabel() {
            return 'Additional Project Management (Hrs/quarter)';
        }
    }

    public class PnpSoaAdvancedProductEsr extends PnPAdvancedProductEsr {
        override Decimal getEsr(Decimal projManagementCompUnits, Decimal projManagementUnitPrice, Decimal addlProjManagementHoursPerQuarter) {
            //return ((deal.Requested_Price__c - (projManagementCompUnits * projManagementUnitPrice * 2800) - (addlProjManagementHoursPerQuarter * 80)) * (1-( 0.75*0.3))) / deal.Requested_Hours__c; 
            //April 2022     Manasa     ESESP-6655
            return ((deal.Requested_Price__c - (projManagementCompUnits * projManagementUnitPrice) - (addlProjManagementHoursPerQuarter * 80)) * (1-( 0.75*0.3))) / deal.Requested_Hours__c; 
        }
    }

    public class PnpRrsAdvancedProductEsr extends PnPAdvancedProductEsr {
        override Decimal getEsr(Decimal projManagementCompUnits, Decimal projManagementUnitPrice, Decimal addlProjManagementHoursPerQuarter) {
           // return ((deal.Requested_Price__c - (projManagementCompUnits * projManagementUnitPrice * 2800) - (addlProjManagementHoursPerQuarter * 80)) * (1-( 0.55 *0.3)))/deal.Requested_Hours__c; 
            //April 2022     Manasa     ESESP-6655
            return ((deal.Requested_Price__c - (projManagementCompUnits * projManagementUnitPrice) - (addlProjManagementHoursPerQuarter * 80)) * (1-( 0.55*0.3))) / deal.Requested_Hours__c; 
        }
    }

    public class PnpMssAdvancedProductEsr extends PnPAdvancedProductEsr {
        override Decimal getEsr(Decimal projManagementCompUnits, Decimal projManagementUnitPrice, Decimal addlProjManagementHoursPerQuarter) {
            //return ((deal.Requested_Price__c - (projManagementCompUnits * projManagementUnitPrice * 2800) - (addlProjManagementHoursPerQuarter * 80)) * (1-( 0.3 * 0.3))) / deal.Requested_Hours__c; 
            //April 2022     Manasa     ESESP-6655
            return ((deal.Requested_Price__c - (projManagementCompUnits * projManagementUnitPrice) - (addlProjManagementHoursPerQuarter * 80)) * (1-( 0.3*0.3))) / deal.Requested_Hours__c; 
        }
    }
}