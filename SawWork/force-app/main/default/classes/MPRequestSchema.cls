/**Author        Date        Description
Ruchika Sharma   29/07/17       Created class.
                SFDC-1791 : Validate/Integrate MP API and user registration process in salesforce
**/
public class MPRequestSchema {
    public String opportunityId {get;set;} 
    public String opportunityCurrency {get;set;} 
    public List<Products> products {get;set;} 

    public class Products {
        public String id {get;set;} 
        public String name {get;set;} 
        public String trialDuration {get;set;} 

        public Products(Opportunity opp) {
            this.id = opp.MarketPlace_Product_Id__c;
            this.trialDuration = 'P'+String.valueOf(Integer.valueOf(opp.MarketPlace_Trial_Duration__c))+'D';
            MarketPlace_Product_Details__mdt mdtRecord = [select productName__c from MarketPlace_Product_Details__mdt where productId__c=:opp.MarketPlace_Product_Id__c];
            if(mdtRecord!=null)
                this.name = mdtRecord.productName__c;

        }

    }

    public MPRequestSchema(Opportunity opp) {
        this.opportunityId = opp.AKAM_Opportunity_ID__c;
        this.opportunityCurrency = opp.CurrencyIsoCode;
        MPRequestSchema.Products objProducts = new MPRequestSchema.Products(opp);
        this.products = new List<Products>{objProducts};
    }

    public static String convertOppToJson(sObject obj){
        String jsonFromList = '';
        if(obj instanceof Opportunity){
            Opportunity opp = (Opportunity) obj;
            system.debug(LoggingLevel.ERROR,'AGH_D:opp before jsonising '+opp);

            MPRequestSchema mpReqSchema = new MPRequestSchema(opp);
            system.debug(LoggingLevel.ERROR,'AGH_D:opp after instantiating '+mpReqSchema);
            jsonFromList = JSON.serialize(mpReqSchema);
            system.debug(LoggingLevel.ERROR,'AGH_D:opp after serialize '+jsonFromList);
        }

        return jsonFromList;
    }

}